import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Settings, Zap, Shield, AlertTriangle, CheckCircle, RefreshCw, Eye, EyeOff } from 'lucide-react';
import { getAISettings, updateAISettings, testAIConnection } from '../services/api';

const providers = [
    { value: 'gemini', label: 'Google Gemini', models: ['gemini-2.5-flash', 'gemini-2.5-pro', 'gemini-2.0-flash', 'gemini-1.5-pro'] },
    { value: 'openai', label: 'OpenAI', models: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'] },
    { value: 'claude', label: 'Anthropic Claude', models: ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'] },
];

export default function AISettings() {
    const [settings, setSettings] = useState(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [testing, setTesting] = useState(false);
    const [testResult, setTestResult] = useState(null);
    const [showApiKey, setShowApiKey] = useState(false);
    const [newApiKey, setNewApiKey] = useState('');
    const [toast, setToast] = useState(null);

    useEffect(() => {
        loadSettings();
    }, []);

    const loadSettings = async () => {
        try {
            const res = await getAISettings();
            setSettings(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const showToast = (msg, type = 'success') => {
        setToast({ msg, type });
        setTimeout(() => setToast(null), 3000);
    };

    const handleSave = async () => {
        setSaving(true);
        try {
            const payload = { ...settings };
            if (newApiKey) payload.apiKey = newApiKey;
            delete payload.apiKeyMasked;
            await updateAISettings(payload);
            showToast('Settings saved successfully');
            setNewApiKey('');
            loadSettings();
        } catch (err) {
            showToast(err.response?.data?.error || 'Failed to save', 'error');
        } finally {
            setSaving(false);
        }
    };

    const handleTest = async () => {
        setTesting(true);
        setTestResult(null);
        try {
            const res = await testAIConnection();
            setTestResult({ success: true, message: res.data.message, model: res.data.model });
        } catch (err) {
            setTestResult({ success: false, message: err.response?.data?.error || 'Connection failed' });
        } finally {
            setTesting(false);
        }
    };

    const updateField = (field, value) => {
        setSettings(prev => ({ ...prev, [field]: value }));
    };

    const updateRateLimit = (field, value) => {
        setSettings(prev => ({
            ...prev,
            rateLimits: { ...prev.rateLimits, [field]: parseInt(value) || 0 },
        }));
    };

    const updateAlert = (field, value) => {
        setSettings(prev => ({
            ...prev,
            alertThreshold: { ...prev.alertThreshold, [field]: parseFloat(value) || 0 },
        }));
    };

    if (loading) return <div className="spinner mt-6" style={{ margin: 'auto' }} />;

    const currentProvider = providers.find(p => p.value === settings?.provider) || providers[0];

    return (
        <div>
            <div className="page-header">
                <div>
                    <h1 className="page-title">AI Settings</h1>
                    <p className="page-subtitle">Configure AI provider, model parameters, rate limits, and access controls.</p>
                </div>
                <div className="flex gap-2">
                    <button className="btn btn-ghost" onClick={handleTest} disabled={testing}>
                        {testing ? <RefreshCw size={14} className="spin-icon" /> : <Zap size={14} />}
                        {testing ? 'Testing...' : 'Test Connection'}
                    </button>
                    <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
                        {saving ? 'Saving...' : 'Save Settings'}
                    </button>
                </div>
            </div>

            {/* Toast */}
            {toast && (
                <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0 }}
                    style={{
                        position: 'fixed', top: 80, right: 28, zIndex: 200,
                        background: toast.type === 'error' ? 'var(--danger-200)' : 'var(--success-200)',
                        color: toast.type === 'error' ? 'var(--danger)' : 'var(--success)',
                        border: `1px solid ${toast.type === 'error' ? 'var(--danger)' : 'var(--success)'}`,
                        padding: '12px 20px', borderRadius: 'var(--radius)', fontWeight: 600, fontSize: 13,
                        display: 'flex', alignItems: 'center', gap: 8,
                    }}
                >
                    {toast.type === 'error' ? <AlertTriangle size={14} /> : <CheckCircle size={14} />}
                    {toast.msg}
                </motion.div>
            )}

            {/* Test Result */}
            {testResult && (
                <motion.div
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="card"
                    style={{
                        marginBottom: 20,
                        borderColor: testResult.success ? 'var(--success)' : 'var(--danger)',
                        background: testResult.success ? 'var(--success-200)' : 'var(--danger-200)',
                    }}
                >
                    <div className="flex items-center gap-3">
                        {testResult.success
                            ? <CheckCircle size={20} color="var(--success)" />
                            : <AlertTriangle size={20} color="var(--danger)" />
                        }
                        <div>
                            <div style={{ fontWeight: 700, fontSize: 14, color: testResult.success ? 'var(--success)' : 'var(--danger)' }}>
                                {testResult.success ? 'Connection Successful' : 'Connection Failed'}
                            </div>
                            <div style={{ fontSize: 12.5, color: 'var(--text-2)', marginTop: 2 }}>
                                {testResult.message} {testResult.model && `• Model: ${testResult.model}`}
                            </div>
                        </div>
                    </div>
                </motion.div>
            )}

            <div className="grid-2" style={{ alignItems: 'flex-start' }}>
                {/* Left Column - Provider & Model */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>

                    {/* Global Toggle */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="card">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="stat-icon" style={{ background: settings?.enabled ? 'var(--success-200)' : 'var(--danger-200)' }}>
                                    {settings?.enabled
                                        ? <Zap size={18} color="var(--success)" />
                                        : <AlertTriangle size={18} color="var(--danger)" />
                                    }
                                </div>
                                <div>
                                    <div style={{ fontWeight: 700, fontSize: 14 }}>AI Features</div>
                                    <div style={{ fontSize: 12, color: 'var(--text-3)' }}>
                                        {settings?.enabled ? 'AI is active for all users' : 'AI is disabled globally'}
                                    </div>
                                </div>
                            </div>
                            <label className="toggle-switch">
                                <input
                                    type="checkbox"
                                    checked={settings?.enabled ?? true}
                                    onChange={e => updateField('enabled', e.target.checked)}
                                />
                                <span className="toggle-slider" />
                            </label>
                        </div>
                    </motion.div>

                    {/* Provider Selection */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="card">
                        <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 16 }}>
                            <Settings size={16} style={{ display: 'inline', marginRight: 8, verticalAlign: -2 }} />
                            Provider & Model
                        </h3>

                        <div className="input-group" style={{ marginBottom: 14 }}>
                            <label className="label">AI Provider</label>
                            <select
                                className="input"
                                value={settings?.provider || 'gemini'}
                                onChange={e => {
                                    updateField('provider', e.target.value);
                                    const prov = providers.find(p => p.value === e.target.value);
                                    if (prov) updateField('model', prov.models[0]);
                                }}
                            >
                                {providers.map(p => (
                                    <option key={p.value} value={p.value}>{p.label}</option>
                                ))}
                            </select>
                        </div>

                        <div className="input-group" style={{ marginBottom: 14 }}>
                            <label className="label">Model</label>
                            <select
                                className="input"
                                value={settings?.model || ''}
                                onChange={e => updateField('model', e.target.value)}
                            >
                                {currentProvider.models.map(m => (
                                    <option key={m} value={m}>{m}</option>
                                ))}
                            </select>
                        </div>

                        <div className="input-group">
                            <label className="label">API Key</label>
                            <div style={{ position: 'relative' }}>
                                <input
                                    type={showApiKey ? 'text' : 'password'}
                                    className="input"
                                    placeholder={settings?.apiKeyMasked || 'Enter API key...'}
                                    value={newApiKey}
                                    onChange={e => setNewApiKey(e.target.value)}
                                    style={{ paddingRight: 40 }}
                                />
                                <button
                                    onClick={() => setShowApiKey(!showApiKey)}
                                    style={{
                                        position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)',
                                        background: 'none', border: 'none', color: 'var(--text-3)', cursor: 'pointer',
                                    }}
                                >
                                    {showApiKey ? <EyeOff size={16} /> : <Eye size={16} />}
                                </button>
                            </div>
                            <span style={{ fontSize: 11, color: 'var(--text-3)' }}>
                                {settings?.apiKeyMasked ? `Current: ${settings.apiKeyMasked}` : 'Uses GEMINI_API_KEY env variable if empty'}
                            </span>
                        </div>
                    </motion.div>

                    {/* Model Parameters */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }} className="card">
                        <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 16 }}>Model Parameters</h3>

                        <div className="input-group" style={{ marginBottom: 14 }}>
                            <label className="label">Temperature: {settings?.temperature ?? 0.3}</label>
                            <input
                                type="range"
                                min="0"
                                max="1"
                                step="0.1"
                                value={settings?.temperature ?? 0.3}
                                onChange={e => updateField('temperature', parseFloat(e.target.value))}
                                style={{ width: '100%', accentColor: 'var(--primary)' }}
                            />
                            <div className="flex justify-between" style={{ fontSize: 11, color: 'var(--text-3)' }}>
                                <span>Precise (0)</span>
                                <span>Creative (1)</span>
                            </div>
                        </div>

                        <div className="input-group">
                            <label className="label">Max Tokens</label>
                            <input
                                type="number"
                                className="input"
                                value={settings?.maxTokens ?? 8192}
                                onChange={e => updateField('maxTokens', parseInt(e.target.value))}
                                min={256}
                                max={128000}
                            />
                        </div>
                    </motion.div>

                    {/* System Prompt */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="card">
                        <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 16 }}>System Prompt</h3>
                        <div className="input-group">
                            <textarea
                                className="input textarea"
                                style={{ minHeight: 180, fontFamily: 'monospace', fontSize: 12.5 }}
                                value={settings?.systemPrompt || ''}
                                onChange={e => updateField('systemPrompt', e.target.value)}
                            />
                            <span style={{ fontSize: 11, color: 'var(--text-3)' }}>
                                This prompt guides the AI's behavior when analyzing assignments.
                            </span>
                        </div>
                    </motion.div>
                </div>

                {/* Right Column - Rate Limits & Controls */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>

                    {/* Rate Limits */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.15 }} className="card">
                        <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 16 }}>
                            <Shield size={16} style={{ display: 'inline', marginRight: 8, verticalAlign: -2 }} />
                            Rate Limits (per user)
                        </h3>

                        <div className="input-group" style={{ marginBottom: 14 }}>
                            <label className="label">Max Requests / Hour</label>
                            <input
                                type="number"
                                className="input"
                                value={settings?.rateLimits?.maxRequestsPerHour ?? 20}
                                onChange={e => updateRateLimit('maxRequestsPerHour', e.target.value)}
                                min={1}
                            />
                        </div>

                        <div className="input-group" style={{ marginBottom: 14 }}>
                            <label className="label">Max Requests / Day</label>
                            <input
                                type="number"
                                className="input"
                                value={settings?.rateLimits?.maxRequestsPerDay ?? 100}
                                onChange={e => updateRateLimit('maxRequestsPerDay', e.target.value)}
                                min={1}
                            />
                        </div>

                        <div className="input-group">
                            <label className="label">Max Tokens / Day</label>
                            <input
                                type="number"
                                className="input"
                                value={settings?.rateLimits?.maxTokensPerDay ?? 500000}
                                onChange={e => updateRateLimit('maxTokensPerDay', e.target.value)}
                                min={1000}
                                step={10000}
                            />
                        </div>
                    </motion.div>

                    {/* Content Filtering */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.25 }} className="card">
                        <div className="flex items-center justify-between">
                            <div>
                                <div style={{ fontWeight: 700, fontSize: 14 }}>Content Safety Filtering</div>
                                <div style={{ fontSize: 12, color: 'var(--text-3)', marginTop: 4 }}>
                                    Block harmful or inappropriate AI responses
                                </div>
                            </div>
                            <label className="toggle-switch">
                                <input
                                    type="checkbox"
                                    checked={settings?.contentFiltering ?? true}
                                    onChange={e => updateField('contentFiltering', e.target.checked)}
                                />
                                <span className="toggle-slider" />
                            </label>
                        </div>
                    </motion.div>

                    {/* Alert Thresholds */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.35 }} className="card">
                        <h3 style={{ fontWeight: 700, fontSize: 15, marginBottom: 16 }}>
                            <AlertTriangle size={16} style={{ display: 'inline', marginRight: 8, verticalAlign: -2 }} />
                            Alert Thresholds
                        </h3>

                        <div className="input-group" style={{ marginBottom: 14 }}>
                            <label className="label">Daily Cost Alert (USD)</label>
                            <input
                                type="number"
                                className="input"
                                value={settings?.alertThreshold?.dailyCostUsd ?? 10}
                                onChange={e => updateAlert('dailyCostUsd', e.target.value)}
                                min={0}
                                step={1}
                            />
                            <span style={{ fontSize: 11, color: 'var(--text-3)' }}>
                                Alert when daily AI cost exceeds this amount
                            </span>
                        </div>

                        <div className="input-group">
                            <label className="label">Daily Request Alert</label>
                            <input
                                type="number"
                                className="input"
                                value={settings?.alertThreshold?.dailyRequests ?? 500}
                                onChange={e => updateAlert('dailyRequests', e.target.value)}
                                min={1}
                            />
                            <span style={{ fontSize: 11, color: 'var(--text-3)' }}>
                                Alert when total daily requests exceed this count
                            </span>
                        </div>
                    </motion.div>

                    {/* Quick Info */}
                    <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4 }} className="card" style={{ background: 'var(--primary-200)', borderColor: 'var(--primary)' }}>
                        <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--primary)', marginBottom: 8 }}>
                            ℹ️ How AI is used
                        </div>
                        <ul style={{ fontSize: 12.5, color: 'var(--text-2)', lineHeight: 1.7, paddingLeft: 16 }}>
                            <li><strong>Analyze</strong> — Extracts PDF text and breaks assignments into subtasks</li>
                            <li><strong>Refine</strong> — Users can chat to modify the AI-generated breakdown</li>
                            <li>Rate limits are enforced per user before each AI call</li>
                            <li>All usage is logged for monitoring in the AI Usage page</li>
                        </ul>
                    </motion.div>
                </div>
            </div>
        </div>
    );
}
