import axios from 'axios';

const BASE = '/api';

const api = axios.create({ baseURL: BASE });

// Attach JWT to every request
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('admin_token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
});

// If 401/403, clear token and redirect to login
api.interceptors.response.use(
    (r) => r,
    (err) => {
        if (err.response?.status === 401 || err.response?.status === 403) {
            localStorage.removeItem('admin_token');
            window.location.href = '/login';
        }
        return Promise.reject(err);
    }
);

export const login = (email, password) => api.post('/admin/login', { email, password });
export const getMe = () => api.get('/admin/me');

export const getUsers = () => api.get('/users');
export const getUser = (uid) => api.get(`/users/${uid}`);
export const getUserStats = () => api.get('/users/stats/summary');
export const banUser = (uid, ban) => api.patch(`/users/${uid}/ban`, { ban });
export const deleteUser = (uid) => api.delete(`/users/${uid}`);

export const getGroups = () => api.get('/groups');
export const getGroupMembers = (id) => api.get(`/groups/${id}/members`);
export const deleteGroup = (id) => api.delete(`/groups/${id}`);

export const sendNotification = (data) => api.post('/notifications/send', data);
export const getNotificationHistory = () => api.get('/notifications/history');

export const getTasks = () => api.get('/tasks');
export const deleteTask = (id) => api.delete(`/tasks/${id}`);

export const getHealth = () => api.get('/health');
export const getAuditLogs = () => api.get('/audit');

// ── AI Admin ──────────────────────────────────────────
export const getAISettings = () => api.get('/ai-admin/settings');
export const updateAISettings = (data) => api.put('/ai-admin/settings', data);
export const testAIConnection = () => api.post('/ai-admin/settings/test');
export const getAIUsage = (period = '7d') => api.get(`/ai-admin/usage?period=${period}`);
export const getAIUserUsage = (uid) => api.get(`/ai-admin/usage/${uid}`);
export const updateAIAccess = (uid, data) => api.patch(`/ai-admin/access/${uid}`, data);
export const getAIConversations = () => api.get('/ai-admin/conversations');
