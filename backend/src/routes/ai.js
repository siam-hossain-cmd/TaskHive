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

    // Check rate limits
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
        const systemPrompt = `You are TaskHive AI, a smart assignment/task analyzer. 
When given the text of an assignment, project brief, or syllabus document, you must:
1. Identify the assignment title and subject
2. Write a concise summary of what the assignment requires
3. Break it down into specific, actionable sub-tasks
4. For each sub-task, estimate priority (high/medium/low) and hours needed
5. If team members are provided, suggest fair distribution based on task count and estimated effort

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
                teamMembers.map((m, i) => `${i + 1}. ${m.name} (uid: ${m.uid})`).join('\n') +
                '\n\nDistribute tasks fairly among these members using their uid as suggestedAssignee.';
        }

        const userPrompt = `Analyze this assignment document and break it into actionable sub-tasks:

${title ? `Title hint: ${title}` : ''}
${subject ? `Subject hint: ${subject}` : ''}

=== DOCUMENT TEXT ===
${truncatedText}
=== END DOCUMENT ===
${memberInfo}

Return the structured JSON breakdown.`;

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

module.exports = router;
