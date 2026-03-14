import { Download as DownloadIcon, Smartphone, Shield, Zap, CheckCircle } from 'lucide-react';

const requirements = [
    'Android 5.0 (API 21) or higher',
    '100MB free storage space',
    'Internet connection for sync & AI features',
    'Allow installation from unknown sources',
];

const steps = [
    { n: '1', title: 'Download APK', desc: 'Tap the download button below to get the latest R-Task APK file.' },
    { n: '2', title: 'Enable Unknown Sources', desc: 'Go to Settings → Security → Enable "Install from unknown sources".' },
    { n: '3', title: 'Install', desc: 'Open the downloaded file and tap Install. Takes about 10 seconds.' },
    { n: '4', title: 'Sign Up & Go!', desc: 'Create your account or sign in with Google. Start creating tasks!' },
];

export default function Download() {
    return (
        <div style={{ paddingTop: 'var(--nav-h)' }}>
            <div className="page-hero" style={{ paddingBottom: 80 }}>
                <div className="blob" style={{ width: 500, height: 500, background: '#10d9a0', top: '-60px', left: '-60px', opacity: .15 }} />
                <div className="blob" style={{ width: 400, height: 400, background: '#3b82f6', bottom: '-60px', right: '-60px', opacity: .13 }} />

                {/* Logo */}
                <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 32 }}>
                    <div style={{
                        width: 110, height: 110, borderRadius: 28, overflow: 'hidden',
                        background: 'rgba(16,217,160,0.08)',
                        border: '1px solid rgba(16,217,160,0.25)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        boxShadow: '0 0 80px rgba(16,217,160,0.2)',
                    }}>
                        <img src="/logo.png" alt="R-Task" style={{ width: '85%', height: '85%', objectFit: 'contain' }} />
                    </div>
                </div>

                <div className="badge badge-green" style={{ marginBottom: 20 }}><Smartphone size={12} /> Android App</div>
                <h1 className="section-title">Download R-Task</h1>
                <p className="section-sub" style={{ marginBottom: 40 }}>
                    Free to download. Smart task management with AI-powered assignment analysis — all in one app.
                </p>

                {/* Main download button */}
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
                    <a href="/apk/rtask.apk" style={{
                        display: 'inline-flex', alignItems: 'center', gap: 14,
                        padding: '20px 48px',
                        background: 'linear-gradient(135deg,#10d9a0,#06b6d4)',
                        borderRadius: 18, color: '#0a1628',
                        fontFamily: 'Outfit', fontWeight: 800, fontSize: 20,
                        boxShadow: '0 0 60px rgba(16,217,160,0.4)',
                        transition: 'transform 0.2s, box-shadow 0.2s',
                        textDecoration: 'none',
                    }}
                        onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = '0 0 80px rgba(16,217,160,0.5)'; }}
                        onMouseLeave={e => { e.currentTarget.style.transform = 'translateY(0)'; e.currentTarget.style.boxShadow = '0 0 60px rgba(16,217,160,0.4)'; }}
                    >
                        <DownloadIcon size={24} />
                        Download APK
                    </a>
                    <div style={{ fontSize: 13, color: 'var(--text3)' }}>Latest version · Free · No ads · No subscriptions</div>
                </div>
            </div>

            {/* Install steps */}
            <div className="section" style={{ paddingTop: 40 }}>
                <div className="section-tag"><span className="badge badge-blue">Setup</span></div>
                <h2 className="section-title" style={{ fontSize: 36, marginBottom: 12 }}>How to Install</h2>
                <p className="section-sub" style={{ marginBottom: 48 }}>Android installation takes less than a minute.</p>

                <div className="grid-4">
                    {steps.map(({ n, title, desc }) => (
                        <div key={n} className="glass-card" style={{ textAlign: 'center', padding: 28 }}>
                            <div style={{
                                width: 52, height: 52, borderRadius: 16, margin: '0 auto 20px',
                                background: 'linear-gradient(135deg,#10d9a0,#06b6d4)',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                fontFamily: 'Outfit', fontWeight: 900, fontSize: 22, color: '#0a1628',
                            }}>{n}</div>
                            <div style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 16, marginBottom: 10 }}>{title}</div>
                            <div style={{ fontSize: 13, color: 'var(--text2)', lineHeight: 1.7 }}>{desc}</div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Requirements + Security */}
            <div className="section" style={{ paddingTop: 0 }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(280px,1fr))', gap: 24 }}>
                    {/* Requirements */}
                    <div className="glass-card">
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
                            <Smartphone size={20} style={{ color: 'var(--accent)' }} />
                            <h3 style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 18 }}>Requirements</h3>
                        </div>
                        {requirements.map(r => (
                            <div key={r} style={{ display: 'flex', gap: 10, alignItems: 'flex-start', marginBottom: 12 }}>
                                <CheckCircle size={15} style={{ color: 'var(--accent)', flexShrink: 0, marginTop: 2 }} />
                                <span style={{ fontSize: 14, color: 'var(--text2)', lineHeight: 1.5 }}>{r}</span>
                            </div>
                        ))}
                    </div>

                    {/* Security notice */}
                    <div className="glass-card" style={{ borderColor: 'rgba(59,130,246,0.2)' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
                            <Shield size={20} style={{ color: 'var(--primary)' }} />
                            <h3 style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 18 }}>Safe & Secure</h3>
                        </div>
                        <p style={{ fontSize: 14, color: 'var(--text2)', lineHeight: 1.7, marginBottom: 16 }}>
                            R-Task is 100% safe. All data is encrypted in transit using HTTPS and stored securely in Firebase with strict Firestore security rules.
                        </p>
                        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                            {['HTTPS encrypted', 'Firebase secured', 'JWT auth', 'No ads', 'Open APK'].map(tag => (
                                <span key={tag} style={{
                                    padding: '4px 12px', borderRadius: 100,
                                    fontSize: 12, fontWeight: 600,
                                    background: 'rgba(59,130,246,0.1)', color: 'var(--primary)',
                                    border: '1px solid rgba(59,130,246,0.25)',
                                }}>{tag}</span>
                            ))}
                        </div>
                    </div>

                    {/* Performance */}
                    <div className="glass-card" style={{ borderColor: 'rgba(16,217,160,0.2)' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
                            <Zap size={20} style={{ color: 'var(--accent)' }} />
                            <h3 style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 18 }}>Performance</h3>
                        </div>
                        {[
                            ['120fps', 'Smooth animations on all screens'],
                            ['Offline-first', 'Works without internet'],
                            ['Background sync', 'Uploads run in background'],
                            ['Lazy loading', 'Handles thousands of tasks'],
                        ].map(([label, desc]) => (
                            <div key={label} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, paddingBottom: 12, borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                                <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--accent)' }}>{label}</span>
                                <span style={{ fontSize: 12, color: 'var(--text3)' }}>{desc}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* Final CTA */}
            <div className="section" style={{ paddingTop: 0 }}>
                <div style={{
                    textAlign: 'center', padding: '60px 40px',
                    background: 'linear-gradient(135deg,rgba(16,217,160,0.1),rgba(59,130,246,0.08))',
                    border: '1px solid rgba(16,217,160,0.2)',
                    borderRadius: 28,
                }}>
                    <h2 style={{ fontFamily: 'Outfit', fontWeight: 900, fontSize: 'clamp(26px,4vw,38px)', marginBottom: 16 }}>Ready to get organized?</h2>
                    <p style={{ color: 'var(--text2)', marginBottom: 32, fontSize: 16 }}>Join students and teams using R-Task to manage assignments with AI.</p>
                    <a href="/apk/rtask.apk" style={{
                        display: 'inline-flex', alignItems: 'center', gap: 10, padding: '16px 40px',
                        background: 'linear-gradient(135deg,#10d9a0,#06b6d4)', borderRadius: 14,
                        color: '#0a1628', fontFamily: 'Outfit', fontWeight: 800, fontSize: 17,
                        textDecoration: 'none',
                    }}>
                        <DownloadIcon size={20} /> Download for Android
                    </a>
                </div>
            </div>
        </div>
    );
}
