import { useState, useEffect } from 'react';
import { apiGet } from '../api';

const WaitingRoom = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [time, setTime] = useState(new Date());

    const fetchData = async () => {
        try {
            const json = await apiGet('/appointments/waiting-room');
            setData(json);
            setError(null);
        } catch (err) {
            console.error('Veri yüklenemedi:', err);
            setError(err.message || 'Veri yüklenemedi');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
        const dataInterval = setInterval(fetchData, 5000);
        const timeInterval = setInterval(() => setTime(new Date()), 1000);
        return () => {
            clearInterval(dataInterval);
            clearInterval(timeInterval);
        };
    }, []);

    if (loading) {
        return (
            <div className="waiting-room-loading">
                <div className="spinner"></div>
                <p>Yükleniyor...</p>
            </div>
        );
    }

    if (error) {
        return (
            <div className="waiting-room-error">
                <div className="error-icon">⚠️</div>
                <p>{error}</p>
                <button onClick={fetchData} className="btn-retry">Tekrar Dene</button>
            </div>
        );
    }

    return (
        <div className="waiting-room">
            <header className="wr-header">
                <div className="hospital-name">
                    <div className="icon">🏥</div>
                    <h1>Acil Servis Bekleme Ekranı</h1>
                </div>
                <div className="clock">
                    {time.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
                </div>
            </header>

            <main className="wr-content">
                <div className="current-call">
                    {data?.currentCall ? (
                        <>
                            <div className="call-label">Şu An Çağrılan</div>
                            <div className="call-number">{data.currentCall.queueNumber}</div>
                            <div className="call-name">{data.currentCall.patientName}</div>
                            <div className="call-message">{data.currentCall.message}</div>
                        </>
                    ) : (
                        <>
                            <div className="call-label">Bekleniyor</div>
                            <div className="call-number">—</div>
                            <div className="call-message">Şu an çağrılan hasta yok</div>
                        </>
                    )}
                </div>

                <div className="waiting-list">
                    <h2 style={{ textAlign: 'center', marginBottom: '20px' }}>📋 Bekleyen Sıra Numaraları</h2>
                    
                    <div className="waiting-lists-container" style={{ display: 'flex', gap: '20px', justifyContent: 'space-between', flexWrap: 'wrap' }}>
                        <div className="queue-column" style={{ flex: '1 1 30%', backgroundColor: '#fff1f0', padding: '15px', borderRadius: '12px', border: '2px solid #ffccc7', minWidth: '250px' }}>
                            <h3 style={{ color: '#cf1322', textAlign: 'center', marginBottom: '15px', fontSize: '1.2rem' }}>🟥 KIRMIZI (Acil)</h3>
                            <div className="queue-numbers" style={{ display: 'flex', flexWrap: 'wrap', gap: '10px', justifyContent: 'center' }}>
                                {data?.waitingList?.filter(w => w.colorCode === 'KIRMIZI').map((w, i) => (
                                    <div key={i} className="queue-item" style={{ backgroundColor: '#ff4d4f', color: 'white', border: 'none' }}>
                                        {w.queueNumber}
                                    </div>
                                ))}
                                {data?.waitingList?.filter(w => w.colorCode === 'KIRMIZI').length === 0 && <p className="no-waiting" style={{ color: '#ff7875' }}>Yok</p>}
                            </div>
                        </div>

                        <div className="queue-column" style={{ flex: '1 1 30%', backgroundColor: '#fffbe6', padding: '15px', borderRadius: '12px', border: '2px solid #ffe58f', minWidth: '250px' }}>
                            <h3 style={{ color: '#d48806', textAlign: 'center', marginBottom: '15px', fontSize: '1.2rem' }}>🟨 SARI (Öncelikli)</h3>
                            <div className="queue-numbers" style={{ display: 'flex', flexWrap: 'wrap', gap: '10px', justifyContent: 'center' }}>
                                {data?.waitingList?.filter(w => w.colorCode === 'SARI' || !w.colorCode).map((w, i) => (
                                    <div key={i} className="queue-item" style={{ backgroundColor: '#faad14', color: 'white', border: 'none' }}>
                                        {w.queueNumber}
                                    </div>
                                ))}
                                {data?.waitingList?.filter(w => w.colorCode === 'SARI' || !w.colorCode).length === 0 && <p className="no-waiting" style={{ color: '#ffc53d' }}>Yok</p>}
                            </div>
                        </div>

                        <div className="queue-column" style={{ flex: '1 1 30%', backgroundColor: '#f6ffed', padding: '15px', borderRadius: '12px', border: '2px solid #b7eb8f', minWidth: '250px' }}>
                            <h3 style={{ color: '#389e0d', textAlign: 'center', marginBottom: '15px', fontSize: '1.2rem' }}>🟩 YEŞİL (Normal)</h3>
                            <div className="queue-numbers" style={{ display: 'flex', flexWrap: 'wrap', gap: '10px', justifyContent: 'center' }}>
                                {data?.waitingList?.filter(w => w.colorCode === 'YESIL').map((w, i) => (
                                    <div key={i} className="queue-item" style={{ backgroundColor: '#52c41a', color: 'white', border: 'none' }}>
                                        {w.queueNumber}
                                    </div>
                                ))}
                                {data?.waitingList?.filter(w => w.colorCode === 'YESIL').length === 0 && <p className="no-waiting" style={{ color: '#95de64' }}>Yok</p>}
                            </div>
                        </div>
                    </div>

                    <div className="total-waiting" style={{ marginTop: '25px', textAlign: 'center', fontSize: '1.2rem', padding: '15px', backgroundColor: '#f0f5ff', borderRadius: '8px' }}>
                        Toplam Bekleyen Hasta: <strong>{data?.totalWaiting || 0}</strong>
                    </div>
                </div>
            </main>

            <footer className="wr-footer">
                Son güncelleme: {data?.lastUpdated || '—'}
            </footer>
        </div>
    );
};

export default WaitingRoom;
