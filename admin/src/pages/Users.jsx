import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { getUsers, banUser, deleteUser } from '../services/api';
import { Search, Ban, Trash2, ShieldCheck, MoreVertical } from 'lucide-react';

export default function Users() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [selectedUser, setSelectedUser] = useState(null);

    const fetchUsers = () => {
        setLoading(true);
        getUsers()
            .then(res => setUsers(res.data.users))
            .catch(console.error)
            .finally(() => setLoading(false));
    };

    useEffect(() => { fetchUsers(); }, []);

    const handleBan = async (uid, isBanned) => {
        if (!window.confirm(`Are you sure you want to ${isBanned ? 'unban' : 'ban'} this user?`)) return;
        try {
            await banUser(uid, !isBanned);
            fetchUsers();
        } catch (err) { alert('Failed to ban user'); }
    };

    const handleDelete = async (uid) => {
        if (!window.confirm('WARNING: Irreversible action. Delete user permanently?')) return;
        try {
            await deleteUser(uid);
            fetchUsers();
        } catch (err) { alert('Failed to delete user'); }
    };

    const filtered = users.filter(u =>
        (u.email || '').toLowerCase().includes(search.toLowerCase()) ||
        (u.displayName || '').toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">User Management</h1>
                    <p className="page-subtitle">View, moderate, and manage all registered accounts.</p>
                </div>
                <div className="search-wrap" style={{ width: 260 }}>
                    <Search className="icon" size={16} />
                    <input
                        type="text"
                        className="input"
                        placeholder="Search email or name..."
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                    />
                </div>
            </div>

            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="card table-wrap">
                {loading ? (
                    <div className="spinner mt-6 mb-6 mx-auto" />
                ) : (
                    <table>
                        <thead>
                            <tr>
                                <th>User / Email</th>
                                <th>Joined Date</th>
                                <th>Status</th>
                                <th style={{ textAlign: 'right' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filtered.map(u => (
                                <tr key={u.uid}>
                                    <td>
                                        <div className="flex items-center gap-3">
                                            <div className="avatar" style={{ background: u.photoURL ? 'transparent' : 'var(--primary-200)', color: 'var(--primary)' }}>
                                                {u.photoURL ? <img src={u.photoURL} alt="" className="avatar" /> : u.email?.[0]?.toUpperCase()}
                                            </div>
                                            <div>
                                                <div className="font-bold text-sm" style={{ color: 'var(--text)' }}>{u.displayName || 'No Name'}</div>
                                                <div className="text-xs text-muted">{u.email}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td>{new Date(u.createdAt).toLocaleDateString()}</td>
                                    <td>
                                        <span className={`badge ${u.disabled ? 'badge-red' : 'badge-green'}`}>
                                            {u.disabled ? 'Banned' : 'Active'}
                                        </span>
                                    </td>
                                    <td style={{ textAlign: 'right' }}>
                                        <div className="flex gap-2" style={{ justifyContent: 'flex-end' }}>
                                            <button
                                                onClick={() => handleBan(u.uid, u.disabled)}
                                                className={`btn btn-xs ${u.disabled ? 'btn-success' : 'btn-ghost'}`}
                                                title={u.disabled ? 'Unban' : 'Ban'}
                                            >
                                                {u.disabled ? <ShieldCheck size={14} /> : <Ban size={14} />}
                                            </button>
                                            <button
                                                onClick={() => handleDelete(u.uid)}
                                                className="btn btn-xs btn-danger"
                                                title="Delete Permanently"
                                            >
                                                <Trash2 size={14} />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {filtered.length === 0 && (
                                <tr>
                                    <td colSpan="4" style={{ textAlign: 'center', padding: '40px 0' }}>
                                        No users found matching your search.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                )}
            </motion.div>
        </div>
    );
}
