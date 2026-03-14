import { Link } from 'react-router-dom';
import { Download, Zap, Users, Brain, CheckCircle, ArrowRight, Star } from 'lucide-react';

const highlights = [
    { icon: '🧠', label: 'AI-Powered', desc: 'Gemini AI analyzes assignments & breaks them into tasks' },
    { icon: '👥', label: 'Team Collaboration', desc: 'Role-based groups, approval pipelines & live progress' },
    { icon: '📱', label: 'Native Flutter', desc: 'Smooth 120 FPS on iOS & Android with offline support' },
    { icon: '🔔', label: 'Smart Reminders', desc: 'Auto 24-hour warnings & custom notification times' },
];

const stats = [
    { value: '120fps', label: 'Smooth UI' },
    { value: 'AI', label: 'Powered' },
    { value: '100%', label: 'Offline-First' },
    { value: 'Free', label: 'to Download' },
];

export default function Home() {
    return (
        <div style={{ paddingTop: 'var(--nav-h)' }}>

            {/* ── Hero ── */}
            <section style={{
                position: 'relative', overflow: 'hidden',
                padding: '100px 24px 120px', textAlign: 'center',
                minHeight: '92vh', display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center',
            }}>
                {/* Glow blobs */}
                <div className="blob" style={{ width: 600, height: 600, background: '#3b82f6', top: '-10%', left: '-10%', opacity: .18 }} />
                <div className="blob" style={{ width: 400, height: 400, background: '#10d9a0', bottom: '0%', right: '5%', opacity: .15 }} />
                <div className="blob" style={{ width: 300, height: 300, background: '#a855f7', top: '40%', left: '50%', opacity: .12 }} />

                <div style={{ position: 'relative', zIndex: 1, maxWidth: 860, margin: '0 auto' }}>
                    {/* Logo */}
                    <div style={{ marginBottom: 32, display: 'flex', justifyContent: 'center' }}>
                        <div style={{
                            width: 96, height: 96, borderRadius: 24, overflow: 'hidden',
                            background: 'rgba(255,255,255,0.06)',
                            border: '1px solid rgba(255,255,255,0.12)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            boxShadow: '0 0 60px rgba(59,130,246,0.3)',
                        }}>
                            <img src="/logo.png" alt="R-Task" style={{ width: '85%', height: '85%', objectFit: 'contain' }} />
                        </div>
                    </div>

                    <div className="badge badge-blue" style={{ marginBottom: 24 }}>
                        <Zap size={12} /> Smart Task Management
                    </div>

                    <h1 style={{
                        fontFamily: 'Outfit', fontWeight: 900,
                        fontSize: 'clamp(44px, 8vw, 88px)',
                        lineHeight: 1.05, marginBottom: 24,
                    }}>
                        <span style={{ background: 'linear-gradient(135deg,#fff 40%,#94a3b8)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                            Manage Tasks.
                        </span>
                        <br />
                        <span style={{ background: 'linear-gradient(135deg,#3b82f6,#10d9a0)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                            Powered by AI.
                        </span>
                    </h1>

                    <p style={{ fontSize: 'clamp(15px,2.5vw,20px)', color: 'var(--text2)', maxWidth: 600, margin: '0 auto 48px', lineHeight: 1.7 }}>
                        R-Task is a cross-platform Flutter app for personal productivity and group collaboration — with an AI that reads your assignments and automatically builds your task list.
                    </p>

                    <div style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
                        <a href="/apk/rtask.apk" className="btn btn-accent" style={{ fontSize: 16, padding: '16px 32px' }}>
                            <Download size={18} /> Download APK
                        </a>
                        <Link to="/features" className="btn btn-ghost" style={{ fontSize: 16, padding: '16px 32px' }}>
                            Explore Features <ArrowRight size={16} />
                        </Link>
                    </div>
                </div>
            </section>

            {/* ── Stats ── */}
            <section style={{ padding: '0 24px 80px' }}>
                <div style={{ maxWidth: 1140, margin: '0 auto' }}>
                    <div className="grid-4">
                        {stats.map(({ value, label }) => (
                            <div key={label} className="glass-card" style={{ textAlign: 'center', padding: '32px 20px' }}>
                                <div style={{ fontFamily: 'Outfit', fontSize: 40, fontWeight: 900, background: 'linear-gradient(135deg,#3b82f6,#10d9a0)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', marginBottom: 8 }}>
                                    {value}
                                </div>
                                <div style={{ fontSize: 14, color: 'var(--text2)' }}>{label}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* ── Highlights ── */}
            <section className="section">
                <div className="section-tag"><span className="badge badge-green">Why R-Task?</span></div>
                <h2 className="section-title">Everything in one app</h2>
                <p className="section-sub">Built for students, teams, and anyone who needs to stay organized and collaborate effortlessly.</p>

                <div className="grid-2">
                    {highlights.map(({ icon, label, desc }) => (
                        <div key={label} className="glass-card" style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
                            <div style={{ fontSize: 36, flexShrink: 0 }}>{icon}</div>
                            <div>
                                <div style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 19, marginBottom: 8 }}>{label}</div>
                                <div style={{ color: 'var(--text2)', fontSize: 14, lineHeight: 1.7 }}>{desc}</div>
                            </div>
                        </div>
                    ))}
                </div>
            </section>

            {/* ── CTA ── */}
            <section style={{ padding: '60px 24px 100px' }}>
                <div style={{
                    maxWidth: 800, margin: '0 auto', textAlign: 'center',
                    padding: '60px 40px',
                    background: 'linear-gradient(135deg,rgba(59,130,246,0.12),rgba(16,217,160,0.08))',
                    border: '1px solid rgba(59,130,246,0.2)',
                    borderRadius: 28,
                    position: 'relative', overflow: 'hidden',
                }}>
                    <div className="blob" style={{ width: 300, height: 300, background: '#3b82f6', top: '-50px', right: '-50px', opacity: .15 }} />
                    <h2 style={{ fontFamily: 'Outfit', fontWeight: 900, fontSize: 'clamp(28px,5vw,42px)', marginBottom: 16 }}>
                        Ready to get organized?
                    </h2>
                    <p style={{ color: 'var(--text2)', fontSize: 16, marginBottom: 36, lineHeight: 1.7 }}>
                        Download R-Task for Android today — free, no account needed to try.
                    </p>
                    <div style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
                        <a href="/apk/rtask.apk" className="btn btn-accent" style={{ fontSize: 16, padding: '16px 36px' }}>
                            <Download size={18} /> Download APK
                        </a>
                        <Link to="/flow" className="btn btn-ghost">
                            See How It Works <ArrowRight size={16} />
                        </Link>
                    </div>
                </div>
            </section>
        </div>
    );
}
