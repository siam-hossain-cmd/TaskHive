const phases = [
    {
        phase: 'Phase 1', title: 'Task Creation & AI Analysis', color: '#3b82f6', emoji: '📤',
        steps: [
            { step: '1', label: 'Choose Mode', desc: 'User selects Individual or Group task creation' },
            { step: '2', label: 'Upload Assignment', desc: 'Upload PDF/DOC/DOCX file — plus optional title, subject, due date' },
            { step: '3', label: 'AI Analyzes', desc: 'PDF text extracted → sent to Gemini AI → returns structured sub-task breakdown' },
            { step: '4', label: 'Refine with AI Chat', desc: 'Leader types commands: "Split task 2", "Add a testing task" → AI re-generates live' },
        ],
        diagram: `User uploads PDF
        │
        ▼
  Backend extracts text
        │
        ▼
  Gemini AI analyzes
        │
        ▼
  Returns: { title, subject, 
    summary, subtasks[] }
        │
        ▼
  Leader edits via AI Chat
        │
        ▼
  Confirms final task list ✓`,
    },
    {
        phase: 'Phase 2', title: 'Team Assignment & Distribution', color: '#10d9a0', emoji: '👥',
        steps: [
            { step: '1', label: 'AI Suggests Distribution', desc: 'AI maps sub-tasks to team members based on equal effort distribution' },
            { step: '2', label: 'Leader Reviews Board', desc: 'Visual assignment board: Member 1 → Task A, Member 2 → Task B, C...' },
            { step: '3', label: 'Reassign as Needed', desc: 'Leader can drag or tap to reassign any task to any member' },
            { step: '4', label: 'Confirm & Notify', desc: 'All members receive push notifications with their assigned sub-tasks' },
        ],
        diagram: `Sub-tasks ready
        │
        ┌───────────────────┐
        │  AI Suggests:     │
        │  Alice → Task A,B │
        │  Bob   → Task C   │
        │  Carol → Task D,E │
        └───────────────────┘
        │
        ▼
  Leader adjusts if needed
        │
        ▼
  "Assign All" → N tasks created
        │
        ▼
  Push notifications sent ✓`,
    },
    {
        phase: 'Phase 3', title: 'Submission & Review', color: '#a855f7', emoji: '📝',
        steps: [
            { step: '1', label: 'Member Submits Work', desc: 'Each member uploads their completed doc/file — status changes to Submitted' },
            { step: '2', label: 'Team Notified', desc: 'All other members receive: "Alice uploaded Part 2"' },
            { step: '3', label: 'Comment & Review', desc: 'Leader and members can comment: "Fix section 3" — a mini chat per task' },
            { step: '4', label: 'Request Changes', desc: 'Leader requests changes with feedback → member re-submits' },
        ],
        diagram: `Member uploads file
        │
        ▼
  Status: "Submitted"
        │
        ▼
  All members notified 🔔
        │
        ▼
  Leader reviews submission
        │
   ┌────┴─────────┐
   │              │
Approve ✅   Request Changes 🔄
   │              │
   ▼              ▼
Sub-task DONE  Member re-submits`,
    },
    {
        phase: 'Phase 4', title: 'Final Compilation & Completion', color: '#f97316', emoji: '🎉',
        steps: [
            { step: '1', label: 'All Sub-Tasks Approved', desc: 'Once every member\'s submission is approved, compilation phase begins' },
            { step: '2', label: 'Compile the Report', desc: 'Leader compiles themselves OR assigns a "Compiler" team member' },
            { step: '3', label: 'Upload Final Doc', desc: 'Final compiled document uploaded to the assignment' },
            { step: '4', label: 'Mark Complete', desc: 'Leader marks assignment as Completed — all members notified with 🎉' },
        ],
        diagram: `All sub-tasks approved ✅
        │
   ┌────┴──────────────┐
   │                   │
Leader compiles   Assign Compiler
   │               member
   │                   │
   └────────┬──────────┘
            │
            ▼
   Upload final document
            │
            ▼
  Mark Assignment Complete ✅
            │
            ▼
  All members notified 🎉`,
    },
];

const apis = [
    { method: 'POST', path: '/api/ai/analyze', desc: 'PDF → AI analysis → task breakdown', color: '#10d9a0' },
    { method: 'POST', path: '/api/ai/refine', desc: 'AI chat refinement of task list', color: '#3b82f6' },
    { method: 'POST', path: '/api/tasks/submit', desc: 'Member submits completed work file', color: '#a855f7' },
    { method: 'POST', path: '/api/tasks/:id/comment', desc: 'Add comment to a submission', color: '#f97316' },
    { method: 'POST', path: '/api/tasks/:id/approve', desc: 'Leader approves sub-task', color: '#10d9a0' },
    { method: 'POST', path: '/api/tasks/:id/request-changes', desc: 'Leader requests changes with feedback', color: '#f59e0b' },
    { method: 'POST', path: '/api/assignments/:id/compile', desc: 'Assign compiler or upload final doc', color: '#ec4899' },
    { method: 'POST', path: '/api/assignments/:id/complete', desc: 'Mark full assignment as done', color: '#3b82f6' },
];

export default function Flow() {
    return (
        <div style={{ paddingTop: 'var(--nav-h)' }}>
            <div className="page-hero">
                <div className="blob" style={{ width: 500, height: 500, background: '#10d9a0', top: '-80px', right: '-80px', opacity: .13 }} />
                <div className="badge badge-green" style={{ marginBottom: 20 }}>🔄 Algorithm & Flow</div>
                <h1 className="section-title">System Flow & Algorithm</h1>
                <p className="section-sub">The complete 4-phase lifecycle of an AI-powered assignment from upload to final completion.</p>
            </div>

            {/* Phases */}
            <div className="section" style={{ paddingTop: 20 }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 64 }}>
                    {phases.map(({ phase, title, color, emoji, steps, diagram }) => (
                        <div key={phase}>
                            {/* Phase header */}
                            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 32 }}>
                                <div style={{ fontSize: 36 }}>{emoji}</div>
                                <div>
                                    <div style={{ fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color: 'var(--text3)', marginBottom: 4 }}>{phase}</div>
                                    <h3 style={{ fontFamily: 'Outfit', fontWeight: 800, fontSize: 28, color }}>{title}</h3>
                                </div>
                            </div>

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
                                {/* Steps */}
                                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                                    {steps.map(({ step, label, desc }) => (
                                        <div key={step} className="step-card">
                                            <div className="step-num" style={{ background: `${color}18`, color }}>{step}</div>
                                            <div>
                                                <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 4 }}>{label}</div>
                                                <div style={{ fontSize: 13, color: 'var(--text2)', lineHeight: 1.6 }}>{desc}</div>
                                            </div>
                                        </div>
                                    ))}
                                </div>

                                {/* Diagram */}
                                <div style={{
                                    background: '#0a0f1a', border: `1px solid ${color}30`,
                                    borderRadius: 16, padding: 24,
                                    fontFamily: 'Courier New, monospace', fontSize: 13,
                                    color: '#94a3b8', lineHeight: 1.8, whiteSpace: 'pre',
                                }}>
                                    <div style={{ fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, color, marginBottom: 16 }}>Flow Diagram</div>
                                    {diagram}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* API Endpoints */}
            <div className="section" style={{ paddingTop: 0 }}>
                <div className="section-tag"><span className="badge badge-blue">Backend</span></div>
                <h2 className="section-title" style={{ fontSize: 36, marginBottom: 12 }}>API Endpoints</h2>
                <p className="section-sub" style={{ marginBottom: 48 }}>8 REST endpoints power the entire AI assignment workflow.</p>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {apis.map(({ method, path, desc, color }) => (
                        <div key={path} style={{
                            display: 'flex', gap: 16, alignItems: 'center',
                            padding: '16px 24px',
                            background: 'var(--card)', border: '1px solid var(--card-border)',
                            borderRadius: 14,
                            flexWrap: 'wrap',
                        }}>
                            <span style={{
                                padding: '4px 12px', borderRadius: 8,
                                fontSize: 12, fontWeight: 700,
                                background: `${color}20`, color, border: `1px solid ${color}40`,
                                flexShrink: 0,
                            }}>{method}</span>
                            <code style={{ color: '#e2e8f0', fontSize: 14, fontFamily: 'Courier New', flex: 1, minWidth: 200 }}>{path}</code>
                            <span style={{ fontSize: 13, color: 'var(--text2)' }}>{desc}</span>
                        </div>
                    ))}
                </div>
            </div>

            {/* Notification Matrix */}
            <div className="section" style={{ paddingTop: 0 }}>
                <div className="section-tag"><span className="badge badge-orange">Notifications</span></div>
                <h2 className="section-title" style={{ fontSize: 36, marginBottom: 12 }}>Notification Algorithm</h2>
                <p className="section-sub" style={{ marginBottom: 48 }}>Every action triggers the right push notification to the right people.</p>

                <div style={{ overflowX: 'auto' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 14 }}>
                        <thead>
                            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
                                {['Event', 'Recipients', 'Message'].map(h => (
                                    <th key={h} style={{ textAlign: 'left', padding: '12px 16px', color: 'var(--text3)', fontWeight: 600, fontSize: 12, textTransform: 'uppercase', letterSpacing: 0.5 }}>{h}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                ['Task assigned', 'Assigned member', '"You\'ve been assigned: {task title}"'],
                                ['Member submits work', 'All other group members', '"{name} uploaded their part: {task}"'],
                                ['Comment added', 'Task assignee', '"{name} commented on your task"'],
                                ['Changes requested', 'Task assignee', '"Leader requested changes: {feedback}"'],
                                ['Task approved', 'Task assignee', '"Your task \'{title}\' has been approved! ✅"'],
                                ['Compiler assigned', 'Compiler member', '"You\'ve been assigned to compile"'],
                                ['Assignment completed', 'All group members', '"Assignment \'{title}\' is complete! 🎉"'],
                            ].map(([event, who, msg], i) => (
                                <tr key={i} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                                    <td style={{ padding: '14px 16px', color: 'var(--text)', fontWeight: 500 }}>{event}</td>
                                    <td style={{ padding: '14px 16px', color: 'var(--accent)', fontSize: 13 }}>{who}</td>
                                    <td style={{ padding: '14px 16px', color: 'var(--text2)', fontFamily: 'monospace', fontSize: 12 }}>{msg}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
