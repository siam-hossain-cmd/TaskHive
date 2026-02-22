import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { getGroups, deleteGroup, getGroupMembers } from '../services/api';
import { Users2, Shield, Trash2, X } from 'lucide-react';

export default function Groups() {
    const [groups, setGroups] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedGroup, setSelectedGroup] = useState(null);
    const [members, setMembers] = useState([]);
    const [membersLoading, setMembersLoading] = useState(false);

    const fetchGroups = () => {
        setLoading(true);
        getGroups()
            .then(res => setGroups(res.data.groups))
            .catch(console.error)
            .finally(() => setLoading(false));
    };

    useEffect(() => { fetchGroups(); }, []);

    const handleDelete = async (id) => {
        if (!window.confirm('WARNING: Irreversible action. Delete group and all its tasks permanently?')) return;
        try {
            await deleteGroup(id);
            fetchGroups();
        } catch (err) { alert('Failed to delete group'); }
    };

    const handleViewMembers = async (group) => {
        setSelectedGroup(group);
        setMembersLoading(true);
        try {
            const res = await getGroupMembers(group.id);
            setMembers(res.data.members);
        } catch (err) { alert('Failed to load members'); }
        finally { setMembersLoading(false); }
    };

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">Groups & Teams</h1>
                    <p className="page-subtitle">Manage shared workspaces and their members.</p>
                </div>
            </div>

            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="card table-wrap">
                {loading ? (
                    <div className="spinner mt-6 mb-6 mx-auto" />
                ) : (
                    <table>
                        <thead>
                            <tr>
                                <th>Group Name</th>
                                <th>Leader UID</th>
                                <th>Created</th>
                                <th style={{ textAlign: 'right' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {groups.map(g => (
                                <tr key={g.id}>
                                    <td>
                                        <div className="font-bold text-sm" style={{ color: 'var(--text)' }}>{g.name}</div>
                                        <div className="text-xs text-muted">ID: {g.id}</div>
                                    </td>
                                    <td>{g.leaderUid}</td>
                                    <td>{g.createdAt ? new Date(g.createdAt).toLocaleDateString() : 'Unknown'}</td>
                                    <td style={{ textAlign: 'right' }}>
                                        <div className="flex gap-2" style={{ justifyContent: 'flex-end' }}>
                                            <button
                                                onClick={() => handleViewMembers(g)}
                                                className="btn btn-xs btn-ghost"
                                                title="View Members"
                                            >
                                                <Users2 size={14} />
                                            </button>
                                            <button
                                                onClick={() => handleDelete(g.id)}
                                                className="btn btn-xs btn-danger"
                                                title="Delete Group"
                                            >
                                                <Trash2 size={14} />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {groups.length === 0 && (
                                <tr><td colSpan="4" style={{ textAlign: 'center', padding: '40px 0' }}>No active groups.</td></tr>
                            )}
                        </tbody>
                    </table>
                )}
            </motion.div>

            {/* Members Modal */}
            {selectedGroup && (
                <div className="modal-backdrop" onClick={() => setSelectedGroup(null)}>
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="modal"
                        onClick={e => e.stopPropagation()}
                    >
                        <div className="flex items-center justify-between mb-6">
                            <h2 className="modal-title" style={{ marginBottom: 0 }}>{selectedGroup.name} Members</h2>
                            <button
                                className="btn btn-ghost"
                                style={{ padding: 6, borderRadius: '50%' }}
                                onClick={() => setSelectedGroup(null)}
                            ><X size={18} /></button>
                        </div>

                        {membersLoading ? (
                            <div className="spinner mx-auto" />
                        ) : (
                            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, maxHeight: 400, overflowY: 'auto' }}>
                                {members.map(m => (
                                    <div key={m.id} className="flex items-center gap-3" style={{ padding: 12, background: 'var(--bg-2)', borderRadius: 12 }}>
                                        <div className="avatar" style={{ background: 'var(--primary-200)', color: 'var(--primary)' }}>
                                            <Users2 size={16} />
                                        </div>
                                        <div style={{ flex: 1 }}>
                                            <div className="text-sm font-bold">{m.uid}</div>
                                            <div className="text-xs text-muted flex items-center gap-1">
                                                <Shield size={12} /> {m.role}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                                {members.length === 0 && <div className="text-muted text-center pt-4">No members found.</div>}
                            </div>
                        )}
                    </motion.div>
                </div>
            )}
        </div>
    );
}
