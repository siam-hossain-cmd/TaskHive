import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { getHealth } from '../services/api';
import { Activity, Database, Server, Key, AlertTriangle, RefreshCw } from 'lucide-react';

export default function Health() {
    const [health, setHealth] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);

    const checkHealth = () => {
        setLoading(true);
        setError(false);
        getHealth()
            .then(res => setHealth(res.data))
            .catch(() => setError(true))
            .finally(() => setLoading(false));
    };

    useEffect(() => { checkHealth(); }, []);

    const formatUptime = (sec) => {
        const d = Math.floor(sec / 86400);
        const h = Math.floor((sec % 86400) / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return `${d}d ${h}h ${m}m`;
    };

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">System Health & Metrics</h1>
                    <p className="page-subtitle">Monitor Firebase connections, APIs, and server utilization.</p>
                </div>
                <button className="btn btn-primary" onClick={checkHealth} disabled={loading}>
                    <RefreshCw size={14} className={loading ? "spinner-icon" : ""} style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }} />
                    Refresh Diagnostics
                </button>
            </div>

            {error ? (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="card" style={{ background: 'var(--danger-200)', border: '1px solid var(--danger)' }}>
                    <div className="flex items-center gap-3 font-bold" style={{ color: 'var(--danger)' }}>
                        <AlertTriangle size={24} /> CRITICAL: API Backend is unreachable.
                    </div>
                    <p className="text-sm mt-2" style={{ color: 'var(--text-2)' }}>The Node.js server appears to be offline or network connection is lost. Verify the backend process is running successfully on port 3001.</p>
                </motion.div>
            ) : loading && !health ? (
                <div className="spinner mt-12 mx-auto" />
            ) : health ? (
                <>
                    <div className="grid-3 mb-6">
                        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="card stat-card">
                            <div className="stat-label">System Uptime</div>
                            <div className="stat-value text-xl">{formatUptime(health.uptime)}</div>
                            <div className="stat-change up">Stable</div>
                        </motion.div>

                        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="card stat-card">
                            <div className="stat-label">API Response Time</div>
                            <div className="stat-value text-xl">{health.responseTime} ms</div>
                            <div className={`stat-change ${health.responseTime < 200 ? 'up' : 'down'}`}>
                                {health.responseTime < 200 ? 'Excellent' : 'Degraded'}
                            </div>
                        </motion.div>

                        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="card stat-card">
                            <div className="stat-label">Memory Utilization</div>
                            <div className="stat-value text-xl">{health.system.heapUsedMb} MB</div>
                            <div className="stat-change up">Out of {health.system.totalMemoryMb} MB</div>
                        </motion.div>
                    </div>

                    <h3 className="font-bold mb-4 mt-8 flex items-center gap-2">
                        <Activity size={18} color="var(--primary)" /> External Service Status
                    </h3>
                    <div className="grid-3">
                        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="health-service">
                            <div className="flex items-center gap-3">
                                <Database size={18} color={health.services.firestore.status === 'ok' ? 'var(--success)' : 'var(--danger)'} />
                                <span className="health-name">Firebase Firestore</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span className="health-latency">{health.services.firestore.latencyMs} ms</span>
                                <div className={`status-dot ${health.services.firestore.status === 'ok' ? 'dot-green' : 'dot-red'}`} />
                            </div>
                        </motion.div>

                        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.5 }} className="health-service">
                            <div className="flex items-center gap-3">
                                <Key size={18} color={health.services.auth.status === 'ok' ? 'var(--success)' : 'var(--danger)'} />
                                <span className="health-name">Firebase Auth</span>
                            </div>
                            <div className={`status-dot ${health.services.auth.status === 'ok' ? 'dot-green' : 'dot-red'}`} />
                        </motion.div>

                        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.6 }} className="health-service">
                            <div className="flex items-center gap-3">
                                <Server size={18} color="var(--success)" />
                                <span className="health-name">Node.js Engine</span>
                            </div>
                            <div className="text-xs text-muted">{health.system.nodeVersion}</div>
                        </motion.div>
                    </div>
                </>
            ) : null}
        </div>
    );
}
