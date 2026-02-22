const express = require('express');
const { db } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

const logAudit = async (action, adminEmail, details = {}) => {
    await db.collection('admin_audit_logs').add({
        action, adminEmail, details, timestamp: new Date().toISOString(),
    });
};

// GET /api/tasks — Get all tasks (paginated)
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

// DELETE /api/tasks/:id — Delete a specific task
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

module.exports = router;
