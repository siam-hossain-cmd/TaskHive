const express = require('express');
const { db, messaging } = require('../firebase');
const { authenticateUser } = require('../middleware/auth');

const router = express.Router();

// ─── Helper: Send notification to a user ──────────────────────────────────────
async function notifyUser(userId, title, body, payload = {}) {
    try {
        // Save in-app notification
        await db.collection('users').doc(userId).collection('notifications').add({
            title,
            body,
            type: payload.type || 'general',
            createdAt: new Date(),
            isRead: false,
            relatedId: payload.relatedId || null,
        });

        // Send push notification
        const tokenSnap = await db.collection('users').doc(userId).get();
        const fcmToken = tokenSnap.data()?.fcmToken;
        if (fcmToken) {
            await messaging.send({
                token: fcmToken,
                notification: { title, body },
                data: Object.fromEntries(
                    Object.entries(payload).map(([k, v]) => [k, String(v)])
                ),
            }).catch(() => {}); // Ignore push failures
        }
    } catch (err) {
        console.error('Notification error:', err.message);
    }
}

// ─── POST /api/assignments — Create a new assignment with subtasks ───────────
router.post('/', authenticateUser, async (req, res) => {
    try {
        const {
            groupId, title, subject, summary,
            originalPdfUrl, dueDate, subtasks,
        } = req.body;

        if (!groupId || !title || !subtasks || subtasks.length === 0) {
            return res.status(400).json({ error: 'groupId, title, and subtasks are required' });
        }

        // 1. Create the assignment document
        const assignmentData = {
            groupId,
            createdBy: req.user.uid,
            title,
            subject: subject || '',
            summary: summary || '',
            originalPdfUrl: originalPdfUrl || null,
            finalDocUrl: null,
            compilerId: null,
            status: 'active',
            subtaskIds: [],
            dueDate: dueDate || null,
            createdAt: new Date().toISOString(),
        };

        const assignmentRef = await db.collection('assignments').add(assignmentData);
        const assignmentId = assignmentRef.id;

        // 2. Create group tasks for each subtask
        const subtaskIds = [];
        const notificationPromises = [];

        for (const subtask of subtasks) {
            const taskData = {
                groupId,
                assignmentId,
                assignedTo: subtask.assignedToId || subtask.assignedTo || null,
                assignedBy: req.user.uid,
                title: subtask.title,
                description: subtask.description || '',
                status: 'pending',
                rejectionFeedback: null,
                attachments: [],
                submissionUrl: null,
                submissionFileName: null,
                submittedAt: null,
                approvedAt: null,
                dueDate: dueDate || null,
                priority: subtask.priority || 'medium',
                createdAt: new Date().toISOString(),
            };

            const taskRef = await db.collection('group_tasks').add(taskData);
            subtaskIds.push(taskRef.id);

            // Notify assigned member
            const assigneeId = subtask.assignedToId || subtask.assignedTo;
            if (assigneeId && assigneeId !== req.user.uid) {
                notificationPromises.push(
                    notifyUser(assigneeId, 'New Task Assigned', 
                        `You've been assigned: "${subtask.title}"`, {
                            type: 'task_assigned',
                            relatedId: assignmentId,
                            groupId,
                        })
                );
            }
        }

        // 3. Update assignment with subtask IDs
        await assignmentRef.update({ subtaskIds });

        // 4. Send all notifications
        await Promise.all(notificationPromises);

        return res.json({
            success: true,
            assignmentId,
            subtaskIds,
        });
    } catch (err) {
        console.error('Create assignment error:', err);
        return res.status(500).json({ error: 'Failed to create assignment' });
    }
});

// ─── GET /api/assignments/:id — Get assignment details ───────────────────────
router.get('/:id', authenticateUser, async (req, res) => {
    try {
        const doc = await db.collection('assignments').doc(req.params.id).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Assignment not found' });
        }

        const assignment = { id: doc.id, ...doc.data() };

        // Fetch subtasks
        const tasksSnap = await db.collection('group_tasks')
            .where('assignmentId', '==', req.params.id)
            .orderBy('createdAt')
            .get();
        
        const subtasks = tasksSnap.docs.map(d => ({ id: d.id, ...d.data() }));

        return res.json({ assignment, subtasks });
    } catch (err) {
        console.error('Get assignment error:', err);
        return res.status(500).json({ error: 'Failed to fetch assignment' });
    }
});

// ─── GET /api/assignments/group/:groupId — Get all assignments for a group ───
router.get('/group/:groupId', authenticateUser, async (req, res) => {
    try {
        const snap = await db.collection('assignments')
            .where('groupId', '==', req.params.groupId)
            .orderBy('createdAt', 'desc')
            .get();
        
        const assignments = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ assignments });
    } catch (err) {
        console.error('Get group assignments error:', err);
        return res.status(500).json({ error: 'Failed to fetch assignments' });
    }
});

// ─── POST /api/assignments/:id/assign-compiler — Assign a compiler ──────────
router.post('/:id/assign-compiler', authenticateUser, async (req, res) => {
    try {
        const { compilerId } = req.body;
        if (!compilerId) {
            return res.status(400).json({ error: 'compilerId is required' });
        }

        await db.collection('assignments').doc(req.params.id).update({
            compilerId,
            status: 'compilationPhase',
        });

        // Get assignment title for notification
        const assignmentDoc = await db.collection('assignments').doc(req.params.id).get();
        const assignmentTitle = assignmentDoc.data()?.title || 'Assignment';

        // Notify compiler
        await notifyUser(compilerId, 'Compilation Task',
            `You've been assigned to compile the final report for: "${assignmentTitle}"`, {
                type: 'compiler_assigned',
                relatedId: req.params.id,
            });

        return res.json({ success: true });
    } catch (err) {
        console.error('Assign compiler error:', err);
        return res.status(500).json({ error: 'Failed to assign compiler' });
    }
});

// ─── POST /api/assignments/:id/upload-final — Upload final compiled doc ─────
router.post('/:id/upload-final', authenticateUser, async (req, res) => {
    try {
        const { finalDocUrl, finalDocName } = req.body;
        if (!finalDocUrl) {
            return res.status(400).json({ error: 'finalDocUrl is required' });
        }

        await db.collection('assignments').doc(req.params.id).update({
            finalDocUrl,
            finalDocName: finalDocName || 'final_document',
        });

        return res.json({ success: true });
    } catch (err) {
        console.error('Upload final doc error:', err);
        return res.status(500).json({ error: 'Failed to upload final document' });
    }
});

// ─── POST /api/assignments/:id/complete — Mark assignment as completed ──────
router.post('/:id/complete', authenticateUser, async (req, res) => {
    try {
        const assignmentDoc = await db.collection('assignments').doc(req.params.id).get();
        if (!assignmentDoc.exists) {
            return res.status(404).json({ error: 'Assignment not found' });
        }

        const assignment = assignmentDoc.data();

        await db.collection('assignments').doc(req.params.id).update({
            status: 'completed',
            completedAt: new Date().toISOString(),
        });

        // Notify all group members
        const groupDoc = await db.collection('groups').doc(assignment.groupId).get();
        if (groupDoc.exists) {
            const memberIds = groupDoc.data().memberIds || [];
            const notificationPromises = memberIds
                .filter(id => id !== req.user.uid)
                .map(memberId =>
                    notifyUser(memberId, 'Assignment Completed!',
                        `"${assignment.title}" has been marked as complete! 🎉`, {
                            type: 'assignment_completed',
                            relatedId: req.params.id,
                        })
                );
            await Promise.all(notificationPromises);
        }

        return res.json({ success: true });
    } catch (err) {
        console.error('Complete assignment error:', err);
        return res.status(500).json({ error: 'Failed to complete assignment' });
    }
});

module.exports = router;
