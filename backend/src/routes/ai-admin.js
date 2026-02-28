const express = require('express');
const { db } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

// ─── All routes require admin authentication ─────────────────────────────────
router.use(authenticateAdmin);

// ─── GET /api/ai-admin/settings — Get AI settings ────────────────────────────
router.get('/settings', async (req, res) => {
    try {
        const doc = await db.collection('app_config').doc('ai_settings').get();

        const defaults = {
            enabled: true,
            provider: 'gemini',
            model: 'gemini-2.5-flash',
            apiKey: '',
            temperature: 0.3,
            maxTokens: 8192,
            systemPrompt: `You are TaskHive AI, a smart assignment/task analyzer. 
When given the text of an assignment, project brief, or syllabus document, you must:
1. Identify the assignment title and subject
2. Write a concise summary of what the assignment requires
3. Break it down into specific, actionable sub-tasks
4. For each sub-task, estimate priority (high/medium/low) and hours needed
5. If team members are provided, suggest fair distribution based on task count and estimated effort`,
            rateLimits: {
                maxRequestsPerHour: 20,
                maxRequestsPerDay: 100,
                maxTokensPerDay: 500000,
            },
            contentFiltering: true,
            alertThreshold: {
                dailyCostUsd: 10,
                dailyRequests: 500,
            },
        };

        if (!doc.exists) {
            return res.json(defaults);
        }

        const data = doc.data();
        // Mask API key for security (show only last 4 chars)
        if (data.apiKey) {
            data.apiKeyMasked = '••••••••' + data.apiKey.slice(-4);
        }
        return res.json({ ...defaults, ...data });
    } catch (err) {
        console.error('Get AI settings error:', err);
        return res.status(500).json({ error: 'Failed to fetch AI settings' });
    }
});

// ─── PUT /api/ai-admin/settings — Update AI settings ─────────────────────────
router.put('/settings', async (req, res) => {
    try {
        const {
            enabled,
            provider,
            model,
            apiKey,
            temperature,
            maxTokens,
            systemPrompt,
            rateLimits,
            contentFiltering,
            alertThreshold,
        } = req.body;

        const updateData = {};
        if (typeof enabled === 'boolean') updateData.enabled = enabled;
        if (provider) updateData.provider = provider;
        if (model) updateData.model = model;
        if (apiKey) updateData.apiKey = apiKey;
        if (typeof temperature === 'number') updateData.temperature = temperature;
        if (typeof maxTokens === 'number') updateData.maxTokens = maxTokens;
        if (systemPrompt) updateData.systemPrompt = systemPrompt;
        if (rateLimits) updateData.rateLimits = rateLimits;
        if (typeof contentFiltering === 'boolean') updateData.contentFiltering = contentFiltering;
        if (alertThreshold) updateData.alertThreshold = alertThreshold;
        updateData.updatedAt = new Date().toISOString();
        updateData.updatedBy = req.admin.email;

        await db.collection('app_config').doc('ai_settings').set(updateData, { merge: true });

        // Log audit
        await db.collection('audit_logs').add({
            action: 'AI_SETTINGS_UPDATED',
            adminEmail: req.admin.email,
            details: `Updated AI settings: ${Object.keys(updateData).filter(k => k !== 'updatedAt' && k !== 'updatedBy').join(', ')}`,
            timestamp: new Date().toISOString(),
        });

        return res.json({ success: true, message: 'AI settings updated' });
    } catch (err) {
        console.error('Update AI settings error:', err);
        return res.status(500).json({ error: 'Failed to update AI settings' });
    }
});

// ─── POST /api/ai-admin/settings/test — Test AI connection ───────────────────
router.post('/settings/test', async (req, res) => {
    try {
        // Load current settings or use env
        const doc = await db.collection('app_config').doc('ai_settings').get();
        const settings = doc.exists ? doc.data() : {};

        const apiKey = settings.apiKey || process.env.GEMINI_API_KEY;
        if (!apiKey) {
            return res.status(400).json({ success: false, error: 'No API key configured' });
        }

        const { GoogleGenerativeAI } = require('@google/generative-ai');
        const genAI = new GoogleGenerativeAI(apiKey);
        const model = genAI.getGenerativeModel({
            model: settings.model || 'gemini-2.5-flash',
        });

        const result = await model.generateContent('Say "Connection successful" in exactly 2 words.');
        const text = result.response.text();

        return res.json({
            success: true,
            message: 'AI connection is working',
            response: text.substring(0, 100),
            model: settings.model || 'gemini-2.5-flash',
        });
    } catch (err) {
        console.error('AI connection test error:', err);
        return res.status(400).json({
            success: false,
            error: err.message || 'Connection failed',
        });
    }
});

// ─── GET /api/ai-admin/usage — Get usage overview & per-user stats ───────────
router.get('/usage', async (req, res) => {
    try {
        const { period = '7d', userId } = req.query;

        // Calculate date range
        const now = new Date();
        let startDate;
        switch (period) {
            case '24h': startDate = new Date(now - 24 * 60 * 60 * 1000); break;
            case '7d': startDate = new Date(now - 7 * 24 * 60 * 60 * 1000); break;
            case '30d': startDate = new Date(now - 30 * 24 * 60 * 60 * 1000); break;
            case '90d': startDate = new Date(now - 90 * 24 * 60 * 60 * 1000); break;
            default: startDate = new Date(now - 7 * 24 * 60 * 60 * 1000);
        }

        // Query usage logs
        let query = db.collection('ai_usage_logs')
            .where('timestamp', '>=', startDate.toISOString())
            .orderBy('timestamp', 'desc');

        if (userId) {
            query = query.where('userId', '==', userId);
        }

        const snapshot = await query.get();
        const logs = [];
        snapshot.forEach(doc => logs.push({ id: doc.id, ...doc.data() }));

        // Aggregate stats
        const totalRequests = logs.length;
        const totalTokens = logs.reduce((sum, l) => sum + (l.tokensUsed || 0), 0);
        const totalCost = logs.reduce((sum, l) => sum + (l.estimatedCost || 0), 0);
        const uniqueUsers = [...new Set(logs.map(l => l.userId))].length;
        const failedRequests = logs.filter(l => l.status === 'error').length;

        // Per-user breakdown
        const userMap = {};
        logs.forEach(log => {
            if (!userMap[log.userId]) {
                userMap[log.userId] = {
                    userId: log.userId,
                    userName: log.userName || 'Unknown',
                    userEmail: log.userEmail || '',
                    requests: 0,
                    tokensUsed: 0,
                    estimatedCost: 0,
                    lastRequest: null,
                    errors: 0,
                };
            }
            const u = userMap[log.userId];
            u.requests++;
            u.tokensUsed += log.tokensUsed || 0;
            u.estimatedCost += log.estimatedCost || 0;
            if (log.status === 'error') u.errors++;
            if (!u.lastRequest || log.timestamp > u.lastRequest) {
                u.lastRequest = log.timestamp;
            }
        });

        const perUser = Object.values(userMap).sort((a, b) => b.requests - a.requests);

        // Daily breakdown for charts
        const dailyMap = {};
        logs.forEach(log => {
            const day = log.timestamp.substring(0, 10); // YYYY-MM-DD
            if (!dailyMap[day]) {
                dailyMap[day] = { date: day, requests: 0, tokens: 0, cost: 0 };
            }
            dailyMap[day].requests++;
            dailyMap[day].tokens += log.tokensUsed || 0;
            dailyMap[day].cost += log.estimatedCost || 0;
        });

        const dailyStats = Object.values(dailyMap).sort((a, b) => a.date.localeCompare(b.date));

        return res.json({
            overview: {
                totalRequests,
                totalTokens,
                totalCost: Math.round(totalCost * 10000) / 10000,
                uniqueUsers,
                failedRequests,
                period,
            },
            perUser,
            dailyStats,
        });
    } catch (err) {
        console.error('Get AI usage error:', err);
        return res.status(500).json({ error: 'Failed to fetch AI usage data' });
    }
});

// ─── GET /api/ai-admin/usage/:uid — Detailed user usage ─────────────────────
router.get('/usage/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const { limit: maxResults = 50 } = req.query;

        const snapshot = await db.collection('ai_usage_logs')
            .where('userId', '==', uid)
            .orderBy('timestamp', 'desc')
            .limit(parseInt(maxResults))
            .get();

        const logs = [];
        snapshot.forEach(doc => logs.push({ id: doc.id, ...doc.data() }));

        // Get user's AI access status
        const accessDoc = await db.collection('ai_user_access').doc(uid).get();
        const accessData = accessDoc.exists ? accessDoc.data() : { enabled: true, customQuota: null };

        return res.json({
            userId: uid,
            access: accessData,
            recentLogs: logs,
            totalLogged: logs.length,
        });
    } catch (err) {
        console.error('Get user AI usage error:', err);
        return res.status(500).json({ error: 'Failed to fetch user AI usage' });
    }
});

// ─── PATCH /api/ai-admin/access/:uid — Enable/disable AI for a user ─────────
router.patch('/access/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const { enabled, customQuota } = req.body;

        const updateData = { updatedAt: new Date().toISOString() };
        if (typeof enabled === 'boolean') updateData.enabled = enabled;
        if (customQuota !== undefined) updateData.customQuota = customQuota;

        await db.collection('ai_user_access').doc(uid).set(updateData, { merge: true });

        // Audit log
        await db.collection('audit_logs').add({
            action: enabled === false ? 'AI_ACCESS_DISABLED' : 'AI_ACCESS_UPDATED',
            adminEmail: req.admin.email,
            details: `AI access for user ${uid}: enabled=${enabled}${customQuota ? `, quota=${JSON.stringify(customQuota)}` : ''}`,
            timestamp: new Date().toISOString(),
        });

        return res.json({ success: true, message: `AI access updated for user ${uid}` });
    } catch (err) {
        console.error('Update AI access error:', err);
        return res.status(500).json({ error: 'Failed to update AI access' });
    }
});

// ─── GET /api/ai-admin/conversations — List all AI conversations ────────────
router.get('/conversations', async (req, res) => {
    try {
        const { limit: maxResults = 50 } = req.query;

        const snapshot = await db.collection('ai_conversations')
            .orderBy('createdAt', 'desc')
            .limit(parseInt(maxResults))
            .get();

        const conversations = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            conversations.push({
                id: doc.id,
                userId: data.userId,
                pdfTextPreview: data.pdfTextPreview || '',
                messageCount: data.messages?.length || 0,
                createdAt: data.createdAt,
            });
        });

        return res.json({ conversations });
    } catch (err) {
        console.error('Get AI conversations error:', err);
        return res.status(500).json({ error: 'Failed to fetch AI conversations' });
    }
});

module.exports = router;
