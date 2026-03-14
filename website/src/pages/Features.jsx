import { Zap } from 'lucide-react';

const features = [
    {
        emoji: '📋', title: 'Personal Task Management', color: '#3b82f6', badge: 'Productivity',
        items: ['Rich task creation with title, description, subject, priority & due date', 'Smart 24-hour warning reminders with progress mini-report', 'Custom notification times (you decide when to be reminded)', 'Unlimited file/PDF uploads attached to tasks', 'Weekly performance analytics with beautiful charts'],
    },
    {
        emoji: '👥', title: 'Group Collaboration', color: '#10d9a0', badge: 'Teamwork',
        items: ['Connect via Unique User ID — no phone number needed', 'Democratic mode (equal rights) or Leader-led mode', 'Approval pipeline — members submit, leader reviews & approves', 'Real-time group progress tracking with completion percentages', 'Individual contribution visibility for every member'],
    },
    {
        emoji: '🤖', title: 'AI Assignment Analyzer', color: '#a855f7', badge: 'AI-Powered',
        items: ['Upload PDF/DOC/DOCX assignment sheet', 'Gemini AI extracts tasks, priorities, deadlines, and sub-tasks', 'AI Chat: type "Split task 2" and AI instantly updates the breakdown', 'AI suggests fair task distribution across team members', 'Leader can reassign any sub-task with drag & drop'],
    },
    {
        emoji: '📤', title: 'Submission & Review System', color: '#f97316', badge: 'Workflow',
        items: ['Members upload completed work files as submissions', 'All team members get notified instantly on new submissions', 'Comment thread per submission — like a mini review chat', 'Leader approves or requests changes with written feedback', 'Progress bar tracks how many sub-tasks are approved'],
    },
    {
        emoji: '🔔', title: 'Smart Notifications', color: '#06b6d4', badge: 'Reminders',
        items: ['Auto 24-hour warning before any deadline', 'Task assigned, submitted, approved — all push notifications', 'Custom reminder scheduling per task', 'Group-wide alerts when a member uploads or submits', 'Firebase Cloud Messaging for reliable delivery'],
    },
    {
        emoji: '🌐', title: 'Offline-First & Performance', color: '#f59e0b', badge: 'Performance',
        items: ['Optimistic UI — tasks update instantly, sync in background', 'Works fully offline on subway, flights, anywhere', '60/120 FPS smooth Flutter animations on every device', 'Background isolate uploads — large PDFs don\'t freeze UI', 'Lazy loading for task lists of any size'],
    },
];

export default function Features() {
    return (
        <div style={{ paddingTop: 'var(--nav-h)' }}>
            <div className="page-hero">
                <div className="blob" style={{ width: 500, height: 500, background: '#3b82f6', top: '-100px', right: '-100px', opacity: .15 }} />
                <div className="badge badge-blue" style={{ marginBottom: 20 }}><Zap size={12} /> Feature Set</div>
                <h1 className="section-title" style={{ marginBottom: 16 }}>Everything you need</h1>
                <p className="section-sub" style={{ marginBottom: 0 }}>
                    R-Task is designed to cover personal productivity and team workflows in one coherent, beautiful experience.
                </p>
            </div>

            <div className="section" style={{ paddingTop: 40 }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(320px,1fr))', gap: 28 }}>
                    {features.map(({ emoji, title, color, badge, items }) => (
                        <div key={title} className="glass-card" style={{ padding: 32 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 20 }}>
                                <div style={{ fontSize: 36 }}>{emoji}</div>
                                <div>
                                    <div style={{ fontFamily: 'Outfit', fontWeight: 700, fontSize: 18, marginBottom: 4 }}>{title}</div>
                                    <span style={{
                                        display: 'inline-block', padding: '3px 10px', borderRadius: 100,
                                        fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5,
                                        background: `${color}18`, color, border: `1px solid ${color}40`,
                                    }}>{badge}</span>
                                </div>
                            </div>
                            <div style={{ borderTop: '1px solid rgba(255,255,255,0.06)', paddingTop: 20, display: 'flex', flexDirection: 'column', gap: 10 }}>
                                {items.map(item => (
                                    <div key={item} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                                        <span style={{ color, flexShrink: 0, marginTop: 2 }}>✓</span>
                                        <span style={{ fontSize: 14, color: 'var(--text2)', lineHeight: 1.6 }}>{item}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}
