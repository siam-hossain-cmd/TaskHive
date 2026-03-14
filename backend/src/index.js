require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const adminRoutes = require('./routes/admin');
const userRoutes = require('./routes/users');
const groupRoutes = require('./routes/groups');
const notificationRoutes = require('./routes/notifications');
const taskRoutes = require('./routes/tasks');
const healthRoutes = require('./routes/health');
const auditRoutes = require('./routes/audit');
const aiRoutes = require('./routes/ai');
const aiAdminRoutes = require('./routes/ai-admin');
const assignmentRoutes = require('./routes/assignments');
const reminderRoutes = require('./routes/reminders');

const app = express();
const PORT = process.env.PORT || 3001;

// ─── Security Middleware ────────────────────────────────────────────────────────
app.use(helmet());

const productionOrigins = [process.env.ADMIN_PANEL_URL || 'https://admin.taskhive.com'];
app.use(cors({
    origin: process.env.NODE_ENV === 'production' ? productionOrigins : ['http://localhost:5173', 'http://localhost:3000', '*'],
    credentials: true,
}));

// ─── Rate Limiting ────────────────────────────────────────────────────────────
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    message: { error: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// ─── Request Logging ──────────────────────────────────────────────────────────
app.use(morgan('dev'));

// ─── Body Parsing ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/audit', auditRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/ai-admin', aiAdminRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/reminders', reminderRoutes);

// ─── Root ─────────────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
    res.json({
        name: 'TaskHive Backend API',
        version: '1.0.0',
        status: 'running',
        docs: 'See /api/health for system status',
    });
});

// ─── 404 Handler ─────────────────────────────────────────────────────────────
app.use((req, res) => {
    res.status(404).json({ error: `Route ${req.method} ${req.path} not found` });
});

// ─── Error Handler ────────────────────────────────────────────────────────────
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ 
        error: 'Internal server error', 
        message: process.env.NODE_ENV === 'production' ? 'An unexpected error occurred.' : err.message 
    });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`\n🚀 TaskHive Backend running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🔐 Admin login: POST http://localhost:${PORT}/api/admin/login\n`);
});

module.exports = app;
