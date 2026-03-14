const express = require('express');
const { db, messaging } = require('../firebase');
const { authenticateUser } = require('../middleware/auth');

const router = express.Router();

// ─── Helper: Send push notification to a user ────────────────────────────────
async function notifyUser(userId, title, body, payload = {}) {
    try {
        // Save in-app notification
        await db.collection('users').doc(userId).collection('notifications').add({
            title,
            body,
            type: payload.type || 'reminder',
            createdAt: new Date(),
            isRead: false,
            relatedId: payload.relatedId || null,
        });

        // Send FCM push
        const tokenSnap = await db.collection('users').doc(userId).get();
        const fcmToken = tokenSnap.data()?.fcmToken;
        if (fcmToken) {
            await messaging.send({
                token: fcmToken,
                notification: { title, body },
                data: Object.fromEntries(
                    Object.entries(payload).map(([k, v]) => [k, String(v)])
                ),
            }).catch(() => {});
        }
    } catch (err) {
        console.error('Reminder notification error:', err.message);
    }
}

// ─── POST /api/reminders — Create a new reminder ─────────────────────────────
router.post('/', authenticateUser, async (req, res) => {
    try {
        const {
            type, title, remark, date, recurrence,
            notifyBeforeMinutes,
        } = req.body;

        if (!title || !date) {
            return res.status(400).json({ error: 'title and date are required' });
        }

        const reminderData = {
            userId: req.user.uid,
            type: type || 'custom',
            title,
            remark: remark || '',
            date: new Date(date),
            recurrence: recurrence || 'none',
            notifyBeforeMinutes: notifyBeforeMinutes || 0,
            isCompleted: false,
            createdAt: new Date(),
        };

        const docRef = await db.collection('reminders').add(reminderData);

        res.status(201).json({
            id: docRef.id,
            ...reminderData,
            date: reminderData.date.toISOString(),
            createdAt: reminderData.createdAt.toISOString(),
        });
    } catch (err) {
        console.error('Create reminder error:', err);
        res.status(500).json({ error: 'Failed to create reminder' });
    }
});

// ─── GET /api/reminders — List user's reminders ──────────────────────────────
router.get('/', authenticateUser, async (req, res) => {
    try {
        const snapshot = await db.collection('reminders')
            .where('userId', '==', req.user.uid)
            .orderBy('date', 'asc')
            .get();

        const reminders = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
            date: doc.data().date?.toDate?.()?.toISOString() || null,
            createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
        }));

        res.json(reminders);
    } catch (err) {
        console.error('List reminders error:', err);
        res.status(500).json({ error: 'Failed to fetch reminders' });
    }
});

// ─── GET /api/reminders/:id — Get a single reminder ─────────────────────────
router.get('/:id', authenticateUser, async (req, res) => {
    try {
        const doc = await db.collection('reminders').doc(req.params.id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Reminder not found' });
        }

        const data = doc.data();
        if (data.userId !== req.user.uid) {
            return res.status(403).json({ error: 'Access denied' });
        }

        res.json({
            id: doc.id,
            ...data,
            date: data.date?.toDate?.()?.toISOString() || null,
            createdAt: data.createdAt?.toDate?.()?.toISOString() || null,
        });
    } catch (err) {
        console.error('Get reminder error:', err);
        res.status(500).json({ error: 'Failed to fetch reminder' });
    }
});

// ─── PUT /api/reminders/:id — Update a reminder ─────────────────────────────
router.put('/:id', authenticateUser, async (req, res) => {
    try {
        const doc = await db.collection('reminders').doc(req.params.id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Reminder not found' });
        }

        const data = doc.data();
        if (data.userId !== req.user.uid) {
            return res.status(403).json({ error: 'Access denied' });
        }

        const updates = {};
        const allowedFields = ['type', 'title', 'remark', 'date', 'recurrence', 'notifyBeforeMinutes', 'isCompleted'];

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                updates[field] = field === 'date' ? new Date(req.body[field]) : req.body[field];
            }
        }

        await db.collection('reminders').doc(req.params.id).update(updates);

        res.json({ message: 'Reminder updated', id: req.params.id });
    } catch (err) {
        console.error('Update reminder error:', err);
        res.status(500).json({ error: 'Failed to update reminder' });
    }
});

// ─── DELETE /api/reminders/:id — Delete a reminder ──────────────────────────
router.delete('/:id', authenticateUser, async (req, res) => {
    try {
        const doc = await db.collection('reminders').doc(req.params.id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Reminder not found' });
        }

        const data = doc.data();
        if (data.userId !== req.user.uid) {
            return res.status(403).json({ error: 'Access denied' });
        }

        await db.collection('reminders').doc(req.params.id).delete();

        res.json({ message: 'Reminder deleted' });
    } catch (err) {
        console.error('Delete reminder error:', err);
        res.status(500).json({ error: 'Failed to delete reminder' });
    }
});

// ─── POST /api/reminders/:id/complete — Mark reminder as completed ──────────
router.post('/:id/complete', authenticateUser, async (req, res) => {
    try {
        const doc = await db.collection('reminders').doc(req.params.id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Reminder not found' });
        }

        const data = doc.data();
        if (data.userId !== req.user.uid) {
            return res.status(403).json({ error: 'Access denied' });
        }

        await db.collection('reminders').doc(req.params.id).update({
            isCompleted: true,
        });

        res.json({ message: 'Reminder completed' });
    } catch (err) {
        console.error('Complete reminder error:', err);
        res.status(500).json({ error: 'Failed to complete reminder' });
    }
});

// ─── POST /api/reminders/check-due — Check and send notifications for due reminders ─
// This can be called by a cron job / Cloud Scheduler to handle server-side notifications
router.post('/check-due', async (req, res) => {
    try {
        const now = new Date();
        const windowEnd = new Date(now.getTime() + 2 * 60 * 1000); // 2-minute window

        // Find reminders that are due in the next 2 minutes and not completed
        const snapshot = await db.collection('reminders')
            .where('isCompleted', '==', false)
            .where('date', '>=', now)
            .where('date', '<=', windowEnd)
            .get();

        let notified = 0;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const reminderDate = data.date.toDate();
            const notifyTime = new Date(reminderDate.getTime() - (data.notifyBeforeMinutes || 0) * 60 * 1000);

            // Check if it's time to notify (within the window)
            if (notifyTime >= now && notifyTime <= windowEnd) {
                const bodyText = data.remark
                    ? `${data.type}: ${data.remark}`
                    : `Reminder: ${data.type}`;

                await notifyUser(data.userId, data.title, bodyText, {
                    type: 'reminder',
                    relatedId: doc.id,
                });
                notified++;
            }
        }

        res.json({ message: `Checked and notified ${notified} reminders` });
    } catch (err) {
        console.error('Check due reminders error:', err);
        res.status(500).json({ error: 'Failed to check due reminders' });
    }
});

module.exports = router;
