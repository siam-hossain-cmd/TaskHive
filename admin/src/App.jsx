import { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { getMe } from './services/api';

import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Groups from './pages/Groups';
import Tasks from './pages/Tasks';
import Notifications from './pages/Notifications';
import Health from './pages/Health';
import Audit from './pages/Audit';
import AISettings from './pages/AISettings';
import AIUsage from './pages/AIUsage';

function App() {
    const [admin, setAdmin] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('admin_token');
        if (!token) {
            setLoading(false);
            return;
        }
        getMe()
            .then(res => setAdmin(res.data))
            .catch(() => localStorage.removeItem('admin_token'))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="spinner" style={{ margin: 'auto', marginTop: '20%' }} />;

    if (!admin) {
        return <Login onLogin={setAdmin} />;
    }

    return (
        <BrowserRouter>
            <Layout admin={admin} onLogout={() => { localStorage.removeItem('admin_token'); setAdmin(null); }}>
                <Routes>
                    <Route path="/" element={<Dashboard />} />
                    <Route path="/users" element={<Users />} />
                    <Route path="/groups" element={<Groups />} />
                    <Route path="/tasks" element={<Tasks />} />
                    <Route path="/notifications" element={<Notifications />} />
                    <Route path="/health" element={<Health />} />
                    <Route path="/audit" element={<Audit />} />
                    <Route path="/ai-settings" element={<AISettings />} />
                    <Route path="/ai-usage" element={<AIUsage />} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
            </Layout>
        </BrowserRouter>
    );
}

export default App;
