import { NavLink } from 'react-router-dom';
import { Github, Globe } from 'lucide-react';

export default function Footer() {
    return (
        <footer style={{
            borderTop: '1px solid rgba(255,255,255,0.06)',
            background: 'rgba(7,11,20,0.8)',
            padding: '48px 24px',
        }}>
            <div style={{ maxWidth: 1140, margin: '0 auto' }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px,1fr))', gap: 40, marginBottom: 48 }}>
                    {/* Brand */}
                    <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
                            <img src="/logo.png" alt="R-Task" style={{ width: 32, height: 32, objectFit: 'contain', borderRadius: 8 }} />
                            <span style={{ fontFamily: 'Outfit', fontWeight: 800, fontSize: 20, color: '#fff' }}>R-Task</span>
                        </div>
                        <p style={{ fontSize: 13, color: 'var(--text3)', lineHeight: 1.7, maxWidth: 220 }}>
                            Smart task management and AI-powered collaboration for students and teams.
                        </p>
                    </div>

                    {/* Pages */}
                    <div>
                        <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 16 }}>Pages</div>
                        {[['/', 'Home'], ['/features', 'Features'], ['/architecture', 'Architecture'], ['/flow', 'System Flow'], ['/download', 'Download']].map(([to, label]) => (
                            <NavLink key={to} to={to} end={to === '/'} style={{ display: 'block', fontSize: 14, color: 'var(--text2)', marginBottom: 10, transition: 'color .2s' }}
                                onMouseEnter={e => e.target.style.color = '#fff'}
                                onMouseLeave={e => e.target.style.color = 'var(--text2)'}
                            >{label}</NavLink>
                        ))}
                    </div>

                    {/* Tech Stack */}
                    <div>
                        <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 16 }}>Built With</div>
                        {['Flutter + Dart', 'Firebase', 'Node.js + Express', 'Google Gemini AI', 'Riverpod'].map(t => (
                            <div key={t} style={{ fontSize: 14, color: 'var(--text2)', marginBottom: 10 }}>▸ {t}</div>
                        ))}
                    </div>

                    {/* Download */}
                    <div>
                        <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 16 }}>Download</div>
                        <a href="/apk/rtask.apk" style={{
                            display: 'flex', alignItems: 'center', gap: 8, padding: '12px 16px',
                            background: 'linear-gradient(135deg,#10d9a0,#06b6d4)', borderRadius: 12,
                            color: '#0a1628', fontWeight: 700, fontSize: 14, marginBottom: 12,
                        }}>
                            📱 Android APK
                        </a>
                        <a href="https://r-task.online" style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--text3)' }}>
                            <Globe size={14} /> r-task.online
                        </a>
                    </div>
                </div>

                <div style={{ borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12 }}>
                    <div style={{ fontSize: 13, color: 'var(--text3)' }}>
                        © 2026 R-Task. All rights reserved.
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text3)' }}>
                        Built with Flutter · Firebase · Node.js · Gemini AI
                    </div>
                </div>
            </div>
        </footer>
    );
}
