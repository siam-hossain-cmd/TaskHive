const express = require('express');
const { db, auth } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');
const os = require('os');

const router = express.Router();

// GET /api/health — Public health check
router.get('/', async (req, res) => {
    const start = Date.now();

    try {
        // Check Firebase Firestore connectivity
        let firestoreStatus = 'ok';
        let firestoreLatency = 0;
        try {
            const t = Date.now();
            await db.collection('_health').doc('ping').set({ ts: t });
            firestoreLatency = Date.now() - t;
        } catch {
            firestoreStatus = 'error';
        }

        // Check Firebase Auth connectivity
        let authStatus = 'ok';
        try {
            await auth.listUsers(1);
        } catch {
            authStatus = 'error';
        }

        // Check AI Service (Gemini) connectivity
        let aiStatus = 'ok';
        let aiLatency = 0;
        let aiModel = 'unknown';
        let aiEnabled = true;
        try {
            // Check settings
            const settingsDoc = await db.collection('app_config').doc('ai_settings').get();
            const settings = settingsDoc.exists ? settingsDoc.data() : {};
            aiEnabled = settings.enabled !== false;
            aiModel = settings.model || 'gemini-2.5-flash';

            if (aiEnabled) {
                const apiKey = settings.apiKey || process.env.GEMINI_API_KEY;
                if (!apiKey) {
                    aiStatus = 'no_key';
                } else {
                    const { GoogleGenerativeAI } = require('@google/generative-ai');
                    const genAI = new GoogleGenerativeAI(apiKey);
                    const model = genAI.getGenerativeModel({ model: aiModel });
                    const t = Date.now();
                    await model.generateContent('ping');
                    aiLatency = Date.now() - t;
                }
            } else {
                aiStatus = 'disabled';
            }
        } catch (err) {
            aiStatus = 'error';
            console.error('AI health check error:', err.message);
        }

        const uptime = process.uptime();
        const memory = process.memoryUsage();

        return res.json({
            status: 'ok',
            timestamp: new Date().toISOString(),
            uptime: Math.floor(uptime),
            responseTime: Date.now() - start,
            services: {
                firestore: { status: firestoreStatus, latencyMs: firestoreLatency },
                auth: { status: authStatus },
                server: { status: 'ok' },
                ai: { status: aiStatus, latencyMs: aiLatency, model: aiModel, enabled: aiEnabled },
            },
            system: {
                platform: os.platform(),
                arch: os.arch(),
                cpuCount: os.cpus().length,
                freeMemoryMb: Math.round(os.freemem() / 1024 / 1024),
                totalMemoryMb: Math.round(os.totalmem() / 1024 / 1024),
                nodeVersion: process.version,
                heapUsedMb: Math.round(memory.heapUsed / 1024 / 1024),
                heapTotalMb: Math.round(memory.heapTotal / 1024 / 1024),
            },
        });
    } catch (err) {
        return res.status(500).json({ status: 'error', error: err.message });
    }
});

module.exports = router;
