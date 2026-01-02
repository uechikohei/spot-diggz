import { useEffect, useMemo, useState } from 'react';
import type { SdzSpot } from './types/spot';
import { useAuth } from './contexts/useAuth';

const apiUrl = import.meta.env.VITE_SDZ_API_URL || 'http://localhost:8080';

function formatCoords(location?: SdzSpot['location']) {
  if (!location) return 'N/A';
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
}

function App() {
  const {
    user,
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

  const handleRefresh = () => fetchSpots();

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
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <strong>閲覧専用モード</strong>
              <div className="sdz-meta">
                新規登録・画像登録はモバイルアプリからのみ行えます。
              </div>
            </div>
            <button type="button" onClick={handleRefresh}>
              再読み込み
            </button>
          </div>
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
