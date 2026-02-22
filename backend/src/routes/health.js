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
