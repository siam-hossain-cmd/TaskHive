const express = require('express');
const { db } = require('../firebase');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

const logAudit = async (action, adminEmail, details = {}) => {
    await db.collection('admin_audit_logs').add({
        action, adminEmail, details, timestamp: new Date().toISOString(),
    });
};

// GET /api/groups — List all groups
router.get('/', authenticateAdmin, async (req, res) => {
    try {
        const snap = await db.collection('groups').orderBy('createdAt', 'desc').limit(200).get();
        const groups = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ groups, count: groups.length });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch groups' });
    }
});

// GET /api/groups/:id/members — Get members of a group
router.get('/:id/members', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const snap = await db.collection('group_members').where('groupId', '==', id).get();
        const members = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        return res.json({ members });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to fetch members' });
    }
});

// DELETE /api/groups/:id — Delete a group
router.delete('/:id', authenticateAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        await db.collection('groups').doc(id).delete();
        await logAudit('delete_group', req.admin.email, { groupId: id });
        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Failed to delete group' });
    }
});

module.exports = router;
