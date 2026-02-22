const express = require('express');
const { auth, db } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

// Helper: log admin action
const logAudit = async (action, adminEmail, details = {}) => {
    await db.collection('admin_audit_logs').add({
        action,
        adminEmail,
        details,
        timestamp: new Date().toISOString(),
    });
};

// GET /api/users — List all users
router.get('/', authenticateAdmin, async (req, res) => {
    try {
        const listUsersResult = await auth.listUsers(1000);
        const users = listUsersResult.users.map(u => ({
            uid: u.uid,
            email: u.email,
            displayName: u.displayName,
            photoURL: u.photoURL,
            disabled: u.disabled,
            createdAt: u.metadata.creationTime,
            lastSignIn: u.metadata.lastSignInTime,
        }));
        return res.json({ users, count: users.length });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// GET /api/users/:uid — Get user details + their tasks/groups
router.get('/:uid', authenticateAdmin, async (req, res) => {
    try {
        const { uid } = req.params;
        const userRecord = await auth.getUser(uid);

        // Get user profile from Firestore
        const profileDoc = await db.collection('users').doc(uid).get();
        const profile = profileDoc.exists ? profileDoc.data() : {};

        // Get personal tasks
        const tasksSnap = await db.collection('tasks').where('userId', '==', uid).get();
        const tasks = tasksSnap.docs.map(d => ({ id: d.id, ...d.data() }));

        // Get groups
        const membersSnap = await db.collection('group_members').where('uid', '==', uid).get();
        const groupIds = membersSnap.docs.map(d => d.data().groupId);

        return res.json({
            uid: userRecord.uid,
            email: userRecord.email,
            displayName: userRecord.displayName,
            photoURL: userRecord.photoURL,
            disabled: userRecord.disabled,
            createdAt: userRecord.metadata.creationTime,
            lastSignIn: userRecord.metadata.lastSignInTime,
            profile,
            taskCount: tasks.length,
            tasks,
            groupIds,
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch user' });
    }
});

// PATCH /api/users/:uid/ban — Ban or unban user
router.patch('/:uid/ban', authenticateAdmin, async (req, res) => {
    try {
        const { uid } = req.params;
        const { ban } = req.body; // true = ban, false = unban
        await auth.updateUser(uid, { disabled: ban });
        await logAudit(ban ? 'ban_user' : 'unban_user', req.admin.email, { uid });
        return res.json({ success: true, disabled: ban });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to update user' });
    }
});

// DELETE /api/users/:uid — Delete user
router.delete('/:uid', authenticateAdmin, async (req, res) => {
    try {
        const { uid } = req.params;
        await auth.deleteUser(uid);
        // Optionally delete their Firestore profile
        await db.collection('users').doc(uid).delete();
        await logAudit('delete_user', req.admin.email, { uid });
        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to delete user' });
    }
});

// GET /api/users/stats/summary — Get user counts for dashboard
router.get('/stats/summary', authenticateAdmin, async (req, res) => {
    try {
        const listResult = await auth.listUsers(1000);
        const total = listResult.users.length;
        const banned = listResult.users.filter(u => u.disabled).length;

        const now = new Date();
        const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);
        const newThisWeek = listResult.users.filter(u => new Date(u.metadata.creationTime) > sevenDaysAgo).length;

        const tasksSnap = await db.collection('tasks').count().get();
        const groupsSnap = await db.collection('groups').count().get();

        return res.json({
            totalUsers: total,
            bannedUsers: banned,
            newThisWeek,
            totalTasks: tasksSnap.data().count,
            totalGroups: groupsSnap.data().count,
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch stats' });
    }
});

module.exports = router;
