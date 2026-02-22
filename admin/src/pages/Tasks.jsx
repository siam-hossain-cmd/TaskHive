import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { getTasks, deleteTask } from '../services/api';
import { Trash2, AlertTriangle, EyeOff } from 'lucide-react';

export default function Tasks() {
    const [tasks, setTasks] = useState([]);
    const [loading, setLoading] = useState(true);

    const fetchTasks = () => {
        setLoading(true);
        getTasks()
            .then(res => setTasks(res.data.tasks))
            .catch(console.error)
            .finally(() => setLoading(false));
    };

    useEffect(() => { fetchTasks(); }, []);

    const handleDelete = async (id) => {
        if (!window.confirm('Delete this task permanently? Due to data policy, only use this for violating content.')) return;
        try {
            await deleteTask(id);
            fetchTasks();
        } catch (err) { alert('Failed to delete task'); }
    };

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">Tasks Moderation</h1>
                    <p className="page-subtitle">View and moderate reported or inappropriate tasks.</p>
                </div>
                <div className="badge badge-yellow">
                    <AlertTriangle size={14} /> View-Only Mode Active
                </div>
            </div>

            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="card table-wrap">
                {loading ? (
                    <div className="spinner mt-6 mb-6 mx-auto" />
                ) : (
                    <table>
                        <thead>
                            <tr>
                                <th>Content</th>
                                <th>Owner ID / Group ID</th>
                                <th>Status</th>
                                <th style={{ textAlign: 'right' }}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {tasks.map(t => (
                                <tr key={t.id}>
                                    <td>
                                        <div className="font-bold text-sm" style={{ color: 'var(--text)', display: 'flex', alignItems: 'center', gap: 6 }}>
                                            {t.isPrivate ? <EyeOff size={14} color="var(--text-3)" title="Private Task" /> : null}
                                            {t.title || 'Untitled Task'}
                                        </div>
                                        <div className="text-xs text-muted" style={{ maxWidth: 300, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                            {t.description || 'No description'}
                                        </div>
                                    </td>
                                    <td>
                                        <div className="text-xs">{t.groupId ? `Group: ${t.groupId}` : `User: ${t.userId}`}</div>
                                    </td>
                                    <td>
                                        <span className={`badge ${t.isCompleted ? 'badge-green' : 'badge-yellow'}`}>
                                            {t.isCompleted ? 'Completed' : 'Pending'}
                                        </span>
                                    </td>
                                    <td style={{ textAlign: 'right' }}>
                                        <div className="flex gap-2" style={{ justifyContent: 'flex-end' }}>
                                            <button
                                                onClick={() => handleDelete(t.id)}
                                                className="btn btn-xs btn-danger"
                                                title="Delete Task"
                                            >
                                                <Trash2 size={14} /> Remove
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {tasks.length === 0 && (
                                <tr><td colSpan="4" style={{ textAlign: 'center', padding: '40px 0' }}>No tasks found in the system.</td></tr>
                            )}
                        </tbody>
                    </table>
                )}
            </motion.div>
        </div>
    );
}
