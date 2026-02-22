import { NavLink, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { LayoutDashboard, Users, Component, CheckCircle, Bell, Activity, ClipboardList } from 'lucide-react';

const navItems = [
    { to: '/', label: 'Dashboard', icon: <LayoutDashboard size={18} /> },
    { to: '/users', label: 'Users', icon: <Users size={18} /> },
    { to: '/groups', label: 'Groups', icon: <Component size={18} /> },
    { to: '/tasks', label: 'Tasks', icon: <CheckCircle size={18} /> },
    { to: '/notifications', label: 'Notifications', icon: <Bell size={18} /> },
    { to: '/health', label: 'System Health', icon: <Activity size={18} /> },
    { to: '/audit', label: 'Audit Logs', icon: <ClipboardList size={18} /> },
];

export default function Layout({ children, admin, onLogout }) {
    const location = useLocation();

    const pageTitle = navItems.find(n => {
        if (n.to === '/') return location.pathname === '/';
        return location.pathname.startsWith(n.to);
    })?.label || 'Dashboard';

    return (
        <div className="layout">
            {/* Sidebar */}
            <nav className="sidebar">
                <div className="brand">
                    <div className="brand-icon">🐝</div>
                    <div>
                        <span className="brand-name">TaskHive</span>
                        <span className="brand-badge">ADMIN</span>
                    </div>
                </div>

                <div className="nav-section">Navigation</div>
                {navItems.map(({ to, label, icon }) => (
                    <NavLink
                        key={to}
                        to={to}
                        end={to === '/'}
                        className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
                    >
                        <span className="icon">{icon}</span>
                        {label}
                    </NavLink>
                ))}

                <div style={{ flex: 1 }} />
                <div className="divider" />

                <div style={{ padding: '8px 12px' }}>
                    <div style={{ fontSize: 12, color: 'var(--text-3)', marginBottom: 8 }}>
                        Signed in as
                    </div>
                    <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-2)', wordBreak: 'break-all', marginBottom: 12 }}>
                        {admin?.email}
                    </div>
                    <button className="btn btn-ghost btn-sm w-full" onClick={onLogout}>
                        → Sign Out
                    </button>
                </div>
            </nav>

            {/* Main */}
            <div className="main">
                <div className="topbar">
                    <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 15, fontWeight: 700 }}>{pageTitle}</div>
                        <div style={{ fontSize: 11.5, color: 'var(--text-3)' }}>TaskHive Admin Console</div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <div className="status-dot dot-green" />
                        <span style={{ fontSize: 12, color: 'var(--text-2)' }}>All systems operational</span>
                    </div>
                </div>

                <motion.div
                    key={location.pathname}
                    initial={{ opacity: 0, y: 12 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.25 }}
                    className="page"
                >
                    {children}
                </motion.div>
            </div>
        </div>
    );
}
