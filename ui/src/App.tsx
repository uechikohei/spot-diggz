import { useEffect, useMemo, useRef, useState } from 'react';
import type { SdzSpot } from './types/spot';
import { useAuth } from './contexts/AuthContext';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

const apiUrl = import.meta.env.VITE_SDZ_API_URL || 'http://localhost:8080';

function formatCoords(location?: SdzSpot['location']) {
  if (!location) return 'N/A';
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
}

function App() {
  const {
    user,
    idToken,
    loginWithGoogle,
    loginWithEmail,
    signupWithEmail,
    resendVerification,
    logout,
    loading: authLoading,
  } = useAuth();
  const [spots, setSpots] = useState<SdzSpot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authError, setAuthError] = useState<string | null>(null);
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [signupEmail, setSignupEmail] = useState('');
  const [signupPassword, setSignupPassword] = useState('');
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);
  const [form, setForm] = useState({
    name: '',
    description: '',
    lat: '',
    lng: '',
    tags: '',
    image: null as File | null,
  });
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const subtitle = useMemo(
    () => `API base: ${apiUrl}（GET /sdz/spots を表示中）`,
    [],
  );
  const isEmailPending = user && !user.emailVerified;

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

  const handleLoginWithGoogle = async () => {
    setAuthError(null);
    try {
      await loginWithGoogle();
    } catch (err) {
      setAuthError((err as Error).message);
    }
  };

  const handleLoginWithEmail = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    try {
      await loginWithEmail(loginEmail, loginPassword);
      setLoginEmail('');
      setLoginPassword('');
    } catch (err) {
      setAuthError((err as Error).message);
    }
  };

  const handleSignupWithEmail = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    try {
      await signupWithEmail(signupEmail, signupPassword);
      setSignupEmail('');
      setSignupPassword('');
    } catch (err) {
      setAuthError((err as Error).message);
    }
  };

  const handleResendVerification = async () => {
    setAuthError(null);
    try {
      await resendVerification();
      setAuthError('確認メールを再送しました。受信トレイを確認してください。');
    } catch (err) {
      setAuthError((err as Error).message);
    }
  };

  const handleLogout = async () => {
    setAuthError(null);
    await logout();
  };

  const handleMapSelect = (lat: number, lng: number) => {
    setForm((f) => ({ ...f, lat: lat.toString(), lng: lng.toString() }));
  };

  const MapClicker: React.FC = () => {
    useMapEvents({
      click(e) {
        handleMapSelect(e.latlng.lat, e.latlng.lng);
      },
    });
    return null;
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
      const tags = form.tags
        ? form.tags
            .split(',')
            .map((t) => t.trim())
            .filter(Boolean)
        : [];

      // 画像アップロードは未実装のため、現状は空配列を送信。
      // TODO: 署名付きURLを取得してアップロードし、そのURLをimagesにセットする。
      const payload = {
        name: form.name,
        description: form.description || undefined,
        location:
          form.lat && form.lng
            ? { lat: Number(form.lat), lng: Number(form.lng) }
            : undefined,
        tags,
        images: [] as string[],
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
      setForm({ name: '', description: '', lat: '', lng: '', tags: '', image: null });
      if (fileInputRef.current) fileInputRef.current.value = '';
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
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <button type="button" onClick={handleLoginWithGoogle} disabled={authLoading}>
                Googleでログイン / 新規登録
              </button>
            </div>

            <form onSubmit={handleLoginWithEmail} style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <input
                type="email"
                placeholder="メールアドレスでログイン"
                value={loginEmail}
                onChange={(e) => setLoginEmail(e.target.value)}
                required
              />
              <input
                type="password"
                placeholder="パスワード"
                value={loginPassword}
                onChange={(e) => setLoginPassword(e.target.value)}
                required
              />
              <button type="submit" disabled={authLoading}>
                メールでログイン
              </button>
            </form>

            <form onSubmit={handleSignupWithEmail} style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              <input
                type="email"
                placeholder="メールアドレス（新規登録）"
                value={signupEmail}
                onChange={(e) => setSignupEmail(e.target.value)}
                required
              />
              <input
                type="password"
                placeholder="パスワード（新規登録）"
                value={signupPassword}
                onChange={(e) => setSignupPassword(e.target.value)}
                required
              />
              <button type="submit" disabled={authLoading}>
                メールで新規登録
              </button>
            </form>
            {authError && <div className="sdz-error">Authエラー: {authError}</div>}
          </div>
        )}
      </div>

      {/* 未認証ユーザー向けの案内（専用ビュー） */}
      {isEmailPending && (
        <div className="sdz-card" style={{ marginBottom: 16 }}>
          <h2>メール認証が必要です</h2>
          <p>
            {user?.email} 宛に認証メールを送信しました。受信トレイ（迷惑メール含む）でリンクを開いて認証してください。
          </p>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
            <button type="button" onClick={handleResendVerification}>
              認証メールを再送
            </button>
            <button type="button" onClick={() => window.location.reload()}>
              認証後は再読み込み
            </button>
            <button type="button" onClick={handleLogout}>
              ログアウト
            </button>
          </div>
          {authError && <div className="sdz-error">Authエラー: {authError}</div>}
        </div>
      )}

      {/* 認証済みユーザー専用コンテンツ */}
      {!isEmailPending && user && (
        /* 新規/更新ボタンプレースホルダ */
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
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <label>画像（1枚、未実装で送信はしない）</label>
              <input
                type="file"
                accept="image/*"
                ref={fileInputRef}
                onChange={(e) => setForm((f) => ({ ...f, image: e.target.files?.[0] ?? null }))}
              />
              <span className="sdz-meta">※ アップロード処理は後続実装予定。現在は送信されません。</span>
            </div>
            <div className="sdz-meta">地図をクリックすると緯度経度をセットできます。</div>
            <div className="sdz-map">
              <MapContainer
                center={[34.6873, 135.5262]}
                zoom={13}
                style={{ height: '100%', width: '100%' }}
                scrollWheelZoom
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                <MapClicker />
                {form.lat && form.lng && (
                  <Marker
                    position={[Number(form.lat), Number(form.lng)]}
                    icon={L.icon({
                      iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
                      shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
                    })}
                  />
                )}
              </MapContainer>
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
