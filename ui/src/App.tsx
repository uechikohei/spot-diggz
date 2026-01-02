import { useEffect, useMemo, useState } from 'react';
import type { SdzSpot } from './types/spot';
import { useAuth } from './contexts/useAuth';
import { Route, Routes, useNavigate, useParams } from 'react-router-dom';

const apiUrl = import.meta.env.VITE_SDZ_API_URL || 'http://localhost:8080';

function formatCoords(location?: SdzSpot['location']) {
  if (!location) return 'N/A';
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
}

type SdzSpotDetailProps = {
  spots: SdzSpot[];
  apiUrl: string;
};

function SdzSpotDetailPage({ spots, apiUrl }: SdzSpotDetailProps) {
  const { spotId } = useParams();
  const navigate = useNavigate();
  const [sdzDetail, setSdzDetail] = useState<SdzSpot | null>(null);
  const [sdzDetailLoading, setSdzDetailLoading] = useState(false);
  const [sdzDetailError, setSdzDetailError] = useState<string | null>(null);

  useEffect(() => {
    if (!spotId) return;
    const sdzExisting = spots.find((spot) => spot.spotId === spotId);
    if (sdzExisting) {
      setSdzDetail(sdzExisting);
      setSdzDetailError(null);
      return;
    }
    let isActive = true;
    setSdzDetailLoading(true);
    setSdzDetailError(null);
    fetch(`${apiUrl}/sdz/spots/${spotId}`)
      .then((res) => {
        if (!res.ok) {
          throw new Error(`Failed to fetch spot: ${res.status}`);
        }
        return res.json();
      })
      .then((data: SdzSpot) => {
        if (!isActive) return;
        setSdzDetail(data);
      })
      .catch((err) => {
        if (!isActive) return;
        setSdzDetailError((err as Error).message);
      })
      .finally(() => {
        if (!isActive) return;
        setSdzDetailLoading(false);
      });
    return () => {
      isActive = false;
    };
  }, [apiUrl, spotId, spots]);

  if (!spotId) {
    return (
      <div className="sdz-card">
        <p>スポットIDが指定されていません。</p>
        <button type="button" onClick={() => navigate('/')}>
          一覧へ戻る
        </button>
      </div>
    );
  }

  if (sdzDetailLoading) {
    return <p>スポット詳細を読み込み中...</p>;
  }

  if (sdzDetailError) {
    return (
      <div className="sdz-error">
        詳細取得エラー: {sdzDetailError}
        <div style={{ marginTop: 8 }}>
          <button type="button" onClick={() => navigate('/')}>
            一覧へ戻る
          </button>
        </div>
      </div>
    );
  }

  if (!sdzDetail) {
    return (
      <div className="sdz-card">
        <p>該当するスポットが見つかりませんでした。</p>
        <button type="button" onClick={() => navigate('/')}>
          一覧へ戻る
        </button>
      </div>
    );
  }

  return (
    <div className="sdz-card sdz-detail">
      <div className="sdz-detail-header">
        <div>
          <h2>{sdzDetail.name}</h2>
          <div className="sdz-meta">
            投稿者: {sdzDetail.userId} / 位置: {formatCoords(sdzDetail.location)}
            / 作成: {sdzDetail.createdAt}
          </div>
        </div>
        <button type="button" onClick={() => navigate('/')}>
          一覧へ戻る
        </button>
      </div>
      {sdzDetail.description && <p>{sdzDetail.description}</p>}
      {sdzDetail.tags && sdzDetail.tags.length > 0 && (
        <div className="sdz-tags">
          {sdzDetail.tags.map((tag) => (
            <span key={tag} className="sdz-tag">
              {tag}
            </span>
          ))}
        </div>
      )}
      <div>
        <strong>写真</strong>
        {sdzDetail.images?.length ? (
          <div className="sdz-image-grid">
            {sdzDetail.images.map((imageUrl) => (
              <img
                key={imageUrl}
                src={imageUrl}
                alt={`${sdzDetail.name}の画像`}
                className="sdz-image"
                loading="lazy"
              />
            ))}
          </div>
        ) : (
          <p className="sdz-meta">画像はまだ登録されていません。</p>
        )}
      </div>
    </div>
  );
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
  const [sdzSearchText, setSdzSearchText] = useState('');
  const [sdzSelectedTag, setSdzSelectedTag] = useState('all');

  const subtitle = `API base: ${apiUrl}（GET /sdz/spots を表示中）`;
  const isEmailPending = user && !user.emailVerified;
  const sdzAvailableTags = useMemo(() => {
    const tagSet = new Set<string>();
    spots.forEach((spot) => {
      spot.tags?.forEach((tag) => tagSet.add(tag));
    });
    return Array.from(tagSet).sort((a, b) => a.localeCompare(b));
  }, [spots]);
  const sdzFilteredSpots = useMemo(() => {
    const normalizedQuery = sdzSearchText.trim().toLowerCase();
    return spots.filter((spot) => {
      if (sdzSelectedTag !== 'all' && !spot.tags?.includes(sdzSelectedTag)) {
        return false;
      }
      if (!normalizedQuery) return true;
      const nameMatch = spot.name.toLowerCase().includes(normalizedQuery);
      const descMatch = spot.description
        ? spot.description.toLowerCase().includes(normalizedQuery)
        : false;
      const tagMatch = spot.tags?.some((tag) =>
        tag.toLowerCase().includes(normalizedQuery),
      );
      return nameMatch || descMatch || tagMatch;
    });
  }, [spots, sdzSearchText, sdzSelectedTag]);

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
  const handleResetFilters = () => {
    setSdzSearchText('');
    setSdzSelectedTag('all');
  };
  const navigate = useNavigate();

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

      <Routes>
        <Route
          path="/"
          element={
            <>
              {!loading && !error && spots.length === 0 && (
                <p>スポットがまだありません。</p>
              )}

              {!loading && !error && spots.length > 0 && (
                <div className="sdz-card sdz-controls">
                  <div className="sdz-controls-row">
                    <div className="sdz-controls-col">
                      <label htmlFor="sdz-search">キーワード</label>
                      <input
                        id="sdz-search"
                        type="text"
                        placeholder="スポット名・タグ・説明文で検索"
                        value={sdzSearchText}
                        onChange={(e) => setSdzSearchText(e.target.value)}
                      />
                    </div>
                    <div className="sdz-controls-col">
                      <label htmlFor="sdz-tag">タグ</label>
                      <select
                        id="sdz-tag"
                        value={sdzSelectedTag}
                        onChange={(e) => setSdzSelectedTag(e.target.value)}
                      >
                        <option value="all">すべて</option>
                        {sdzAvailableTags.map((tag) => (
                          <option key={tag} value={tag}>
                            {tag}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div className="sdz-controls-col sdz-controls-meta">
                      <span>
                        表示中: {sdzFilteredSpots.length} / {spots.length}
                      </span>
                      <button type="button" onClick={handleResetFilters}>
                        クリア
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {!loading &&
                !error &&
                spots.length > 0 &&
                sdzFilteredSpots.length === 0 && (
                  <p>条件に一致するスポットがありません。</p>
                )}

              {sdzFilteredSpots.map((spot) => (
                <div key={spot.spotId} className="sdz-card">
                  <div className="sdz-card-header">
                    <h3>{spot.name}</h3>
                    <button
                      type="button"
                      onClick={() => navigate(`/spots/${spot.spotId}`)}
                    >
                      詳細を見る
                    </button>
                  </div>
                  <div className="sdz-meta">
                    投稿者: {spot.userId} / 位置: {formatCoords(spot.location)} /
                    作成: {spot.createdAt}
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
            </>
          }
        />
        <Route
          path="/spots/:spotId"
          element={<SdzSpotDetailPage spots={spots} apiUrl={apiUrl} />}
        />
      </Routes>
    </div>
  );
}

export default App;
