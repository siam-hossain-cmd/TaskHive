import { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { Menu, X, Download } from 'lucide-react';

const links = [
    { to: '/', label: 'Home' },
    { to: '/features', label: 'Features' },
    { to: '/architecture', label: 'Architecture' },
    { to: '/flow', label: 'System Flow' },
    { to: '/download', label: 'Download' },
];

export default function Navbar() {
    const [open, setOpen] = useState(false);
    const [scrolled, setScrolled] = useState(false);
    const location = useLocation();

    useEffect(() => {
        const fn = () => setScrolled(window.scrollY > 20);
        window.addEventListener('scroll', fn);
        return () => window.removeEventListener('scroll', fn);
    }, []);

    useEffect(() => setOpen(false), [location]);

    return (
        <nav style={{
            position: 'fixed', top: 0, left: 0, right: 0, zIndex: 1000,
            height: 'var(--nav-h)',
            display: 'flex', alignItems: 'center',
            padding: '0 24px',
            background: scrolled ? 'rgba(7,11,20,0.92)' : 'transparent',
            backdropFilter: scrolled ? 'blur(20px)' : 'none',
            borderBottom: scrolled ? '1px solid rgba(255,255,255,0.06)' : 'none',
            transition: 'all 0.3s',
        }}>
            {/* Logo */}
            <NavLink to="/" style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 1 }}>
                <img src="/logo.png" alt="R-Task" style={{ width: 38, height: 38, objectFit: 'contain', borderRadius: 10 }} />
                <span style={{ fontFamily: 'Outfit', fontWeight: 800, fontSize: 22, background: 'linear-gradient(135deg,#fff,#94a3b8)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                    R-Task
                </span>
            </NavLink>

            {/* Desktop links */}
            <div style={{ display: 'flex', gap: 6, alignItems: 'center' }} className="desktop-nav">
                {links.map(({ to, label }) => (
                    <NavLink key={to} to={to} end={to === '/'}
                        style={({ isActive }) => ({
                            padding: '8px 16px',
                            borderRadius: 10,
                            fontSize: 14,
                            fontWeight: 500,
                            color: isActive ? '#fff' : 'var(--text2)',
                            background: isActive ? 'rgba(255,255,255,0.08)' : 'transparent',
                            transition: 'all 0.2s',
                        })}>
                        {label}
                    </NavLink>
                ))}
                <a href="/download" className="btn btn-accent" style={{ padding: '9px 20px', fontSize: 13, marginLeft: 8 }}>
                    <Download size={15} /> Get App
                </a>
            </div>

            {/* Mobile hamburger */}
            <button onClick={() => setOpen(!open)} style={{ background: 'none', border: 'none', color: 'var(--text)', cursor: 'pointer', display: 'none' }} className="hamburger">
                {open ? <X size={24} /> : <Menu size={24} />}
            </button>

            {/* Mobile menu */}
            {open && (
                <div style={{
                    position: 'fixed', top: 'var(--nav-h)', left: 0, right: 0,
                    background: 'rgba(7,11,20,0.98)', backdropFilter: 'blur(20px)',
                    padding: '20px 24px 32px',
                    borderBottom: '1px solid rgba(255,255,255,0.08)',
                    display: 'flex', flexDirection: 'column', gap: 4,
                }}>
                    {links.map(({ to, label }) => (
                        <NavLink key={to} to={to} end={to === '/'}
                            style={({ isActive }) => ({
                                padding: '12px 16px',
                                borderRadius: 12,
                                fontSize: 15,
                                fontWeight: 500,
                                color: isActive ? '#fff' : 'var(--text2)',
                                background: isActive ? 'rgba(255,255,255,0.08)' : 'transparent',
                            })}>
                            {label}
                        </NavLink>
                    ))}
                    <a href="/download" className="btn btn-accent" style={{ marginTop: 12, justifyContent: 'center' }}>
                        <Download size={16} /> Download App
                    </a>
                </div>
            )}

            <style>{`
        @media (max-width: 768px) {
          .desktop-nav { display: none !important; }
          .hamburger { display: block !important; }
        }
      `}</style>
        </nav>
    );
}
