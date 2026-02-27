const express = require('express');
const { db, messaging } = require('../firebase');
const { authenticateAdmin, authenticateUser } = require('../middleware/auth');

const router = express.Router();

const logAudit = async (action, adminEmail, details = {}) => {
    await db.collection('admin_audit_logs').add({
        action, adminEmail, details, timestamp: new Date().toISOString(),
    });
};

// ─── Helper: Send notification to a user ──────────────────────────────────────
async function notifyUser(userId, title, body, payload = {}) {
    try {
        await db.collection('users').doc(userId).collection('notifications').add({
            title,
            body,
            type: payload.type || 'general',
            createdAt: new Date(),
            isRead: false,
            relatedId: payload.relatedId || null,
        });

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
        console.error('Notification error:', err.message);
    }
}

// GET /api/tasks — Get all tasks (paginated) — Admin only
router.get('/', authenticateAdmin, async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 100;
        const snap = await db.collection('tasks').orderBy('createdAt', 'desc').limit(limit).get();
        const tasks = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ tasks, count: tasks.length });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch tasks' });
    }
});

// DELETE /api/tasks/:id — Delete a specific task — Admin only
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection('tasks').doc(id).delete();
        await logAudit('delete_task', req.admin.email, { taskId: id });
        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to delete task' });
    }
});

// ═══════════════════════════════════════════════════════════════════════════════
//  GROUP TASK ENDPOINTS (User-authenticated)
// ═══════════════════════════════════════════════════════════════════════════════

// ─── POST /api/tasks/:id/submit — Member submits their work ─────────────────
router.post('/:id/submit', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { submissionUrl, submissionFileName } = req.body;

        if (!submissionUrl) {
            return res.status(400).json({ error: 'submissionUrl is required' });
        }

        const taskDoc = await db.collection('group_tasks').doc(id).get();
        if (!taskDoc.exists) {
            return res.status(404).json({ error: 'Task not found' });
        }

        const task = taskDoc.data();

        // Verify the submitter is the assignee
        if (task.assignedTo !== req.user.uid) {
            return res.status(403).json({ error: 'Only the assigned member can submit' });
        }

        // Update task with submission
        await db.collection('group_tasks').doc(id).update({
            submissionUrl,
            submissionFileName: submissionFileName || 'submission',
            submittedAt: new Date().toISOString(),
            status: 'pendingApproval',
        });

        // Notify all group members that this member uploaded
        const groupDoc = await db.collection('groups').doc(task.groupId).get();
        if (groupDoc.exists) {
            const memberIds = groupDoc.data().memberIds || [];
            const userDoc = await db.collection('users').doc(req.user.uid).get();
            const userName = userDoc.data()?.displayName || 'A team member';

            const notificationPromises = memberIds
                .filter(mid => mid !== req.user.uid)
                .map(memberId =>
                    notifyUser(memberId, 'Submission Uploaded',
                        `${userName} uploaded their part: "${task.title}"`, {
                            type: 'task_submitted',
                            relatedId: id,
                            groupId: task.groupId,
                        })
                );
            await Promise.all(notificationPromises);
        }

        return res.json({ success: true, status: 'pendingApproval' });
    } catch (err) {
        console.error('Submit task error:', err);
        return res.status(500).json({ error: 'Failed to submit task' });
    }
});

// ─── POST /api/tasks/:id/approve — Leader approves a submission ─────────────
router.post('/:id/approve', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;

        const taskDoc = await db.collection('group_tasks').doc(id).get();
        if (!taskDoc.exists) {
            return res.status(404).json({ error: 'Task not found' });
        }

        const task = taskDoc.data();

        await db.collection('group_tasks').doc(id).update({
            status: 'approved',
            approvedAt: new Date().toISOString(),
            rejectionFeedback: null,
        });

        // Notify the assignee
        if (task.assignedTo) {
            await notifyUser(task.assignedTo, 'Task Approved! ✅',
                `Your task "${task.title}" has been approved!`, {
                    type: 'task_approved',
                    relatedId: id,
                    groupId: task.groupId,
                });
        }

        return res.json({ success: true, status: 'approved' });
    } catch (err) {
        console.error('Approve task error:', err);
        return res.status(500).json({ error: 'Failed to approve task' });
    }
});

// ─── POST /api/tasks/:id/request-changes — Leader requests changes ──────────
router.post('/:id/request-changes', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { feedback } = req.body;

        if (!feedback) {
            return res.status(400).json({ error: 'feedback is required' });
        }

        const taskDoc = await db.collection('group_tasks').doc(id).get();
        if (!taskDoc.exists) {
            return res.status(404).json({ error: 'Task not found' });
        }

        const task = taskDoc.data();

        await db.collection('group_tasks').doc(id).update({
            status: 'changesRequested',
            rejectionFeedback: feedback,
        });

        // Notify the assignee
        if (task.assignedTo) {
            await notifyUser(task.assignedTo, 'Changes Requested',
                `Leader requested changes on "${task.title}": ${feedback.substring(0, 80)}`, {
                    type: 'changes_requested',
                    relatedId: id,
                    groupId: task.groupId,
                });
        }

        return res.json({ success: true, status: 'changesRequested' });
    } catch (err) {
        console.error('Request changes error:', err);
        return res.status(500).json({ error: 'Failed to request changes' });
    }
});

// ─── GET /api/tasks/:id/comments — Get comments for a task ──────────────────
router.get('/:id/comments', authenticateUser, async (req, res) => {
    try {
        const snap = await db.collection('task_comments')
            .where('taskId', '==', req.params.id)
            .orderBy('createdAt', 'asc')
            .get();

        const comments = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ comments });
    } catch (err) {
        console.error('Get comments error:', err);
        return res.status(500).json({ error: 'Failed to fetch comments' });
    }
});

// ─── POST /api/tasks/:id/comments — Add a comment on a task ────────────────
router.post('/:id/comments', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { text, type } = req.body;

        if (!text) {
            return res.status(400).json({ error: 'text is required' });
        }

        const taskDoc = await db.collection('group_tasks').doc(id).get();
        if (!taskDoc.exists) {
            return res.status(404).json({ error: 'Task not found' });
        }

        const task = taskDoc.data();

        // Get commenter info
        const userDoc = await db.collection('users').doc(req.user.uid).get();
        const userName = userDoc.data()?.displayName || 'Unknown';

        const comment = {
            taskId: id,
            groupId: task.groupId,
            userId: req.user.uid,
            userName,
            text,
            type: type || 'general',
            createdAt: new Date().toISOString(),
        };

        const commentRef = await db.collection('task_comments').add(comment);

        // Notify the task assignee if commenter is not the assignee
        if (task.assignedTo && task.assignedTo !== req.user.uid) {
            await notifyUser(task.assignedTo, 'New Comment',
                `${userName} commented on "${task.title}": ${text.substring(0, 60)}`, {
                    type: 'task_comment',
                    relatedId: id,
                    groupId: task.groupId,
                });
        }

        return res.json({ success: true, commentId: commentRef.id, comment: { id: commentRef.id, ...comment } });
    } catch (err) {
        console.error('Add comment error:', err);
        return res.status(500).json({ error: 'Failed to add comment' });
    }
});

module.exports = router;
