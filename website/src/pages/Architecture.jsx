const techStack = [
    { layer: 'Mobile App', tech: 'Flutter + Dart', icon: '📱', desc: '60/120 FPS native compilation for iOS & Android', color: '#06b6d4' },
    { layer: 'State Management', tech: 'Riverpod', icon: '♻️', desc: 'Scalable, leak-proof async state management', color: '#10d9a0' },
    { layer: 'Navigation', tech: 'GoRouter', icon: '🗺️', desc: 'Declarative routing with deep link support', color: '#3b82f6' },
    { layer: 'Backend API', tech: 'Node.js + Express', icon: '⚙️', desc: 'RESTful API with JWT auth, rate limiting & helmet', color: '#f97316' },
    { layer: 'Database', tech: 'Firebase Firestore', icon: '🔥', desc: 'Real-time NoSQL database for live sync', color: '#f59e0b' },
    { layer: 'Auth', tech: 'Firebase Auth', icon: '🔐', desc: 'Email/password + Google OAuth sign-in', color: '#a855f7' },
    { layer: 'Storage', tech: 'Firebase Storage', icon: '📦', desc: 'Unlimited file & PDF uploads with background isolation', color: '#ec4899' },
    { layer: 'AI Engine', tech: 'Google Gemini AI', icon: '🤖', desc: 'Assignment analysis and task breakdown via gemini-2.5-flash', color: '#10d9a0' },
    { layer: 'Push Notifications', tech: 'Firebase Messaging', icon: '🔔', desc: 'Reliable cross-platform push delivery via FCM', color: '#3b82f6' },
];

const layers = [
    {
        name: 'Presentation Layer', color: '#3b82f6', icon: '🎨',
        desc: 'Flutter Widgets, Screens, and Riverpod Providers. Only handles UI rendering and user input — zero business logic.',
        items: ['Screens & Widgets', 'Riverpod StateNotifiers', 'Animations & Micro-interactions', 'GoRouter Navigation'],
    },
    {
        name: 'Domain Layer', color: '#10d9a0', icon: '🧬',
        desc: 'Pure Dart — completely independent of Flutter or Firebase. Contains all business rules and Use Cases.',
        items: ['Entities: User, Task, Group, Assignment', 'Use Cases: SubmitTask, ApproveTask, CreateGroup', 'Repository Interfaces (abstract)', 'Failure & Result types'],
    },
    {
        name: 'Data Layer', color: '#a855f7', icon: '🗃️',
        desc: 'Bridges the Domain with Firebase and the Node.js backend API. All data fetching, caching, and serialization lives here.',
        items: ['Firestore Repository Impl', 'API Service (Node.js calls)', 'Firebase Storage uploads', 'Offline cache (SharedPreferences)'],
    },
];

const collections = [
    { name: 'users', desc: 'Profile, stats, unique ID', icon: '👤' },
    { name: 'tasks', desc: 'Personal tasks with sub-tasks & files', icon: '✅' },
    { name: 'groups', desc: 'Group metadata, members, leader', icon: '👥' },
    { name: 'group_tasks', desc: 'Task assignments + submission fields', icon: '📋' },
    { name: 'assignments', desc: 'AI-analyzed assignment containers', icon: '📄' },
    { name: 'task_comments', desc: 'Review comments per submission', icon: '💬' },
    { name: 'ai_conversations', desc: 'AI chat context for refinement', icon: '🤖' },
    { name: 'notifications', desc: 'Push notification history', icon: '🔔' },
];

export default function Architecture() {
    return (
        <div style={{ paddingTop: 'var(--nav-h)' }}>
            <div className="page-hero">
                <div className="blob" style={{ width: 500, height: 500, background: '#a855f7', top: '-80px', left: '-80px', opacity: .14 }} />
                <div className="badge badge-purple" style={{ marginBottom: 20 }}>⚙️ System Design</div>
                <h1 className="section-title">Architecture & Tech Stack</h1>
                <p className="section-sub">R-Task follows Clean Architecture principles for massive scalability and testability.</p>
            </div>

            {/* ── Clean Architecture ── */}
            <div className="section" style={{ paddingTop: 20 }}>
                <div className="section-tag"><span className="badge badge-blue">Clean Architecture</span></div>
                <h2 className="section-title" style={{ fontSize: 36, marginBottom: 12 }}>Three-Layer Design</h2>
                <p className="section-sub" style={{ marginBottom: 48 }}>Each layer has a single responsibility and depends only on the layer below it.</p>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                    {layers.map(({ name, color, icon, desc, items }, i) => (
                        <div key={name} className="glass-card" style={{ borderLeft: `3px solid ${color}` }}>
                            <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', flexWrap: 'wrap' }}>
                                <div style={{ flexShrink: 0 }}>
                                    <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color: 'var(--text3)', marginBottom: 6 }}>Layer {i + 1}</div>
                                    <div style={{ fontFamily: 'Outfit', fontWeight: 800, fontSize: 20, color, marginBottom: 4 }}>{icon} {name}</div>
                                    <p style={{ fontSize: 14, color: 'var(--text2)', lineHeight: 1.7, maxWidth: 480 }}>{desc}</p>
                                </div>
                                <div style={{ marginLeft: 'auto', display: 'flex', flexDirection: 'column', gap: 8, minWidth: 220 }}>
                                    {items.map(item => (
                                        <div key={item} style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                                            <span style={{ color, fontSize: 10 }}>▶</span>
                                            <span style={{ fontSize: 13, color: 'var(--text2)' }}>{item}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Arrow diagram */}
                <div style={{ textAlign: 'center', padding: '32px 0', fontSize: 13, color: 'var(--text3)' }}>
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 12, flexWrap: 'wrap', justifyContent: 'center' }}>
                        {['Presentation', '→ depends on →', 'Domain', '← implements ←', 'Data'].map((t, i) => (
                            <span key={i} style={{ color: i % 2 === 0 ? 'var(--text2)' : 'var(--text3)', fontWeight: i % 2 === 0 ? 600 : 400 }}>{t}</span>
                        ))}
                    </div>
                </div>
            </div>

            {/* ── Tech Stack ── */}
            <div className="section" style={{ paddingTop: 0 }}>
                <div className="section-tag"><span className="badge badge-green">Technology</span></div>
                <h2 className="section-title" style={{ fontSize: 36, marginBottom: 12 }}>Full Stack</h2>
                <p className="section-sub" style={{ marginBottom: 48 }}>Every technology chosen for performance, scalability, and developer experience.</p>

                <div className="grid-3">
                    {techStack.map(({ layer, tech, icon, desc, color }) => (
                        <div key={tech} className="glass-card" style={{ padding: 24 }}>
                            <div style={{ fontSize: 28, marginBottom: 12 }}>{icon}</div>
                            <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color: 'var(--text3)', marginBottom: 4 }}>{layer}</div>
                            <div style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 17, color, marginBottom: 8 }}>{tech}</div>
                            <div style={{ fontSize: 13, color: 'var(--text2)', lineHeight: 1.6 }}>{desc}</div>
                        </div>
                    ))}
                </div>
            </div>

            {/* ── Firestore ── */}
            <div className="section" style={{ paddingTop: 0 }}>
                <div className="section-tag"><span className="badge badge-orange">Database</span></div>
                <h2 className="section-title" style={{ fontSize: 36, marginBottom: 12 }}>Firestore Collections</h2>
                <p className="section-sub" style={{ marginBottom: 48 }}>Structured NoSQL schema optimized for real-time sync and offline-first access.</p>

                <div className="grid-4">
                    {collections.map(({ name, desc, icon }) => (
                        <div key={name} className="glass-card" style={{ padding: 20 }}>
                            <div style={{ fontSize: 24, marginBottom: 10 }}>{icon}</div>
                            <div style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 15, marginBottom: 6, color: 'var(--accent)' }}>{name}/</div>
                            <div style={{ fontSize: 13, color: 'var(--text2)', lineHeight: 1.6 }}>{desc}</div>
                        </div>
                    ))}
                </div>

                {/* Code sample */}
                <div style={{ marginTop: 40 }}>
                    <div style={{ fontSize: 13, color: 'var(--text3)', marginBottom: 12, fontWeight: 600 }}>Sample: group_tasks document</div>
                    <div className="code-block">{`{
  <span class="kw">id</span>: <span class="str">"task_xyz123"</span>,
  <span class="kw">title</span>: <span class="str">"Design UI/UX Mockups"</span>,
  <span class="kw">assignedTo</span>: <span class="str">"user_alice"</span>,
  <span class="kw">groupId</span>: <span class="str">"group_abc"</span>,
  <span class="kw">assignmentId</span>: <span class="str">"assignment_001"</span>,   <span class="cm">// AI assignment link</span>
  <span class="kw">status</span>: <span class="str">"pendingApproval"</span>,
  <span class="kw">priority</span>: <span class="str">"high"</span>,
  <span class="kw">submissionUrl</span>: <span class="str">"https://storage.googleapis.com/..."</span>,
  <span class="kw">submittedAt</span>: <span class="str">"2026-03-14T10:30:00Z"</span>,
  <span class="kw">estimatedHours</span>: 4
}`}</div>
                </div>
            </div>
        </div>
    );
}
