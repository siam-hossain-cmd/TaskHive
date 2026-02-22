import { useState } from 'react';
import { motion } from 'framer-motion';
import { login } from '../services/api';

export default function Login({ onLogin }) {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const res = await login(email, password);
            localStorage.setItem('admin_token', res.data.token);
            onLogin(res.data);
        } catch (err) {
            setError(err.response?.data?.error || 'Login failed. Check credentials.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="login-page">
            <motion.div
                initial={{ opacity: 0, y: 24 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, ease: 'easeOut' }}
                className="login-card"
            >
                <div className="login-logo">
                    <div className="icon">🐝</div>
                    <div>
                        <div className="name">TaskHive</div>
                        <div className="sub">ADMIN CONSOLE</div>
                    </div>
                </div>

                <div className="login-title">Welcome back</div>
                <div className="login-subtitle">Sign in to your admin account to continue.</div>

                <form onSubmit={handleSubmit} className="login-fields">
                    <div className="input-group">
                        <label className="label">Email Address</label>
                        <input
                            className="input"
                            type="email"
                            placeholder="admin@taskhive.app"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            required
                            autoFocus
                        />
                    </div>
                    <div className="input-group">
                        <label className="label">Password</label>
                        <input
                            className="input"
                            type="password"
                            placeholder="••••••••"
                            value={password}
                            onChange={e => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    {error && (
                        <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            style={{ color: 'var(--danger)', fontSize: 13, background: 'var(--danger-200)', padding: '10px 14px', borderRadius: 10, border: '1px solid var(--danger)' }}
                        >
                            {error}
                        </motion.div>
                    )}

                    <button className="btn btn-primary w-full" type="submit" disabled={loading}>
                        {loading ? <span className="spinner" style={{ width: 17, height: 17, borderWidth: 2 }} /> : null}
                        {loading ? 'Signing in...' : '→ Sign In'}
                    </button>
                </form>

                <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-3)' }}>
                    Protected area — unauthorized access is prohibited.
                </p>

                <div style={{ marginTop: 24, padding: 12, background: 'var(--primary-200)', border: '1px solid var(--primary)', borderRadius: 12 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase', letterSpacing: 0.5 }}>Demo Credentials</div>
                        <button
                            type="button"
                            className="btn btn-primary btn-xs"
                            onClick={() => {
                                setEmail('admin@taskhive.app');
                                setPassword('Admin@TaskHive2026');
                            }}
                        >
                            Auto-Fill
                        </button>
                    </div>
                    <div style={{ fontSize: 13, color: 'var(--text)', display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                        <span style={{ color: 'var(--text-2)' }}>Email:</span>
                        <span style={{ fontWeight: 600 }}>admin@taskhive.app</span>
                    </div>
                    <div style={{ fontSize: 13, color: 'var(--text)', display: 'flex', justifyContent: 'space-between' }}>
                        <span style={{ color: 'var(--text-2)' }}>Password:</span>
                        <span style={{ fontWeight: 600 }}>Admin@TaskHive2026</span>
                    </div>
                </div>
            </motion.div>
        </div>
    );
}
