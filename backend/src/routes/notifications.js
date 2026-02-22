const express = require('express');
const { messaging, db, auth } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

const logAudit = async (action, adminEmail, details = {}) => {
    await db.collection('admin_audit_logs').add({
        action, adminEmail, details, timestamp: new Date().toISOString(),
    });
};

// POST /api/notifications/send — Send notification to all or specific users
router.post('/send', authenticateAdmin, async (req, res) => {
    try {
        const { title, body, targetUid, topic } = req.body;

        if (!title || !body) {
            return res.status(400).json({ error: 'Title and body are required' });
        }

        let result;

        if (targetUid) {
            // Send to specific user via their FCM token
            const userDoc = await db.collection('users').doc(targetUid).get();
            const fcmToken = userDoc.data()?.fcmToken;
            if (!fcmToken) {
                return res.status(400).json({ error: 'User has no FCM token registered' });
            }
            result = await messaging.send({
                token: fcmToken,
                notification: { title, body },
                data: { type: 'admin_notification' },
            });
        } else {
            // Broadcast to all users via topic
            result = await messaging.send({
                topic: 'all_users',
                notification: { title, body },
                data: { type: 'admin_broadcast' },
            });
        }

        // Save to notification history
        const saved = await db.collection('admin_notifications').add({
            title,
            body,
            targetUid: targetUid || 'all',
            sentAt: new Date().toISOString(),
            sentBy: req.admin.email,
            result: result || 'broadcast_sent',
        });

        await logAudit('send_notification', req.admin.email, { title, targetUid: targetUid || 'all' });

        return res.json({ success: true, id: saved.id });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to send notification', details: err.message });
    }
});

// GET /api/notifications/history — Get notification history
router.get('/history', authenticateAdmin, async (req, res) => {
    try {
        const snap = await db.collection('admin_notifications').orderBy('sentAt', 'desc').limit(100).get();
        const notifications = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ notifications });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch history' });
    }
});

// POST /api/notifications/register-token — Register device FCM token (called from Flutter app)
router.post('/register-token', async (req, res) => {
    try {
        const { uid, fcmToken } = req.body;
        if (!uid || !fcmToken) return res.status(400).json({ error: 'uid and fcmToken required' });

        await db.collection('users').doc(uid).update({ fcmToken });

        // Subscribe user to the all_users topic so broadcasts work
        try {
            await messaging.subscribeToTopic([fcmToken], 'all_users');
        } catch (_) { }

        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to register token' });
    }
});

module.exports = router;
