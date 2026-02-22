import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { getUserStats } from '../services/api';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { Users, CheckCircle, Component, Activity } from 'lucide-react';

const mockChartData = [
    { name: 'Mon', active: 120 },
    { name: 'Tue', active: 180 },
    { name: 'Wed', active: 250 },
    { name: 'Thu', active: 210 },
    { name: 'Fri', active: 390 },
    { name: 'Sat', active: 450 },
    { name: 'Sun', active: 410 },
];

export default function Dashboard() {
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        getUserStats()
            .then(res => setStats(res.data))
            .catch(console.error)
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="spinner mt-6 mx-auto" />;

    const cards = [
        { label: 'Total Users', value: stats?.totalUsers || 0, icon: <Users size={20} color="var(--primary)" />, bg: 'var(--primary-200)', change: '+12% this week', up: true },
        { label: 'Total Tasks', value: stats?.totalTasks || 0, icon: <CheckCircle size={20} color="var(--success)" />, bg: 'var(--success-200)', change: '+5% this week', up: true },
        { label: 'Active Groups', value: stats?.totalGroups || 0, icon: <Component size={20} color="var(--warning)" />, bg: 'var(--warning-200)', change: '-2% this week', up: false },
        { label: 'System Health', value: '99.9%', icon: <Activity size={20} color="var(--danger)" />, bg: 'var(--danger-200)', change: 'Optimal', up: true },
    ];

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">Dashboard Overview</h1>
                    <p className="page-subtitle">Real-time statistics and platform health.</p>
                </div>
            </div>

            <div className="grid-4 mb-6">
                {cards.map((c, i) => (
                    <motion.div
                        key={i}
                        initial={{ opacity: 0, y: 16 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: i * 0.1 }}
                        className="card stat-card"
                    >
                        <div className="flex items-center justify-between">
                            <div className="stat-label">{c.label}</div>
                            <div className="stat-icon" style={{ background: c.bg }}>{c.icon}</div>
                        </div>
                        <div className="stat-value">{c.value}</div>
                        <div className={`stat-change ${c.up ? 'up' : 'down'}`}>
                            {c.up ? '↑' : '↓'} {c.change}
                        </div>
                    </motion.div>
                ))}
            </div>

            <motion.div
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="card card-lg"
            >
                <h3 className="font-bold mb-6">Weekly Active Users</h3>
                <div style={{ height: 300, width: '100%' }}>
                    <ResponsiveContainer>
                        <AreaChart data={mockChartData}>
                            <defs>
                                <linearGradient id="colorPv" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <XAxis dataKey="name" stroke="var(--text-3)" fontSize={12} tickLine={false} axisLine={false} />
                            <YAxis stroke="var(--text-3)" fontSize={12} tickLine={false} axisLine={false} />
                            <Tooltip
                                contentStyle={{ background: 'var(--surface)', border: '1px solid var(--border)', borderRadius: '12px' }}
                                itemStyle={{ color: 'var(--primary)', fontWeight: 700 }}
                            />
                            <Area type="monotone" dataKey="active" stroke="var(--primary)" strokeWidth={3} fillOpacity={1} fill="url(#colorPv)" />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            </motion.div>
        </div>
    );
}
