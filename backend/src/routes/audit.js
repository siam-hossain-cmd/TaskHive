const express = require('express');
const { db } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/audit — Get audit logs
router.get('/', authenticateAdmin, async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 100;
        const snap = await db.collection('admin_audit_logs')
            .orderBy('timestamp', 'desc')
            .limit(limit)
            .get();
        const logs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ logs });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch audit logs' });
    }
});

module.exports = router;
