import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { getAuditLogs } from '../services/api';
import { ShieldAlert, Search } from 'lucide-react';

export default function Audit() {
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');

    useEffect(() => {
        getAuditLogs()
            .then(res => setLogs(res.data.logs))
            .catch(console.error)
            .finally(() => setLoading(false));
    }, []);

    const formatAction = (action) => {
        return action.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
    };

    const filtered = logs.filter(l =>
        (l.adminEmail || '').toLowerCase().includes(search.toLowerCase()) ||
        (l.action || '').toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">Audit Logs</h1>
                    <p className="page-subtitle">Immutable timeline of all administrative actions and security events.</p>
                </div>
                <div className="search-wrap" style={{ width: 260 }}>
                    <Search className="icon" size={16} />
                    <input
                        type="text"
                        className="input"
                        placeholder="Search email or action..."
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                    />
                </div>
            </div>

            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="card">
                <h3 className="font-bold mb-6 flex items-center gap-2">
                    <ShieldAlert size={18} color="var(--primary)" /> Activity Timeline
                </h3>

                {loading ? <div className="spinner mb-6 mt-6 mx-auto" /> : (
                    <div style={{ paddingLeft: 8 }}>
                        {filtered.map((log, i) => (
                            <motion.div
                                key={log.id}
                                initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.05 }}
                                className="audit-item"
                            >
                                <div className="audit-dot" />
                                <div style={{ paddingBottom: 6 }}>
                                    <div className="audit-action">{formatAction(log.action)}</div>
                                    <div className="audit-meta">
                                        <span className="font-bold" style={{ color: 'var(--text-2)' }}>{log.adminEmail}</span>
                                        {' • '}
                                        {new Date(log.timestamp).toLocaleString()}
                                    </div>
                                    {log.details && Object.keys(log.details).length > 0 && (
                                        <div className="text-xs text-muted mt-2" style={{ background: 'var(--surface-2)', padding: '6px 12px', borderRadius: 8 }}>
                                            <code>{JSON.stringify(log.details)}</code>
                                        </div>
                                    )}
                                </div>
                            </motion.div>
                        ))}
                        {filtered.length === 0 && <div className="text-muted text-center pt-8 pb-8">No audit logs found.</div>}
                    </div>
                )}
            </motion.div>
        </div>
    );
}
