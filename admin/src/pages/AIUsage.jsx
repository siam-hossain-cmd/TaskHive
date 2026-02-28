import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { BarChart3, Users, Zap, DollarSign, Clock, AlertTriangle, TrendingUp, XCircle, Search, ChevronDown, ChevronUp, Ban, Check } from 'lucide-react';
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { getAIUsage, getAIUserUsage, updateAIAccess } from '../services/api';

// ─── Demo data for when no real usage exists yet ─────────────────────────────
function generateDemoData() {
    const now = new Date();
    const dailyStats = [];
    for (let i = 6; i >= 0; i--) {
        const d = new Date(now - i * 24 * 60 * 60 * 1000);
        const date = d.toISOString().substring(0, 10);
        const requests = Math.floor(Math.random() * 40) + 5;
        const tokens = requests * (Math.floor(Math.random() * 3000) + 1500);
        dailyStats.push({ date, requests, tokens, cost: (tokens / 1000000) * 0.15 });
    }

    const totalRequests = dailyStats.reduce((s, d) => s + d.requests, 0);
    const totalTokens = dailyStats.reduce((s, d) => s + d.tokens, 0);

    const demoUsers = [
        { userId: 'demo_user_1', userName: 'Arif Rahman', userEmail: 'arif@example.com', requests: 34, tokensUsed: 87500, estimatedCost: 0.0131, lastRequest: new Date(now - 2 * 60 * 60 * 1000).toISOString(), errors: 1 },
        { userId: 'demo_user_2', userName: 'Fatima Akter', userEmail: 'fatima@example.com', requests: 28, tokensUsed: 72300, estimatedCost: 0.0108, lastRequest: new Date(now - 5 * 60 * 60 * 1000).toISOString(), errors: 0 },
        { userId: 'demo_user_3', userName: 'Kamal Hossain', userEmail: 'kamal@example.com', requests: 19, tokensUsed: 45600, estimatedCost: 0.0068, lastRequest: new Date(now - 12 * 60 * 60 * 1000).toISOString(), errors: 2 },
        { userId: 'demo_user_4', userName: 'Nadia Islam', userEmail: 'nadia@example.com', requests: 15, tokensUsed: 38200, estimatedCost: 0.0057, lastRequest: new Date(now - 1 * 24 * 60 * 60 * 1000).toISOString(), errors: 0 },
        { userId: 'demo_user_5', userName: 'Rakib Ahmed', userEmail: 'rakib@example.com', requests: 11, tokensUsed: 29800, estimatedCost: 0.0045, lastRequest: new Date(now - 2 * 24 * 60 * 60 * 1000).toISOString(), errors: 0 },
        { userId: 'demo_user_6', userName: 'Sadia Sultana', userEmail: 'sadia@example.com', requests: 8, tokensUsed: 19400, estimatedCost: 0.0029, lastRequest: new Date(now - 3 * 24 * 60 * 60 * 1000).toISOString(), errors: 1 },
    ];

    return {
        isDemo: true,
        overview: {
            totalRequests,
            totalTokens,
            totalCost: Math.round((totalTokens / 1000000) * 0.15 * 10000) / 10000,
            uniqueUsers: demoUsers.length,
            failedRequests: 4,
            period: '7d',
        },
        perUser: demoUsers,
        dailyStats,
    };
}

export default function AIUsage() {
    const [period, setPeriod] = useState('7d');
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [expandedUser, setExpandedUser] = useState(null);
    const [userDetail, setUserDetail] = useState(null);
    const [detailLoading, setDetailLoading] = useState(false);
    const [toast, setToast] = useState(null);

    useEffect(() => {
        loadUsage();
    }, [period]);

    const loadUsage = async () => {
        setLoading(true);
        try {
            const res = await getAIUsage(period);
            const d = res.data;
            // If no real data, show demo
            if (!d.perUser?.length && !d.dailyStats?.length) {
                setData(generateDemoData());
            } else {
                setData({ ...d, isDemo: false });
            }
        } catch (err) {
            console.error(err);
            // On error, show demo data so the page is still useful
            setData(generateDemoData());
        } finally {
            setLoading(false);
        }
    };

    const showToast = (msg, type = 'success') => {
        setToast({ msg, type });
        setTimeout(() => setToast(null), 3000);
    };

    const handleExpandUser = async (userId) => {
        if (expandedUser === userId) {
            setExpandedUser(null);
            setUserDetail(null);
            return;
        }
        setExpandedUser(userId);
        setDetailLoading(true);

        // If demo data, generate demo user detail
        if (data?.isDemo) {
            const user = perUser.find(u => u.userId === userId);
            const now = new Date();
            setUserDetail({
                userId,
                access: { enabled: true, customQuota: null },
                recentLogs: Array.from({ length: 5 }, (_, i) => ({
                    endpoint: i % 2 === 0 ? 'analyze' : 'refine',
                    status: i === 3 ? 'error' : 'success',
                    tokensUsed: Math.floor(Math.random() * 5000) + 1000,
                    timestamp: new Date(now - i * 3 * 60 * 60 * 1000).toISOString(),
                })),
                totalLogged: user?.requests || 10,
            });
            setDetailLoading(false);
            return;
        }

        try {
            const res = await getAIUserUsage(userId);
            setUserDetail(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setDetailLoading(false);
        }
    };

    const handleToggleAccess = async (userId, currentlyEnabled) => {
        try {
            await updateAIAccess(userId, { enabled: !currentlyEnabled });
            showToast(`AI access ${!currentlyEnabled ? 'enabled' : 'disabled'} for user`);
            // Refresh user detail
            if (expandedUser === userId) {
                const res = await getAIUserUsage(userId);
                setUserDetail(res.data);
            }
        } catch (err) {
            showToast('Failed to update access', 'error');
        }
    };

    const handleSetQuota = async (userId, quota) => {
        try {
            await updateAIAccess(userId, { customQuota: quota });
            showToast('Custom quota set');
            const res = await getAIUserUsage(userId);
            setUserDetail(res.data);
        } catch (err) {
            showToast('Failed to set quota', 'error');
        }
    };

    if (loading) return <div className="spinner mt-6" style={{ margin: 'auto' }} />;

    const overview = data?.overview || {};
    const perUser = data?.perUser || [];
    const dailyStats = data?.dailyStats || [];

    const filteredUsers = perUser.filter(u =>
        u.userName?.toLowerCase().includes(search.toLowerCase()) ||
        u.userEmail?.toLowerCase().includes(search.toLowerCase()) ||
        u.userId?.toLowerCase().includes(search.toLowerCase())
    );

    const statCards = [
        {
            label: 'Total Requests',
            value: overview.totalRequests || 0,
            icon: <Zap size={20} color="var(--primary)" />,
            bg: 'var(--primary-200)',
            sub: `${overview.period || '7d'} period`,
        },
        {
            label: 'Total Tokens',
            value: formatNumber(overview.totalTokens || 0),
            icon: <TrendingUp size={20} color="var(--success)" />,
            bg: 'var(--success-200)',
            sub: 'Consumed',
        },
        {
            label: 'Est. Cost',
            value: `$${(overview.totalCost || 0).toFixed(4)}`,
            icon: <DollarSign size={20} color="var(--warning)" />,
            bg: 'var(--warning-200)',
            sub: 'Approximate',
        },
        {
            label: 'Active AI Users',
            value: overview.uniqueUsers || 0,
            icon: <Users size={20} color="var(--accent)" />,
            bg: 'rgba(139,92,246,0.15)',
            sub: `${overview.failedRequests || 0} errors`,
        },
    ];

    return (
        <div>
            {/* Toast */}
            {toast && (
                <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    style={{
                        position: 'fixed', top: 80, right: 28, zIndex: 200,
                        background: toast.type === 'error' ? 'var(--danger-200)' : 'var(--success-200)',
                        color: toast.type === 'error' ? 'var(--danger)' : 'var(--success)',
                        border: `1px solid ${toast.type === 'error' ? 'var(--danger)' : 'var(--success)'}`,
                        padding: '12px 20px', borderRadius: 'var(--radius)', fontWeight: 600, fontSize: 13,
                    }}
                >
                    {toast.msg}
                </motion.div>
            )}

            <div className="page-header">
                <div>
                    <h1 className="page-title">AI Usage</h1>
                    <p className="page-subtitle">Monitor AI requests, token consumption, and per-user activity.</p>
                </div>
                <div className="flex gap-2">
                    {['24h', '7d', '30d', '90d'].map(p => (
                        <button
                            key={p}
                            className={`btn btn-sm ${period === p ? 'btn-primary' : 'btn-ghost'}`}
                            onClick={() => setPeriod(p)}
                        >
                            {p}
                        </button>
                    ))}
                </div>
            </div>

            {/* Demo Data Banner */}
            {data?.isDemo && (
                <motion.div
                    initial={{ opacity: 0, y: -8 }}
                    animate={{ opacity: 1, y: 0 }}
                    style={{
                        background: 'var(--warning-200)', border: '1px solid var(--warning)',
                        borderRadius: 'var(--radius)', padding: '10px 16px', marginBottom: 16,
                        display: 'flex', alignItems: 'center', gap: 10, fontSize: 13, color: 'var(--warning)', fontWeight: 600,
                    }}
                >
                    <AlertTriangle size={16} />
                    Showing demo data — real analytics will appear once users start using AI features.
                </motion.div>
            )}

            {/* Stats Cards */}
            <div className="grid-4 mb-6">
                {statCards.map((c, i) => (
                    <motion.div
                        key={i}
                        initial={{ opacity: 0, y: 16 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: i * 0.08 }}
                        className="card stat-card"
                    >
                        <div className="flex items-center justify-between">
                            <div className="stat-label">{c.label}</div>
                            <div className="stat-icon" style={{ background: c.bg }}>{c.icon}</div>
                        </div>
                        <div className="stat-value">{c.value}</div>
                        <div style={{ fontSize: 12, color: 'var(--text-3)' }}>{c.sub}</div>
                    </motion.div>
                ))}
            </div>

            {/* Charts */}
            <div className="grid-2 mb-6" style={{ alignItems: 'stretch' }}>
                <motion.div
                    initial={{ opacity: 0, y: 16 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.3 }}
                    className="card card-lg"
                >
                    <h3 className="font-bold" style={{ marginBottom: 20 }}>Daily Requests</h3>
                    <div style={{ height: 220 }}>
                        {dailyStats.length > 0 ? (
                            <ResponsiveContainer>
                                <AreaChart data={dailyStats}>
                                    <defs>
                                        <linearGradient id="reqGrad" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3} />
                                            <stop offset="95%" stopColor="var(--primary)" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <XAxis dataKey="date" stroke="var(--text-3)" fontSize={11} tickLine={false} axisLine={false}
                                        tickFormatter={d => d.substring(5)} />
                                    <YAxis stroke="var(--text-3)" fontSize={11} tickLine={false} axisLine={false} />
                                    <Tooltip
                                        contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 12, fontSize: 12 }}
                                        itemStyle={{ color: 'var(--primary)', fontWeight: 700 }}
                                    />
                                    <Area type="monotone" dataKey="requests" stroke="var(--primary)" strokeWidth={2.5} fillOpacity={1} fill="url(#reqGrad)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="flex items-center" style={{ height: '100%', justifyContent: 'center', color: 'var(--text-3)' }}>
                                No data for this period
                            </div>
                        )}
                    </div>
                </motion.div>

                <motion.div
                    initial={{ opacity: 0, y: 16 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                    className="card card-lg"
                >
                    <h3 className="font-bold" style={{ marginBottom: 20 }}>Daily Token Usage</h3>
                    <div style={{ height: 220 }}>
                        {dailyStats.length > 0 ? (
                            <ResponsiveContainer>
                                <BarChart data={dailyStats}>
                                    <XAxis dataKey="date" stroke="var(--text-3)" fontSize={11} tickLine={false} axisLine={false}
                                        tickFormatter={d => d.substring(5)} />
                                    <YAxis stroke="var(--text-3)" fontSize={11} tickLine={false} axisLine={false}
                                        tickFormatter={v => formatNumber(v)} />
                                    <Tooltip
                                        contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: 12, fontSize: 12 }}
                                        formatter={(val) => [formatNumber(val), 'Tokens']}
                                    />
                                    <Bar dataKey="tokens" fill="var(--accent)" radius={[4, 4, 0, 0]} />
                                </BarChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="flex items-center" style={{ height: '100%', justifyContent: 'center', color: 'var(--text-3)' }}>
                                No data for this period
                            </div>
                        )}
                    </div>
                </motion.div>
            </div>

            {/* Per-User Table */}
            <motion.div
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="card card-lg"
            >
                <div className="flex items-center justify-between" style={{ marginBottom: 16 }}>
                    <h3 className="font-bold">Per-User Usage</h3>
                    <div className="search-wrap" style={{ width: 260 }}>
                        <span className="icon"><Search size={15} /></span>
                        <input
                            className="input"
                            placeholder="Search users..."
                            value={search}
                            onChange={e => setSearch(e.target.value)}
                        />
                    </div>
                </div>

                {filteredUsers.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-3)' }}>
                        <BarChart3 size={32} style={{ marginBottom: 8, opacity: 0.5 }} />
                        <div>No AI usage data found</div>
                        <div style={{ fontSize: 12, marginTop: 4 }}>Usage will appear here once users start using AI features</div>
                    </div>
                ) : (
                    <div className="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>User</th>
                                    <th>Requests</th>
                                    <th>Tokens</th>
                                    <th>Est. Cost</th>
                                    <th>Errors</th>
                                    <th>Last Request</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredUsers.map(user => (
                                    <>
                                        <tr key={user.userId} style={{ cursor: 'pointer' }}
                                            onClick={() => handleExpandUser(user.userId)}>
                                            <td>
                                                <div style={{ fontWeight: 600, color: 'var(--text)' }}>
                                                    {user.userName}
                                                </div>
                                                <div style={{ fontSize: 11, color: 'var(--text-3)' }}>
                                                    {user.userEmail || user.userId.substring(0, 12) + '...'}
                                                </div>
                                            </td>
                                            <td>
                                                <span className="badge badge-purple">{user.requests}</span>
                                            </td>
                                            <td>{formatNumber(user.tokensUsed)}</td>
                                            <td>${user.estimatedCost.toFixed(4)}</td>
                                            <td>
                                                {user.errors > 0
                                                    ? <span className="badge badge-red">{user.errors}</span>
                                                    : <span style={{ color: 'var(--text-3)' }}>0</span>
                                                }
                                            </td>
                                            <td style={{ fontSize: 12 }}>
                                                {user.lastRequest ? formatDate(user.lastRequest) : '—'}
                                            </td>
                                            <td onClick={e => e.stopPropagation()}>
                                                <div className="flex gap-2">
                                                    <button
                                                        className="btn btn-xs btn-ghost"
                                                        onClick={() => handleExpandUser(user.userId)}
                                                        title="View details"
                                                    >
                                                        {expandedUser === user.userId ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>

                                        {/* Expanded Detail Row */}
                                        {expandedUser === user.userId && (
                                            <tr key={`${user.userId}-detail`}>
                                                <td colSpan={7} style={{ padding: 0, background: 'var(--bg)' }}>
                                                    <UserDetailPanel
                                                        userId={user.userId}
                                                        detail={userDetail}
                                                        loading={detailLoading}
                                                        onToggleAccess={handleToggleAccess}
                                                        onSetQuota={handleSetQuota}
                                                    />
                                                </td>
                                            </tr>
                                        )}
                                    </>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </motion.div>
        </div>
    );
}

// ─── User Detail Panel (expanded row) ────────────────────────────────────────
function UserDetailPanel({ userId, detail, loading, onToggleAccess, onSetQuota }) {
    const [quotaHour, setQuotaHour] = useState('');
    const [quotaDay, setQuotaDay] = useState('');

    if (loading) return <div style={{ padding: 20, textAlign: 'center' }}><div className="spinner" style={{ margin: 'auto' }} /></div>;
    if (!detail) return null;

    const access = detail.access || {};
    const isEnabled = access.enabled !== false;

    return (
        <div style={{ padding: 20 }}>
            <div className="grid-3" style={{ gap: 16, marginBottom: 16 }}>
                {/* Access Control */}
                <div style={{
                    background: 'var(--surface)', border: '1px solid var(--border)',
                    borderRadius: 'var(--radius)', padding: 16,
                }}>
                    <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 12 }}>Access Control</div>
                    <div className="flex items-center justify-between" style={{ marginBottom: 12 }}>
                        <span style={{ fontSize: 13, color: 'var(--text-2)' }}>AI Access</span>
                        <button
                            className={`btn btn-xs ${isEnabled ? 'btn-danger' : 'btn-success'}`}
                            onClick={() => onToggleAccess(userId, isEnabled)}
                        >
                            {isEnabled ? <><Ban size={12} /> Disable</> : <><Check size={12} /> Enable</>}
                        </button>
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-3)' }}>
                        Status: <span style={{ color: isEnabled ? 'var(--success)' : 'var(--danger)', fontWeight: 600 }}>
                            {isEnabled ? 'Enabled' : 'Disabled'}
                        </span>
                    </div>
                </div>

                {/* Custom Quota */}
                <div style={{
                    background: 'var(--surface)', border: '1px solid var(--border)',
                    borderRadius: 'var(--radius)', padding: 16,
                }}>
                    <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 12 }}>Custom Quota</div>
                    <div className="input-group" style={{ marginBottom: 8 }}>
                        <input
                            type="number"
                            className="input"
                            placeholder={`Req/hour (default: global)`}
                            value={quotaHour}
                            onChange={e => setQuotaHour(e.target.value)}
                            style={{ fontSize: 12, padding: '6px 10px' }}
                        />
                    </div>
                    <div className="input-group" style={{ marginBottom: 8 }}>
                        <input
                            type="number"
                            className="input"
                            placeholder={`Req/day (default: global)`}
                            value={quotaDay}
                            onChange={e => setQuotaDay(e.target.value)}
                            style={{ fontSize: 12, padding: '6px 10px' }}
                        />
                    </div>
                    <button
                        className="btn btn-xs btn-primary w-full"
                        onClick={() => {
                            const quota = {};
                            if (quotaHour) quota.maxRequestsPerHour = parseInt(quotaHour);
                            if (quotaDay) quota.maxRequestsPerDay = parseInt(quotaDay);
                            onSetQuota(userId, Object.keys(quota).length ? quota : null);
                        }}
                    >
                        {quotaHour || quotaDay ? 'Set Custom Quota' : 'Reset to Global'}
                    </button>
                    {access.customQuota && (
                        <div style={{ fontSize: 11, color: 'var(--warning)', marginTop: 6 }}>
                            Custom: {access.customQuota.maxRequestsPerHour || '?'}/hr, {access.customQuota.maxRequestsPerDay || '?'}/day
                        </div>
                    )}
                </div>

                {/* Recent Activity */}
                <div style={{
                    background: 'var(--surface)', border: '1px solid var(--border)',
                    borderRadius: 'var(--radius)', padding: 16,
                }}>
                    <div style={{ fontWeight: 700, fontSize: 13, marginBottom: 12 }}>Recent Activity</div>
                    <div style={{ fontSize: 12, color: 'var(--text-2)' }}>
                        Total logged: <strong>{detail.totalLogged}</strong>
                    </div>
                    {detail.recentLogs?.slice(0, 5).map((log, i) => (
                        <div key={i} style={{
                            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                            padding: '6px 0', borderBottom: i < 4 ? '1px solid var(--border)' : 'none',
                        }}>
                            <div>
                                <span className={`badge ${log.status === 'error' ? 'badge-red' : 'badge-green'}`}
                                    style={{ fontSize: 10, padding: '1px 6px' }}>
                                    {log.endpoint}
                                </span>
                            </div>
                            <div style={{ fontSize: 10.5, color: 'var(--text-3)' }}>
                                {formatDate(log.timestamp)}
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function formatNumber(num) {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return String(num);
}

function formatDate(dateStr) {
    try {
        const d = new Date(dateStr);
        const now = new Date();
        const diff = now - d;
        if (diff < 60000) return 'Just now';
        if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
        if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
        return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    } catch {
        return dateStr;
    }
}
