import { useState, useEffect } from 'react';
import { apiGet } from '../api';

const Dashboard = () => {
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [lastUpdated, setLastUpdated] = useState(null);

    const fetchStats = async () => {
        try {
            const data = await apiGet('/appointments/dashboard');
            setStats(data);
            setError(null);
            setLastUpdated(new Date());
        } catch (err) {
            console.error('Dashboard yüklenemedi:', err);
            setError(err.message || 'Veriler yüklenemedi');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStats();
        const interval = setInterval(fetchStats, 30000);
        return () => clearInterval(interval);
    }, []);

    if (loading) return <div className="loading"><div className="spinner"></div><p>Yükleniyor...</p></div>;
    if (error || !stats) {
        return (
            <div className="error-state">
                <div className="error-icon">⚠️</div>
                <p>{error?.message || error || 'Veriler yüklenemedi'}</p>
                {error && (
                    <div className="error-meta">
                        {error.status && <span>HTTP {error.status}</span>}
                        {error.requestId && <span>RequestId: {error.requestId}</span>}
                        {error.timestamp && <span>{new Date(error.timestamp).toLocaleTimeString('tr-TR')}</span>}
                    </div>
                )}
                <button onClick={fetchStats} className="btn-retry">Tekrar Dene</button>
            </div>
        );
    }

    const completionRate = stats.totalToday > 0
        ? Math.round((stats.done / stats.totalToday) * 100) : 0;

    const maxTriage = stats.triageLevels
        ? Math.max(...Object.values(stats.triageLevels), 1) : 1;

    const formatTime = (date) => {
        if (!date) return '—';
        try {
            return new Date(date).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
        } catch {
            return '—';
        }
    };

    return (
        <div className="dashboard">
            <div className="dashboard-header">
                <h1>📊 Dashboard</h1>
                <div className="subtitle">
                    <span>Bugünkü acil servis özeti • Otomatik güncelleme 30 sn</span>
                    <div className="header-meta">
                        <span className="badge">Son güncelleme: {formatTime(lastUpdated)}</span>
                        <button className="btn-link" onClick={fetchStats}>Yenile</button>
                    </div>
                </div>
            </div>

            <div className="stats-grid">
                <div className="stat-card total">
                    <div className="stat-icon">📋</div>
                    <div className="stat-info">
                        <span className="stat-value">{stats.totalToday}</span>
                        <span className="stat-label">Toplam Hasta</span>
                    </div>
                </div>
                <div className="stat-card waiting">
                    <div className="stat-icon">⏳</div>
                    <div className="stat-info">
                        <span className="stat-value">{stats.waiting}</span>
                        <span className="stat-label">Bekleyen</span>
                    </div>
                </div>
                <div className="stat-card called">
                    <div className="stat-icon">📢</div>
                    <div className="stat-info">
                        <span className="stat-value">{stats.called}</span>
                        <span className="stat-label">Çağrılan</span>
                    </div>
                </div>
                <div className="stat-card progress">
                    <div className="stat-icon">🩺</div>
                    <div className="stat-info">
                        <span className="stat-value">{stats.inProgress}</span>
                        <span className="stat-label">Muayenede</span>
                    </div>
                </div>
                <div className="stat-card done">
                    <div className="stat-icon">✅</div>
                    <div className="stat-info">
                        <span className="stat-value">{stats.done}</span>
                        <span className="stat-label">Tamamlanan</span>
                    </div>
                </div>
                <div className="stat-card noshow">
                    <div className="stat-icon">❌</div>
                    <div className="stat-info">
                        <span className="stat-value">{stats.noShow}</span>
                        <span className="stat-label">Gelmedi</span>
                    </div>
                </div>
            </div>

            <div className="dashboard-row">
                <div className="dashboard-card">
                    <h3>📈 Performans</h3>
                    <div className="metric-list">
                        <div className="metric">
                            <span>Tamamlanma Oranı</span>
                            <span className="metric-value">%{completionRate}</span>
                        </div>
                        <div className="metric">
                            <span>Son 1 saatte tamamlanan</span>
                            <span className="metric-value">
                                {stats.doneLastHour ?? 0}
                            </span>
                        </div>
                        <div className="metric">
                            <span>Ortalama Bekleme</span>
                            <span className="metric-value">
                                {stats.avgWaitTime ? `${Math.round(stats.avgWaitTime)} dk` : '—'}
                            </span>
                        </div>
                        <div className="metric">
                            <span>Aktif Hasta</span>
                            <span className="metric-value">
                                {stats.waiting + stats.called + stats.inProgress}
                            </span>
                        </div>
                    </div>
                </div>

                <div className="dashboard-card">
                    <h3>🚦 Triaj Dağılımı</h3>
                    <div className="triage-bars">
                        {['KIRMIZI', 'SARI', 'YESIL'].map(level => {
                            const count = stats.triageLevels?.[level] || 0;
                            const width = (count / maxTriage) * 100;
                            return (
                                <div key={level} className={`triage-bar ${level.toLowerCase()}`}>
                                    <span className="bar-label">{level}</span>
                                    <div className="bar-track">
                                        <div className="bar-fill" style={{ width: `${width}%` }}></div>
                                    </div>
                                    <span className="bar-count">{count}</span>
                                </div>
                            );
                        })}
                        {(!stats.triageLevels || Object.keys(stats.triageLevels).length === 0) && (
                            <p className="no-data">ℹ️ Henüz triaj kaydı yok</p>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
