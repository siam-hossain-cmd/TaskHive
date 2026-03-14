const express = require('express');
const { db, messaging, auth } = require('../firebase');
const { authenticateUser } = require('../middleware/auth');

const router = express.Router();

// ─── Helper: Check AI access & rate limits ────────────────────────────────────
async function checkAIAccess(userId) {
    // Check global AI enabled
    const settingsDoc = await db.collection('app_config').doc('ai_settings').get();
    const settings = settingsDoc.exists ? settingsDoc.data() : { enabled: true };
    if (settings.enabled === false) {
        return { allowed: false, reason: 'AI features are currently disabled by admin' };
    }

    // Check per-user access
    const accessDoc = await db.collection('ai_user_access').doc(userId).get();
    if (accessDoc.exists && accessDoc.data().enabled === false) {
        return { allowed: false, reason: 'AI access has been disabled for your account' };
    }

    // Check rate limits (wrapped in try-catch to handle missing Firestore composite indexes)
    try {
        const limits = settings.rateLimits || { maxRequestsPerHour: 20, maxRequestsPerDay: 100 };
        const userQuota = accessDoc.exists ? accessDoc.data().customQuota : null;
        const effectiveLimits = userQuota || limits;

        const now = new Date();
        const oneHourAgo = new Date(now - 60 * 60 * 1000).toISOString();
        const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000).toISOString();

        // Count requests in last hour
        const hourSnap = await db.collection('ai_usage_logs')
            .where('userId', '==', userId)
            .where('timestamp', '>=', oneHourAgo)
            .get();
        if (hourSnap.size >= effectiveLimits.maxRequestsPerHour) {
            return { allowed: false, reason: `Rate limit exceeded: max ${effectiveLimits.maxRequestsPerHour} requests per hour` };
        }

        // Count requests in last day
        const daySnap = await db.collection('ai_usage_logs')
            .where('userId', '==', userId)
            .where('timestamp', '>=', oneDayAgo)
            .get();
        if (daySnap.size >= effectiveLimits.maxRequestsPerDay) {
            return { allowed: false, reason: `Daily limit exceeded: max ${effectiveLimits.maxRequestsPerDay} requests per day` };
        }
    } catch (rateLimitErr) {
        // If composite index is missing, log and allow (don't block users)
        console.warn('Rate limit check failed (missing Firestore index?):', rateLimitErr.message);
    }

    return { allowed: true, settings };
}

// ─── Helper: Log AI usage ─────────────────────────────────────────────────────
async function logAIUsage({ userId, endpoint, status, tokensUsed = 0, durationMs = 0, error = null }) {
    try {
        // Try to get user info
        let userName = 'Unknown', userEmail = '';
        try {
            const userRecord = await auth.getUser(userId);
            userName = userRecord.displayName || 'Unknown';
            userEmail = userRecord.email || '';
        } catch (_) { /* ignore */ }

        // Estimate cost (Gemini Flash pricing: ~$0.075/1M input, ~$0.30/1M output)
        const estimatedCost = (tokensUsed / 1000000) * 0.15;

        await db.collection('ai_usage_logs').add({
            userId,
            userName,
            userEmail,
            endpoint,
            status,
            tokensUsed,
            estimatedCost: Math.round(estimatedCost * 10000) / 10000,
            durationMs,
            error: error ? String(error).substring(0, 200) : null,
            timestamp: new Date().toISOString(),
        });
    } catch (err) {
        console.error('Failed to log AI usage:', err);
    }
}

// ─── Helper: Download PDF and extract text ────────────────────────────────────
async function extractTextFromPdf(pdfUrl) {
    const pdfParse = require('pdf-parse');
    const https = require('https');
    const http = require('http');

    return new Promise((resolve, reject) => {
        const client = pdfUrl.startsWith('https') ? https : http;
        client.get(pdfUrl, (response) => {
            // Handle redirects
            if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
                const redirectClient = response.headers.location.startsWith('https') ? https : http;
                redirectClient.get(response.headers.location, (redirectResponse) => {
                    const chunks = [];
                    redirectResponse.on('data', (chunk) => chunks.push(chunk));
                    redirectResponse.on('end', async () => {
                        try {
                            const buffer = Buffer.concat(chunks);
                            const data = await pdfParse(buffer);
                            resolve(data.text);
                        } catch (err) {
                            reject(err);
                        }
                    });
                    redirectResponse.on('error', reject);
                }).on('error', reject);
                return;
            }

            const chunks = [];
            response.on('data', (chunk) => chunks.push(chunk));
            response.on('end', async () => {
                try {
                    const buffer = Buffer.concat(chunks);
                    const data = await pdfParse(buffer);
                    resolve(data.text);
                } catch (err) {
                    reject(err);
                }
            });
            response.on('error', reject);
        }).on('error', reject);
    });
}

// ─── Helper: Call Gemini AI ───────────────────────────────────────────────────
async function callGeminiAI(prompt, systemPrompt) {
    const { GoogleGenerativeAI } = require('@google/generative-ai');

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new Error('GEMINI_API_KEY not set in environment variables');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
        generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.3,
        },
    });

    const chat = model.startChat({
        history: [
            {
                role: 'user',
                parts: [{ text: systemPrompt }],
            },
            {
                role: 'model',
                parts: [{ text: 'Understood. I will analyze assignments and return structured JSON.' }],
            },
        ],
    });

    const result = await chat.sendMessage(prompt);
    const responseText = result.response.text();

    try {
        return JSON.parse(responseText);
    } catch {
        // Try to extract JSON from the response
        const jsonMatch = responseText.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }
        throw new Error('AI returned invalid JSON');
    }
}

// ─── POST /api/ai/analyze — Analyze PDF and break into subtasks ──────────────
router.post('/analyze', authenticateUser, async (req, res) => {
    const startTime = Date.now();
    try {
        // Check AI access and rate limits
        const access = await checkAIAccess(req.user.uid);
        if (!access.allowed) {
            return res.status(429).json({ error: access.reason });
        }

        const { pdfUrl, teamMembers, title, subject } = req.body;

        if (!pdfUrl) {
            return res.status(400).json({ error: 'pdfUrl is required' });
        }

        // 1. Extract text from PDF
        let pdfText;
        try {
            pdfText = await extractTextFromPdf(pdfUrl);
        } catch (err) {
            console.error('PDF extraction error:', err);
            return res.status(400).json({
                error: 'Could not read this PDF. Please try a text-based PDF.',
                details: err.message,
            });
        }

        if (!pdfText || pdfText.trim().length < 10) {
            return res.status(400).json({
                error: 'PDF contains no readable text. Try a text-based PDF instead of a scanned image.',
            });
        }

        // Truncate very long PDFs to prevent token overflow
        const maxChars = 15000;
        const truncatedText = pdfText.length > maxChars
            ? pdfText.substring(0, maxChars) + '\n...[truncated]'
            : pdfText;

        // 2. Build AI prompt
        const teamSize = req.body.teamSize || (teamMembers ? teamMembers.length : 1);
        const maxSubtasks = Math.max(3, Math.min(teamSize * 3, 12)); // 3 to 12 subtasks max

        const systemPrompt = `You are TaskHive AI, a smart assignment/task analyzer.
When given the text of an assignment, project brief, or syllabus document, you must:
1. Identify the assignment title and subject
2. Write a concise summary of what the assignment requires
3. Break it down into FOCUSED, high-level sub-tasks based on the MAIN topics, questions, or deliverables
4. For each sub-task, estimate priority (high/medium/low) and hours needed
5. If team members are provided, suggest fair distribution based on task count and estimated effort

IMPORTANT RULES for subtask creation:
- Create AT MOST ${maxSubtasks} subtasks (team size is ${teamSize})
- Each subtask should represent a MAJOR deliverable, question, or section — NOT micro-steps
- Group related small items into one subtask instead of creating separate ones
- Focus on WHAT needs to be built/solved/written, not process steps like "read instructions" or "submit work"
- Do NOT create subtasks for obvious steps like "upload", "submit", "review", "compile files"
- If the assignment has numbered questions/problems, each question = 1 subtask
- If the assignment is a project, each major component/feature = 1 subtask
- Aim for ${Math.ceil(maxSubtasks * 0.7)}-${maxSubtasks} subtasks total

ALWAYS return valid JSON in this exact format:
{
  "title": "string",
  "subject": "string",
  "summary": "string (2-3 sentences)",
  "subtasks": [
    {
      "title": "string",
      "description": "string",
      "priority": "high|medium|low",
      "estimatedHours": number,
      "suggestedAssignee": "uid or null"
    }
  ]
}`;

        let memberInfo = '';
        if (teamMembers && teamMembers.length > 0) {
            memberInfo = '\n\nTeam Members:\n' +
                teamMembers.map((m, i) => `${i + 1}. ${m.name} (uid: ${m.uid || m.id})`).join('\n') +
                '\n\nDistribute tasks fairly among these members using their uid as suggestedAssignee.';
        }

        const userPrompt = `Analyze this assignment document and break it into focused, high-level sub-tasks.
Team size: ${teamSize} members. Create at most ${maxSubtasks} subtasks.
Focus on the main questions, problems, or deliverables only.

${title ? `Title hint: ${title}` : ''}
${subject ? `Subject hint: ${subject}` : ''}

=== DOCUMENT TEXT ===
${truncatedText}
=== END DOCUMENT ===
${memberInfo}

Return the structured JSON breakdown with no more than ${maxSubtasks} subtasks.`;

        // 3. Call Gemini AI
        const analysis = await callGeminiAI(userPrompt, systemPrompt);

        // 4. Save conversation for refinement
        const convRef = await db.collection('ai_conversations').add({
            userId: req.user.uid,
            pdfUrl,
            pdfTextPreview: truncatedText.substring(0, 500),
            messages: [
                { role: 'user', content: userPrompt },
                { role: 'assistant', content: JSON.stringify(analysis) },
            ],
            createdAt: new Date().toISOString(),
        });

        // Log successful usage
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'analyze',
            status: 'success',
            tokensUsed: truncatedText.length + JSON.stringify(analysis).length,
            durationMs: Date.now() - startTime,
        });

        return res.json({
            success: true,
            analysis,
            conversationId: convRef.id,
        });
    } catch (err) {
        console.error('AI Analysis Error:', err);
        // Log failed usage
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'analyze',
            status: 'error',
            durationMs: Date.now() - startTime,
            error: err.message,
        });
        return res.status(500).json({
            error: 'Failed to analyze assignment',
            details: err.message,
        });
    }
});

// ─── POST /api/ai/refine — Modify breakdown via AI chat ─────────────────────
router.post('/refine', authenticateUser, async (req, res) => {
    const startTime = Date.now();
    try {
        // Check AI access and rate limits
        const access = await checkAIAccess(req.user.uid);
        if (!access.allowed) {
            return res.status(429).json({ error: access.reason });
        }

        const { conversationId, message, currentSubtasks } = req.body;

        if (!conversationId || !message) {
            return res.status(400).json({ error: 'conversationId and message are required' });
        }

        // Load conversation history
        const convDoc = await db.collection('ai_conversations').doc(conversationId).get();
        if (!convDoc.exists) {
            return res.status(404).json({ error: 'Conversation not found' });
        }

        const convData = convDoc.data();

        const systemPrompt = `You are TaskHive AI. You previously analyzed an assignment and created a task breakdown. 
The user wants to modify the breakdown. Apply their requested changes and return the FULL updated JSON.

ALWAYS return valid JSON in this exact format:
{
  "message": "string (brief description of what you changed)",
  "subtasks": [
    {
      "title": "string",
      "description": "string",
      "priority": "high|medium|low",
      "estimatedHours": number,
      "suggestedAssignee": "uid or null"
    }
  ]
}`;

        const userPrompt = `Current subtask breakdown:
${JSON.stringify(currentSubtasks, null, 2)}

User request: "${message}"

Apply the requested changes and return the complete updated subtasks array as JSON.`;

        const result = await callGeminiAI(userPrompt, systemPrompt);

        // Update conversation history
        const updatedMessages = [
            ...convData.messages,
            { role: 'user', content: message },
            { role: 'assistant', content: JSON.stringify(result) },
        ];

        await db.collection('ai_conversations').doc(conversationId).update({
            messages: updatedMessages,
        });

        // Log successful usage
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'refine',
            status: 'success',
            tokensUsed: message.length + JSON.stringify(result).length,
            durationMs: Date.now() - startTime,
        });

        return res.json({
            success: true,
            message: result.message || 'Breakdown updated successfully',
            updatedSubtasks: result.subtasks || [],
        });
    } catch (err) {
        console.error('AI Refine Error:', err);
        // Log failed usage
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'refine',
            status: 'error',
            durationMs: Date.now() - startTime,
            error: err.message,
        });
        return res.status(500).json({
            error: 'Failed to refine breakdown',
            details: err.message,
        });
    }
});

// ─── POST /api/ai/parse-task — Natural language task creation ────────────────
router.post('/parse-task', authenticateUser, async (req, res) => {
    const startTime = Date.now();
    try {
        const access = await checkAIAccess(req.user.uid);
        if (!access.allowed) {
            return res.status(429).json({ error: access.reason });
        }

        const { text } = req.body;
        if (!text || text.trim().length < 3) {
            return res.status(400).json({ error: 'Please provide a task description' });
        }

        const systemPrompt = `You are TaskHive AI. Parse natural language task descriptions into structured task data.
Extract: title, description, subject, priority (high/medium/low), estimated minutes, due date (ISO 8601), 
recurrence (none/daily/weekly/monthly), and optional subtasks.

If no due date is mentioned, set it to tomorrow at 23:59.
If no priority is mentioned, set it to medium.
If the text mentions multiple steps or sub-items, create subtasks.

ALWAYS return valid JSON in this exact format:
{
  "title": "string",
  "description": "string",
  "subject": "string or empty",
  "priority": "high|medium|low",
  "estimatedMinutes": number,
  "dueDate": "ISO 8601 date string",
  "recurrence": "none|daily|weekly|monthly",
  "subtasks": ["string", "string"] 
}`;

        const userPrompt = `Parse this into a structured task:\n\n"${text}"\n\nCurrent date/time: ${new Date().toISOString()}`;

        const result = await callGeminiAI(userPrompt, systemPrompt);

        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'parse-task',
            status: 'success',
            tokensUsed: text.length + JSON.stringify(result).length,
            durationMs: Date.now() - startTime,
        });

        return res.json({ success: true, task: result });
    } catch (err) {
        console.error('AI Parse Task Error:', err);
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'parse-task',
            status: 'error',
            durationMs: Date.now() - startTime,
            error: err.message,
        });
        return res.status(500).json({ error: 'Failed to parse task', details: err.message });
    }
});

// ─── POST /api/ai/suggestions — Smart task suggestions ──────────────────────
router.post('/suggestions', authenticateUser, async (req, res) => {
    const startTime = Date.now();
    try {
        const access = await checkAIAccess(req.user.uid);
        if (!access.allowed) {
            return res.status(429).json({ error: access.reason });
        }

        const { tasks, completedTasks, currentTime } = req.body;

        const systemPrompt = `You are TaskHive AI productivity advisor. Given a user's current tasks and recently completed tasks, 
provide smart suggestions to improve their productivity.

ALWAYS return valid JSON in this exact format:
{
  "suggestions": [
    {
      "type": "priority_change|schedule|break|focus|deadline|split",
      "title": "string (short actionable title)",
      "message": "string (2-3 sentence explanation)",
      "taskId": "string or null (if suggestion relates to a specific task)",
      "action": "string or null (e.g., 'change_priority_high', 'start_pomodoro', 'add_subtasks')"
    }
  ],
  "dailyTip": "string (one motivational or productivity tip for the day)"
}

Generate 3-5 relevant suggestions based on the user's task data.`;

        const userPrompt = `Here are my current tasks:
${JSON.stringify(tasks || [], null, 2)}

Recently completed tasks:
${JSON.stringify(completedTasks || [], null, 2)}

Current time: ${currentTime || new Date().toISOString()}

Analyze my workload and provide smart suggestions.`;

        const result = await callGeminiAI(userPrompt, systemPrompt);

        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'suggestions',
            status: 'success',
            tokensUsed: userPrompt.length + JSON.stringify(result).length,
            durationMs: Date.now() - startTime,
        });

        return res.json({ success: true, ...result });
    } catch (err) {
        console.error('AI Suggestions Error:', err);
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'suggestions',
            status: 'error',
            durationMs: Date.now() - startTime,
            error: err.message,
        });
        return res.status(500).json({ error: 'Failed to generate suggestions', details: err.message });
    }
});

// ─── POST /api/ai/weekly-review — AI weekly productivity review ─────────────
router.post('/weekly-review', authenticateUser, async (req, res) => {
    const startTime = Date.now();
    try {
        const access = await checkAIAccess(req.user.uid);
        if (!access.allowed) {
            return res.status(429).json({ error: access.reason });
        }

        const { weeklyStats, tasks, userName } = req.body;

        const systemPrompt = `You are TaskHive AI, a supportive productivity coach. Generate a personalized weekly review.
Be encouraging but honest. Use data to back up your observations.

ALWAYS return valid JSON in this exact format:
{
  "greeting": "string (personalized greeting using the user's name)",
  "summary": "string (2-3 sentence overview of the week)",
  "highlights": ["string", "string"] (2-3 positive achievements),
  "improvements": ["string", "string"] (1-2 areas for improvement, constructive),
  "nextWeekTips": ["string", "string"] (2-3 actionable tips for next week),
  "productivityScore": number (0-100, based on completion rate, consistency, and deadline adherence),
  "emoji": "string (single emoji that represents the week)"
}`;

        const userPrompt = `Generate my weekly review.

User name: ${userName || 'there'}

Weekly stats:
${JSON.stringify(weeklyStats || {}, null, 2)}

Tasks this week:
${JSON.stringify(tasks || [], null, 2)}`;

        const result = await callGeminiAI(userPrompt, systemPrompt);

        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'weekly-review',
            status: 'success',
            tokensUsed: userPrompt.length + JSON.stringify(result).length,
            durationMs: Date.now() - startTime,
        });

        return res.json({ success: true, review: result });
    } catch (err) {
        console.error('AI Weekly Review Error:', err);
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'weekly-review',
            status: 'error',
            durationMs: Date.now() - startTime,
            error: err.message,
        });
        return res.status(500).json({ error: 'Failed to generate weekly review', details: err.message });
    }
});

// ─── POST /api/ai/smart-prioritize — AI priority adjustment ─────────────────
router.post('/smart-prioritize', authenticateUser, async (req, res) => {
    const startTime = Date.now();
    try {
        const access = await checkAIAccess(req.user.uid);
        if (!access.allowed) {
            return res.status(429).json({ error: access.reason });
        }

        const { tasks } = req.body;

        const systemPrompt = `You are TaskHive AI. Analyze the user's tasks and suggest optimal priority adjustments.
Consider deadlines, current priorities, workload balance, and task dependencies.

ALWAYS return valid JSON in this exact format:
{
  "adjustments": [
    {
      "taskId": "string",
      "taskTitle": "string",
      "currentPriority": "high|medium|low",
      "suggestedPriority": "high|medium|low",
      "reason": "string (brief explanation)"
    }
  ],
  "overallAdvice": "string (1-2 sentences about the user's priority balance)"
}

Only suggest changes where the priority genuinely should differ. Don't change priorities just for the sake of it.`;

        const userPrompt = `Analyze these tasks and suggest priority adjustments:
${JSON.stringify(tasks || [], null, 2)}

Current date: ${new Date().toISOString()}`;

        const result = await callGeminiAI(userPrompt, systemPrompt);

        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'smart-prioritize',
            status: 'success',
            tokensUsed: userPrompt.length + JSON.stringify(result).length,
            durationMs: Date.now() - startTime,
        });

        return res.json({ success: true, ...result });
    } catch (err) {
        console.error('AI Smart Prioritize Error:', err);
        await logAIUsage({
            userId: req.user.uid,
            endpoint: 'smart-prioritize',
            status: 'error',
            durationMs: Date.now() - startTime,
            error: err.message,
        });
        return res.status(500).json({ error: 'Failed to generate priority suggestions', details: err.message });
    }
});

module.exports = router;
