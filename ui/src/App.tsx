import { useEffect, useMemo, useState } from 'react';
import type { SdzSpot } from './types/spot';
import { useAuth } from './contexts/useAuth';
import { Route, Routes, useNavigate, useParams } from 'react-router-dom';

const apiUrl = import.meta.env.VITE_SDZ_API_URL || 'http://localhost:8080';
const SDZ_FAVORITES_PAGE_SIZE = 8;

function formatCoords(location?: SdzSpot['location']) {
  if (!location) return 'N/A';
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
}

function formatDateTime(value?: string) {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function paginate<T>(items: T[], page: number, perPage: number) {
  const totalPages = Math.max(1, Math.ceil(items.length / perPage));
  const safePage = Math.min(Math.max(page, 1), totalPages);
  const start = (safePage - 1) * perPage;
  return {
    page: safePage,
    totalPages,
    items: items.slice(start, start + perPage),
  };
}

function getInitialFavorites(): string[] {
  if (typeof window === 'undefined') return [];
  const raw = window.localStorage.getItem('sdzFavorites');
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.filter((v) => typeof v === 'string') : [];
  } catch {
    return [];
  }
}

type SdzSpotDetailProps = {
  spots: SdzSpot[];
  apiUrl: string;
  favorites: string[];
  onToggleFavorite: (spotId: string) => void;
};

function SdzSpotDetailPage({
  spots,
  apiUrl,
  favorites,
  onToggleFavorite,
}: SdzSpotDetailProps) {
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

  const sdzRelatedSpots = useMemo(() => {
    if (!sdzDetail) return [];
    const baseTags = new Set(sdzDetail.tags ?? []);
    const related = spots.filter((spot) => {
      if (spot.spotId === sdzDetail.spotId) return false;
      return spot.tags?.some((tag) => baseTags.has(tag));
    });
    return related.slice(0, 5);
  }, [sdzDetail, spots]);

  if (!spotId) {
    return (
      <div className="sdz-card sdz-empty">
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
      <div className="sdz-card sdz-empty">
        <p>該当するスポットが見つかりませんでした。</p>
        <button type="button" onClick={() => navigate('/')}>
          一覧へ戻る
        </button>
      </div>
    );
  }

  return (
    <div className="sdz-detail-layout">
      <div className="sdz-card sdz-detail">
        <div className="sdz-detail-header">
          <div>
            <p className="sdz-eyebrow">Spot Detail</p>
            <h2>{sdzDetail.name}</h2>
            <div className="sdz-meta">
              投稿者: {sdzDetail.userId} / 位置: {formatCoords(sdzDetail.location)} / 作成:
              {formatDateTime(sdzDetail.createdAt)}
            </div>
          </div>
          <div className="sdz-detail-actions">
            <button
              type="button"
              className={`sdz-favorite ${favorites.includes(sdzDetail.spotId) ? 'is-active' : ''}`}
              onClick={() => onToggleFavorite(sdzDetail.spotId)}
            >
              {favorites.includes(sdzDetail.spotId) ? '★ 保存済み' : '☆ お気に入り'}
            </button>
            <button type="button" className="sdz-ghost" onClick={() => navigate('/')}>
              一覧へ戻る
            </button>
          </div>
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
      <aside className="sdz-related">
        <div className="sdz-card">
          <h3>関連スポット</h3>
          <p className="sdz-meta">同じタグのスポットを優先表示</p>
          {sdzRelatedSpots.length === 0 ? (
            <p className="sdz-meta">まだ関連スポットがありません。</p>
          ) : (
            <div className="sdz-related-list">
              {sdzRelatedSpots.map((spot) => (
                <button
                  key={spot.spotId}
                  type="button"
                  className="sdz-related-item"
                  onClick={() => navigate(`/spots/${spot.spotId}`)}
                >
                  <span>{spot.name}</span>
                  <span className="sdz-meta">{formatCoords(spot.location)}</span>
                </button>
              ))}
            </div>
          )}
        </div>
      </aside>
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
    sendPasswordReset,
  } = useAuth();
  const [spots, setSpots] = useState<SdzSpot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [authError, setAuthError] = useState<string | null>(null);
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [sdzAuthMode, setSdzAuthMode] = useState<'login' | 'signup'>('login');
  const [sdzSearchText, setSdzSearchText] = useState('');
  const [sdzSelectedTag, setSdzSelectedTag] = useState('all');
  const [sdzFavorites, setSdzFavorites] = useState<string[]>(getInitialFavorites);
  const [sdzProfileMessage, setSdzProfileMessage] = useState<string | null>(null);
  const [sdzFavoritesPage, setSdzFavoritesPage] = useState(1);

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

  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem('sdzFavorites', JSON.stringify(sdzFavorites));
  }, [sdzFavorites]);

  useEffect(() => {
    setSdzFavoritesPage(1);
  }, [sdzFavorites.length]);

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
      await signupWithEmail(loginEmail, loginPassword);
      setLoginEmail('');
      setLoginPassword('');
    } catch (err) {
      if (
        err &&
        typeof err === 'object' &&
        'code' in err &&
        (err as { code?: string }).code === 'auth/email-already-in-use'
      ) {
        setAuthError('すでに登録済みです。ログインしてください。');
        setSdzAuthMode('login');
        return;
      }
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

  const handleAuthSubmit = async (e: React.FormEvent) => {
    if (sdzAuthMode === 'login') {
      await handleLoginWithEmail(e);
      return;
    }
    await handleSignupWithEmail(e);
  };

  const handleToggleFavorite = (spotId: string) => {
    setSdzFavorites((prev) =>
      prev.includes(spotId)
        ? prev.filter((id) => id !== spotId)
        : [...prev, spotId],
    );
  };

  const handlePasswordReset = async () => {
    setSdzProfileMessage(null);
    try {
      await sendPasswordReset();
      setSdzProfileMessage('パスワード再設定メールを送信しました。');
    } catch (err) {
      setSdzProfileMessage((err as Error).message);
    }
  };

  const handleRefresh = () => fetchSpots();
  const handleResetFilters = () => {
    setSdzSearchText('');
    setSdzSelectedTag('all');
  };
  const navigate = useNavigate();
  const sdzMySpots = useMemo(
    () => spots.filter((spot) => (user ? spot.userId === user.uid : false)),
    [spots, user],
  );
  const sdzFavoriteSpots = useMemo(
    () => spots.filter((spot) => sdzFavorites.includes(spot.spotId)),
    [sdzFavorites, spots],
  );
  const sdzFavoritesPaging = useMemo(
    () => paginate(sdzFavoriteSpots, sdzFavoritesPage, SDZ_FAVORITES_PAGE_SIZE),
    [sdzFavoriteSpots, sdzFavoritesPage],
  );
  const sdzHasPasswordProvider = useMemo(
    () => user?.providerData?.some((provider) => provider.providerId === 'password') ?? false,
    [user],
  );

  return (
    <div className="sdz-container">
      <header className="sdz-nav">
        <div className="sdz-brand">
          <span className="sdz-brand-mark">sdz</span>
          <span>spot-diggz</span>
        </div>
        <nav className="sdz-nav-links">
          <button type="button" className="sdz-ghost" onClick={() => navigate('/')}>
            Spots
          </button>
          <button
            type="button"
            className="sdz-ghost"
            onClick={() => navigate('/favorites')}
          >
            Favorites
          </button>
          <button type="button" className="sdz-ghost" onClick={() => navigate('/me')}>
            My Page
          </button>
        </nav>
      </header>

      {/* 認証セクション */}
      <div className="sdz-card sdz-auth-card">
        {authLoading ? (
          <p>認証状態を確認中...</p>
        ) : user ? (
          <div className="sdz-auth-info">
            <div>
              <strong>ログイン中:</strong> {user.email ?? user.uid}
              <div className="sdz-meta">uid: {user.uid}</div>
            </div>
            <button onClick={handleLogout}>ログアウト</button>
          </div>
        ) : (
          <div className="sdz-auth-actions">
            <div className="sdz-auth-row">
              <button type="button" onClick={handleLoginWithGoogle} disabled={authLoading}>
                Googleでログイン / 新規登録
              </button>
            </div>

            <div className="sdz-auth-row">
              <button
                type="button"
                className={`sdz-ghost ${sdzAuthMode === 'login' ? 'is-active' : ''}`}
                onClick={() => setSdzAuthMode('login')}
              >
                メールでログイン
              </button>
              <button
                type="button"
                className={`sdz-ghost ${sdzAuthMode === 'signup' ? 'is-active' : ''}`}
                onClick={() => setSdzAuthMode('signup')}
              >
                メールで新規登録
              </button>
            </div>

            <form onSubmit={handleAuthSubmit} className="sdz-auth-row">
              <input
                type="email"
                placeholder="メールアドレス"
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
                {sdzAuthMode === 'login' ? 'ログイン' : '新規登録'}
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
        <div className="sdz-card sdz-mode-card">
          <div className="sdz-mode-content">
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
              <section className="sdz-hero">
                <div className="sdz-hero-copy">
                  <p className="sdz-eyebrow">Skate Spot Finder</p>
                  <h1>Spotを掘る。滑りに行く。旅を作る。</h1>
                  <p className="sdz-hero-lead">
                    spot-diggzは、スケートスポットを探し、保存し、次のライドプランに組み込むための
                    シンプルなディレクトリです。モバイルアプリで投稿、Webは閲覧と整理に集中します。
                  </p>
                  <div className="sdz-hero-actions">
                    <div className="sdz-search">
                      <label htmlFor="sdz-search-hero">キーワードで探す</label>
                      <input
                        id="sdz-search-hero"
                        type="text"
                        placeholder="スポット名・タグ・説明文で検索"
                        value={sdzSearchText}
                        onChange={(e) => setSdzSearchText(e.target.value)}
                      />
                    </div>
                    <div className="sdz-search">
                      <label htmlFor="sdz-tag-hero">タグで絞る</label>
                      <select
                        id="sdz-tag-hero"
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
                    <div className="sdz-search-meta">
                      <span>
                        表示中 {sdzFilteredSpots.length} / {spots.length}
                      </span>
                      <button type="button" onClick={handleResetFilters}>
                        クリア
                      </button>
                    </div>
                  </div>
                  <div className="sdz-hero-stats">
                    <div>
                      <strong>{spots.length}</strong>
                      <span>登録スポット</span>
                    </div>
                    <div>
                      <strong>{sdzFavoriteSpots.length}</strong>
                      <span>お気に入り</span>
                    </div>
                    <div>
                      <strong>{sdzAvailableTags.length}</strong>
                      <span>タグ</span>
                    </div>
                  </div>
                  <div className="sdz-hero-footnote">{subtitle}</div>
                </div>
                <div className="sdz-hero-panel">
                  <div className="sdz-map-card">
                    <div className="sdz-map-preview">
                      <div className="sdz-map-dot" />
                      <div className="sdz-map-dot sdz-map-dot-alt" />
                      <div className="sdz-map-dot sdz-map-dot-alt2" />
                    </div>
                    <div>
                      <h3>近くのスポットを探す</h3>
                      <p className="sdz-meta">
                        現在地はブラウザの位置情報設定から許可してください。モバイル環境の方が取得しやすいです。
                      </p>
                    </div>
                  </div>
                  <div className="sdz-card sdz-app-box">
                    <h3>アプリでスポット登録</h3>
                    <p className="sdz-meta">
                      Webは閲覧と整理専用です。スポット登録や画像投稿はモバイルアプリから行います。
                    </p>
                    <div className="sdz-app-links">
                      <button type="button" className="sdz-ghost" disabled>
                        iOSアプリ（準備中）
                      </button>
                      <button type="button" className="sdz-ghost" disabled>
                        Androidアプリ（準備中）
                      </button>
                    </div>
                    <div className="sdz-meta">QR/リンクは後日追加予定</div>
                  </div>
                </div>
              </section>

              {!loading && !error && spots.length === 0 && (
                <p>スポットがまだありません。</p>
              )}

              {!loading &&
                !error &&
                spots.length > 0 &&
                sdzFilteredSpots.length === 0 && (
                  <p>条件に一致するスポットがありません。</p>
                )}

              <div className="sdz-spot-grid">
                {sdzFilteredSpots.map((spot) => (
                  <div key={spot.spotId} className="sdz-card sdz-spot-card">
                    <div className="sdz-card-header">
                      <div>
                        <h3>{spot.name}</h3>
                        <div className="sdz-meta">
                          投稿者: {spot.userId} / 位置: {formatCoords(spot.location)} / 作成:
                          {formatDateTime(spot.createdAt)}
                        </div>
                      </div>
                      <button
                        type="button"
                        className={`sdz-favorite ${
                          sdzFavorites.includes(spot.spotId) ? 'is-active' : ''
                        }`}
                        onClick={() => handleToggleFavorite(spot.spotId)}
                      >
                        {sdzFavorites.includes(spot.spotId) ? '★' : '☆'}
                      </button>
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
                    <div className="sdz-card-footer">
                      <button type="button" onClick={() => navigate(`/spots/${spot.spotId}`)}>
                        詳細を見る
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </>
          }
        />
        <Route
          path="/spots/:spotId"
          element={
            <SdzSpotDetailPage
              spots={spots}
              apiUrl={apiUrl}
              favorites={sdzFavorites}
              onToggleFavorite={handleToggleFavorite}
            />
          }
        />
        <Route
          path="/favorites"
          element={
            <div className="sdz-card">
              <h2>お気に入り一覧</h2>
              <p className="sdz-meta">ローカル保存のお気に入りスポットです。</p>
              {sdzFavoriteSpots.length === 0 ? (
                <p className="sdz-meta">お気に入りがありません。</p>
              ) : (
                <>
                  <div className="sdz-related-list">
                    {sdzFavoritesPaging.items.map((spot) => (
                      <button
                        key={spot.spotId}
                        type="button"
                        className="sdz-related-item"
                        onClick={() => navigate(`/spots/${spot.spotId}`)}
                      >
                        <span>{spot.name}</span>
                        <span className="sdz-meta">{formatCoords(spot.location)}</span>
                      </button>
                    ))}
                  </div>
                  <div className="sdz-pagination">
                    <button
                      type="button"
                      className="sdz-ghost"
                      onClick={() => setSdzFavoritesPage((prev) => Math.max(1, prev - 1))}
                      disabled={sdzFavoritesPaging.page === 1}
                    >
                      前へ
                    </button>
                    <span>
                      {sdzFavoritesPaging.page} / {sdzFavoritesPaging.totalPages}
                    </span>
                    <button
                      type="button"
                      className="sdz-ghost"
                      onClick={() =>
                        setSdzFavoritesPage((prev) =>
                          Math.min(sdzFavoritesPaging.totalPages, prev + 1),
                        )
                      }
                      disabled={sdzFavoritesPaging.page === sdzFavoritesPaging.totalPages}
                    >
                      次へ
                    </button>
                  </div>
                </>
              )}
            </div>
          }
        />
        <Route
          path="/me"
          element={
            <div className="sdz-profile-grid">
              <div className="sdz-card">
                <h2>マイページ</h2>
                <p className="sdz-meta">ログインしたユーザーの情報と保存内容</p>
                {!user ? (
                  <p>ログインするとマイページを利用できます。</p>
                ) : (
                  <>
                    <div className="sdz-profile-summary">
                      <div>
                        <strong>{user.displayName || 'ユーザー名未設定'}</strong>
                        <div className="sdz-meta">{user.email ?? user.uid}</div>
                      </div>
                      <div className="sdz-profile-pill">
                        投稿 {sdzMySpots.length}件 / お気に入り {sdzFavoriteSpots.length}件
                      </div>
                    </div>
                    {sdzHasPasswordProvider ? (
                      <button type="button" className="sdz-ghost" onClick={handlePasswordReset}>
                        パスワード再設定メールを送信
                      </button>
                    ) : (
                      <div className="sdz-meta">
                        Googleログインの場合はGoogleアカウント側でパスワードを変更してください。
                      </div>
                    )}
                    {sdzProfileMessage && <p className="sdz-meta">{sdzProfileMessage}</p>}
                    <button
                      type="button"
                      className="sdz-ghost"
                      onClick={() => navigate('/favorites')}
                    >
                      お気に入りページへ
                    </button>
                  </>
                )}
              </div>
              <div className="sdz-card">
                <h3>お気に入り</h3>
                {sdzFavoriteSpots.length === 0 ? (
                  <p className="sdz-meta">お気に入りがありません。</p>
                ) : (
                  <div className="sdz-related-list">
                    {sdzFavoriteSpots.map((spot) => (
                      <button
                        key={spot.spotId}
                        type="button"
                        className="sdz-related-item"
                        onClick={() => navigate(`/spots/${spot.spotId}`)}
                      >
                        <span>{spot.name}</span>
                        <span className="sdz-meta">{formatCoords(spot.location)}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
              <div className="sdz-card">
                <h3>自分のスポット</h3>
                {sdzMySpots.length === 0 ? (
                  <p className="sdz-meta">まだ投稿したスポットがありません。</p>
                ) : (
                  <div className="sdz-related-list">
                    {sdzMySpots.map((spot) => (
                      <button
                        key={spot.spotId}
                        type="button"
                        className="sdz-related-item"
                        onClick={() => navigate(`/spots/${spot.spotId}`)}
                      >
                        <span>{spot.name}</span>
                        <span className="sdz-meta">{formatCoords(spot.location)}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          }
        />
      </Routes>
    </div>
  );
}

export default App;
