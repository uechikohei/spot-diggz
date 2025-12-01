import { useEffect, useMemo, useState } from 'react';
import type { SdzSpot } from './types/spot';
import { useAuth } from './contexts/AuthContext';

const apiUrl = import.meta.env.VITE_SDZ_API_URL || 'http://localhost:8080';

function formatCoords(location?: SdzSpot['location']) {
  if (!location) return 'N/A';
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
}

function App() {
  const { user, idToken, login, logout, loading: authLoading } = useAuth();
  const [spots, setSpots] = useState<SdzSpot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authError, setAuthError] = useState<string | null>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);
  const [form, setForm] = useState({
    name: '',
    description: '',
    lat: '',
    lng: '',
    tags: '',
  });

  const subtitle = useMemo(
    () => `API base: ${apiUrl}（GET /sdz/spots を表示中）`,
    [],
  );

  const fetchSpots = async (signal?: AbortSignal) => {
    try {
      const res = await fetch(`${apiUrl}/sdz/spots`, { signal });
      if (!res.ok) {
        throw new Error(`Failed to fetch spots: ${res.status}`);
      }
      const data: SdzSpot[] = await res.json();
      setSpots(data);
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') return;
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const controller = new AbortController();
    fetchSpots(controller.signal);
    return () => controller.abort();
  }, []);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    try {
      await login(email, password);
      setEmail('');
      setPassword('');
    } catch (err) {
      setAuthError((err as Error).message);
    }
  };

  const handleLogout = async () => {
    setAuthError(null);
    await logout();
  };

  const handleCreateSpot = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idToken) {
      setCreateError('ログインが必要です');
      return;
    }
    setCreateError(null);
    setCreating(true);
    try {
      const payload = {
        name: form.name,
        description: form.description || undefined,
        location:
          form.lat && form.lng
            ? { lat: Number(form.lat), lng: Number(form.lng) }
            : undefined,
        tags: form.tags
          ? form.tags
              .split(',')
              .map((t) => t.trim())
              .filter(Boolean)
          : [],
        images: [],
      };
      const res = await fetch(`${apiUrl}/sdz/spots`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${idToken}`,
        },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const msg = await res.text();
        throw new Error(`作成に失敗しました (${res.status}): ${msg}`);
      }
      await fetchSpots();
      setForm({ name: '', description: '', lat: '', lng: '', tags: '' });
    } catch (err) {
      setCreateError((err as Error).message);
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="sdz-container">
      <div className="sdz-header">
        <h1>spot-diggz スポット一覧</h1>
        <span className="sdz-meta">{subtitle}</span>
      </div>

      {/* 認証セクション */}
      <div className="sdz-card" style={{ marginBottom: 16 }}>
        {authLoading ? (
          <p>認証状態を確認中...</p>
        ) : user ? (
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <strong>ログイン中:</strong> {user.email ?? user.uid}
              <div className="sdz-meta">uid: {user.uid}</div>
            </div>
            <button onClick={handleLogout}>ログアウト</button>
          </div>
        ) : (
          <form onSubmit={handleLogin} style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <input
              type="email"
              placeholder="メールアドレス"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <input
              type="password"
              placeholder="パスワード"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
            <button type="submit" disabled={authLoading}>
              ログイン
            </button>
            {authError && <div className="sdz-error">Authエラー: {authError}</div>}
          </form>
        )}
      </div>

      {/* 新規/更新ボタンプレースホルダ */}
      {user && (
        <div className="sdz-card" style={{ marginBottom: 16 }}>
          <form onSubmit={handleCreateSpot} style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <label>名前</label>
              <input
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="スポット名"
                required
              />
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <label>説明</label>
              <textarea
                value={form.description}
                onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                placeholder="説明（任意）"
              />
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
                <label>緯度</label>
                <input
                  type="number"
                  step="0.0001"
                  value={form.lat}
                  onChange={(e) => setForm((f) => ({ ...f, lat: e.target.value }))}
                  placeholder="34.6873"
                />
              </div>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
                <label>経度</label>
                <input
                  type="number"
                  step="0.0001"
                  value={form.lng}
                  onChange={(e) => setForm((f) => ({ ...f, lng: e.target.value }))}
                  placeholder="135.5262"
                />
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <label>タグ（カンマ区切り）</label>
              <input
                value={form.tags}
                onChange={(e) => setForm((f) => ({ ...f, tags: e.target.value }))}
                placeholder="park,flat"
              />
            </div>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <button type="submit" disabled={creating}>
                {creating ? '送信中...' : '新規スポット登録'}
              </button>
              {createError && <div className="sdz-error">作成エラー: {createError}</div>}
            </div>
            <div className="sdz-meta">
              認証済みのみ。送信時に`Authorization: Bearer &lt;ID Token&gt;`を付与します。
            </div>
          </form>
        </div>
      )}

      {error && <div className="sdz-error">エラー: {error}</div>}
      {loading && <p>読み込み中...</p>}

      {!loading && !error && spots.length === 0 && <p>スポットがまだありません。</p>}

      {spots.map((spot) => (
        <div key={spot.spotId} className="sdz-card">
          <h3>{spot.name}</h3>
          <div className="sdz-meta">
            投稿者: {spot.userId} / 位置: {formatCoords(spot.location)} / 作成:{' '}
            {spot.createdAt}
          </div>
          {spot.description && <p>{spot.description}</p>}
          {spot.tags && spot.tags.length > 0 && (
            <div className="sdz-tags">
              {spot.tags.map((tag) => (
                <span key={tag} className="sdz-tag">
                  {tag}
                </span>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

export default App;
