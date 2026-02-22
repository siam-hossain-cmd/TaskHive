import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { sendNotification, getNotificationHistory } from '../services/api';
import { Send, Clock, Users, User } from 'lucide-react';

export default function Notifications() {
    const [history, setHistory] = useState([]);
    const [loading, setLoading] = useState(true);
    const [sending, setSending] = useState(false);
    const [form, setForm] = useState({ title: '', body: '', targetUid: '' });

    const fetchHistory = () => {
        getNotificationHistory()
            .then(res => setHistory(res.data.notifications))
            .catch(console.error)
            .finally(() => setLoading(false));
    };

    useEffect(() => { fetchHistory(); }, []);

    const handleSend = async (e) => {
        e.preventDefault();
        if (!form.title || !form.body) return alert('Title and body required');
        if (!window.confirm(`Send this push notification to ${form.targetUid ? 'this specific user' : 'ALL users'}?`)) return;

        setSending(true);
        try {
            await sendNotification(form);
            alert('Notification sent successfully!');
            setForm({ title: '', body: '', targetUid: '' });
            fetchHistory();
        } catch (err) { alert('Failed to send notification'); }
        finally { setSending(false); }
    };

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">Push Notifications</h1>
                    <p className="page-subtitle">Send targeted messages or global announcements to user devices.</p>
                </div>
            </div>

            <div className="grid-2 mt-6">
                <motion.div initial={{ opacity: 0, x: -16 }} animate={{ opacity: 1, x: 0 }} className="card">
                    <h3 className="font-bold mb-6 flex items-center gap-2">
                        <Send size={18} color="var(--primary)" /> Compose Message
                    </h3>
                    <form onSubmit={handleSend} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                        <div className="input-group">
                            <label className="label">Target Audience</label>
                            <div className="flex gap-2">
                                <button
                                    type="button"
                                    className={`btn btn-sm ${!form.targetUid ? 'btn-primary' : 'btn-ghost'}`}
                                    onClick={() => setForm({ ...form, targetUid: '' })}
                                >
                                    <Users size={14} /> Broadcast All
                                </button>
                                <button
                                    type="button"
                                    className={`btn btn-sm ${form.targetUid ? 'btn-primary' : 'btn-ghost'}`}
                                    onClick={() => setForm({ ...form, targetUid: 'SPECIFIC_UID_HERE' })}
                                >
                                    <User size={14} /> Specific User
                                </button>
                            </div>
                        </div>

                        {form.targetUid !== '' && (
                            <div className="input-group">
                                <label className="label">User UID</label>
                                <input
                                    type="text" className="input"
                                    placeholder="Paste exactly user UID here..."
                                    value={form.targetUid !== 'SPECIFIC_UID_HERE' ? form.targetUid : ''}
                                    onChange={e => setForm({ ...form, targetUid: e.target.value })}
                                />
                            </div>
                        )}

                        <div className="input-group">
                            <label className="label">Notification Title</label>
                            <input
                                type="text" className="input"
                                placeholder="E.g., System Update, Welcome back!"
                                value={form.title} onChange={e => setForm({ ...form, title: e.target.value })}
                                required
                            />
                        </div>
                        <div className="input-group">
                            <label className="label">Message Body</label>
                            <textarea
                                className="input textarea"
                                placeholder="Write the content of your push notification here..."
                                value={form.body} onChange={e => setForm({ ...form, body: e.target.value })}
                                required
                            />
                        </div>

                        <button type="submit" className="btn btn-primary" style={{ justifyContent: 'center', marginTop: 8 }} disabled={sending}>
                            {sending ? <span className="spinner" style={{ width: 16, height: 16, borderWidth: 2 }} /> : <Send size={16} />}
                            {sending ? 'Sending via FCM...' : 'Push to Devices'}
                        </button>
                    </form>
                </motion.div>

                <motion.div initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }} className="card">
                    <h3 className="font-bold mb-6 flex items-center gap-2">
                        <Clock size={18} color="var(--primary)" /> Sent History
                    </h3>
                    {loading ? <div className="spinner mx-auto" /> : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 12, maxHeight: 500, overflowY: 'auto', paddingRight: 4 }}>
                            {history.map(item => (
                                <div key={item.id} className="notif-preview flex items-start justify-between gap-4">
                                    <div>
                                        <div className="notif-preview-title">{item.title}</div>
                                        <div className="notif-preview-body">{item.body}</div>
                                        <div className="text-xs text-muted mt-4">
                                            Target: {item.targetUid === 'all' ? <span className="badge badge-purple">All Users</span> : <span className="badge badge-yellow">{item.targetUid}</span>}
                                        </div>
                                    </div>
                                    <div className="text-xs text-muted font-bold" style={{ whiteSpace: 'nowrap' }}>
                                        {new Date(item.sentAt).toLocaleDateString()}
                                    </div>
                                </div>
                            ))}
                            {history.length === 0 && <div className="text-muted text-center pt-8">No notifications sent yet.</div>}
                        </div>
                    )}
                </motion.div>
            </div>
        </div>
    );
}
