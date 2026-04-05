import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../contexts/useAuth';
import type { SdzPlaceResult, SdzSpot } from '../types/spot';
import {
  sdzAdminCreateSpot,
  sdzAdminUpdateSpot,
  sdzAdminGetUploadUrl,
  sdzAdminUploadImage,
} from '../lib/SdzAdminApi';
import { SdzAdminMapPicker } from './SdzAdminMapPicker';

const sdzApiUrl = import.meta.env.VITE_SDZ_API_URL || 'http://localhost:8080';

const SDZ_ALLOWED_URL_SCHEMES = ['https:', 'http:'];

function sdzValidateUrl(value: string): string | null {
  if (!value) return null;
  try {
    const url = new URL(value);
    if (!SDZ_ALLOWED_URL_SCHEMES.includes(url.protocol)) {
      return `許可されていないURLスキームです: ${url.protocol}`;
    }
    return null;
  } catch {
    return '無効なURL形式です';
  }
}

export function SdzAdminSpotForm() {
  const { id } = useParams();
  const isEdit = id != null;
  const navigate = useNavigate();
  const { idToken } = useAuth();

  // 基本情報
  const [sdzName, setSdzName] = useState('');
  const [sdzDescription, setSdzDescription] = useState('');
  const [sdzLat, setSdzLat] = useState('');
  const [sdzLng, setSdzLng] = useState('');
  const [sdzTags, setSdzTags] = useState('');
  const [sdzImages, setSdzImages] = useState<string[]>([]);

  // Instagram
  const [sdzInstagramTag, setSdzInstagramTag] = useState('');
  const [sdzInstagramLocationUrl, setSdzInstagramLocationUrl] = useState('');
  const [sdzInstagramProfileUrl, setSdzInstagramProfileUrl] = useState('');

  // Google Places（自動入力 + 手動編集可）
  const [sdzGooglePlaceId, setSdzGooglePlaceId] = useState('');
  const [sdzGoogleMapsUrl, setSdzGoogleMapsUrl] = useState('');
  const [sdzAddress, setSdzAddress] = useState('');
  const [sdzPhoneNumber, setSdzPhoneNumber] = useState('');
  const [sdzOfficialUrl, setSdzOfficialUrl] = useState('');
  const [sdzBusinessHours, setSdzBusinessHours] = useState('');
  const [sdzGoogleRating, setSdzGoogleRating] = useState('');
  const [sdzGoogleRatingCount, setSdzGoogleRatingCount] = useState('');
  const [sdzGoogleTypes, setSdzGoogleTypes] = useState('');

  // UI状態
  const [sdzUploading, setSdzUploading] = useState(false);
  const [sdzSubmitting, setSdzSubmitting] = useState(false);
  const [sdzError, setSdzError] = useState<string | null>(null);
  const [sdzSuccess, setSdzSuccess] = useState<string | null>(null);
  const [sdzLoadingSpot, setSdzLoadingSpot] = useState(false);

  const handleLocationChange = useCallback((lat: string, lng: string) => {
    setSdzLat(lat);
    setSdzLng(lng);
  }, []);

  // Places Autocomplete からの自動入力
  const handlePlaceSelect = useCallback((place: SdzPlaceResult) => {
    setSdzName((prev) => prev || place.name);
    setSdzAddress(place.address);
    setSdzGooglePlaceId(place.placeId);
    setSdzGoogleMapsUrl(place.googleMapsUrl ?? '');
    setSdzPhoneNumber(place.phoneNumber ?? '');
    setSdzOfficialUrl((prev) => prev || (place.website ?? ''));
    setSdzGoogleRating(place.rating?.toString() ?? '');
    setSdzGoogleRatingCount(place.ratingCount?.toString() ?? '');
    setSdzGoogleTypes(place.types?.join(', ') ?? '');
    if (place.businessHours?.length) {
      setSdzBusinessHours(place.businessHours.join(' / '));
    }
  }, []);

  // 編集時: 既存データを読み込み
  useEffect(() => {
    if (!isEdit) return;
    setSdzLoadingSpot(true);
    fetch(`${sdzApiUrl}/sdz/spots/${id}`)
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json() as Promise<SdzSpot>;
      })
      .then((spot) => {
        setSdzName(spot.name);
        setSdzDescription(spot.description ?? '');
        setSdzLat(spot.location?.lat?.toString() ?? '');
        setSdzLng(spot.location?.lng?.toString() ?? '');
        setSdzTags(spot.tags?.join(', ') ?? '');
        setSdzImages(spot.images ?? []);
        setSdzInstagramTag(spot.instagramTag ?? '');
        setSdzInstagramLocationUrl(spot.instagramLocationUrl ?? '');
        setSdzInstagramProfileUrl(spot.instagramProfileUrl ?? '');
        setSdzGooglePlaceId(spot.googlePlaceId ?? '');
        setSdzGoogleMapsUrl(spot.googleMapsUrl ?? '');
        setSdzAddress(spot.address ?? '');
        setSdzPhoneNumber(spot.phoneNumber ?? '');
        setSdzOfficialUrl(spot.parkAttributes?.officialUrl ?? '');
        setSdzBusinessHours('');
        setSdzGoogleRating(spot.googleRating?.toString() ?? '');
        setSdzGoogleRatingCount(spot.googleRatingCount?.toString() ?? '');
        setSdzGoogleTypes(spot.googleTypes?.join(', ') ?? '');
      })
      .catch((err) => setSdzError((err as Error).message))
      .finally(() => setSdzLoadingSpot(false));
  }, [id, isEdit]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || !idToken) return;
    setSdzUploading(true);
    setSdzError(null);
    try {
      for (const file of Array.from(files)) {
        if (sdzImages.length >= 10) break;
        const result = await sdzAdminGetUploadUrl(idToken, file.type);
        await sdzAdminUploadImage(result.uploadUrl, file);
        setSdzImages((prev) => [...prev, result.objectUrl]);
      }
    } catch (err) {
      setSdzError((err as Error).message);
    } finally {
      setSdzUploading(false);
      e.target.value = '';
    }
  };

  const handleRemoveImage = (index: number) => {
    setSdzImages((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!idToken) {
      setSdzError('認証トークンがありません');
      return;
    }

    setSdzSubmitting(true);
    setSdzError(null);
    setSdzSuccess(null);

    // URL検証
    for (const [label, val] of [
      ['Instagram Location URL', sdzInstagramLocationUrl],
      ['Instagram Profile URL', sdzInstagramProfileUrl],
      ['公式サイトURL', sdzOfficialUrl],
      ['Google Maps URL', sdzGoogleMapsUrl],
    ] as const) {
      const err = sdzValidateUrl(val);
      if (err) {
        setSdzError(`${label}: ${err}`);
        setSdzSubmitting(false);
        return;
      }
    }

    const parseSplit = (value: string) =>
      value
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);

    const parsedLat = parseFloat(sdzLat);
    const parsedLng = parseFloat(sdzLng);
    const location =
      sdzLat && sdzLng && Number.isFinite(parsedLat) && Number.isFinite(parsedLng)
        ? { lat: parsedLat, lng: parsedLng }
        : undefined;

    const payload = {
      name: sdzName,
      description: sdzDescription || undefined,
      location,
      tags: parseSplit(sdzTags),
      images: sdzImages,
      instagramTag: sdzInstagramTag || undefined,
      instagramLocationUrl: sdzInstagramLocationUrl || undefined,
      instagramProfileUrl: sdzInstagramProfileUrl || undefined,
      googlePlaceId: sdzGooglePlaceId || undefined,
      googleMapsUrl: sdzGoogleMapsUrl || undefined,
      address: sdzAddress || undefined,
      phoneNumber: sdzPhoneNumber || undefined,
      officialUrl: sdzOfficialUrl || undefined,
      businessHours: sdzBusinessHours || undefined,
      googleRating: sdzGoogleRating ? parseFloat(sdzGoogleRating) : undefined,
      googleRatingCount: sdzGoogleRatingCount ? parseInt(sdzGoogleRatingCount, 10) : undefined,
      googleTypes: parseSplit(sdzGoogleTypes),
    };

    try {
      if (isEdit) {
        await sdzAdminUpdateSpot(idToken, id, payload);
        setSdzSuccess('スポットを更新しました');
      } else {
        await sdzAdminCreateSpot(idToken, payload);
        setSdzSuccess('スポットを作成しました');
        setTimeout(() => navigate('/admin'), 1000);
      }
    } catch (err) {
      setSdzError((err as Error).message);
    } finally {
      setSdzSubmitting(false);
    }
  };

  if (sdzLoadingSpot) {
    return <p>スポット情報を読み込み中...</p>;
  }

  return (
    <div className="sdz-card">
      <h3>{isEdit ? 'スポット編集' : 'スポット新規作成'}</h3>

      {sdzError && (
        <div className="sdz-error" style={{ marginBottom: 12 }}>
          {sdzError}
        </div>
      )}
      {sdzSuccess && <div style={{ color: '#4caf50', marginBottom: 12 }}>{sdzSuccess}</div>}

      <form onSubmit={handleSubmit}>
        <div style={{ display: 'grid', gap: 16 }}>
          {/* ===== 位置情報・Google Places 検索 ===== */}
          <fieldset style={{ border: '1px solid #e0e0e0', borderRadius: 8, padding: 16 }}>
            <legend style={{ fontWeight: 600 }}>📍 位置情報・Google Places 検索</legend>
            <SdzAdminMapPicker
              lat={sdzLat}
              lng={sdzLng}
              onLocationChange={handleLocationChange}
              onPlaceSelect={handlePlaceSelect}
            />
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 8 }}>
              <div>
                <label htmlFor="sdz-lat">緯度</label>
                <input
                  id="sdz-lat"
                  type="number"
                  step="any"
                  value={sdzLat}
                  onChange={(e) => setSdzLat(e.target.value)}
                  placeholder="35.6812"
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-lng">経度</label>
                <input
                  id="sdz-lng"
                  type="number"
                  step="any"
                  value={sdzLng}
                  onChange={(e) => setSdzLng(e.target.value)}
                  placeholder="139.7671"
                  style={{ width: '100%' }}
                />
              </div>
            </div>
            <div style={{ marginTop: 8 }}>
              <label htmlFor="sdz-address">住所</label>
              <input
                id="sdz-address"
                type="text"
                value={sdzAddress}
                onChange={(e) => setSdzAddress(e.target.value)}
                placeholder="Google Places から自動入力"
                style={{ width: '100%' }}
              />
            </div>
          </fieldset>

          {/* ===== 基本情報 ===== */}
          <fieldset style={{ border: '1px solid #e0e0e0', borderRadius: 8, padding: 16 }}>
            <legend style={{ fontWeight: 600 }}>📋 基本情報</legend>
            <div style={{ display: 'grid', gap: 12 }}>
              <div>
                <label htmlFor="sdz-name">スポット名 *</label>
                <input
                  id="sdz-name"
                  type="text"
                  value={sdzName}
                  onChange={(e) => setSdzName(e.target.value)}
                  required
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-description">説明</label>
                <textarea
                  id="sdz-description"
                  value={sdzDescription}
                  onChange={(e) => setSdzDescription(e.target.value)}
                  rows={3}
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-tags">タグ（カンマ区切り）</label>
                <input
                  id="sdz-tags"
                  type="text"
                  value={sdzTags}
                  onChange={(e) => setSdzTags(e.target.value)}
                  placeholder="初心者OK, 照明あり, 駐車場あり"
                  style={{ width: '100%' }}
                />
              </div>
            </div>
          </fieldset>

          {/* ===== 施設情報 ===== */}
          <fieldset style={{ border: '1px solid #e0e0e0', borderRadius: 8, padding: 16 }}>
            <legend style={{ fontWeight: 600 }}>🏢 施設情報</legend>
            <div style={{ display: 'grid', gap: 12 }}>
              <div>
                <label htmlFor="sdz-official-url">公式サイトURL</label>
                <input
                  id="sdz-official-url"
                  type="url"
                  value={sdzOfficialUrl}
                  onChange={(e) => setSdzOfficialUrl(e.target.value)}
                  placeholder="https://..."
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-phone">電話番号</label>
                <input
                  id="sdz-phone"
                  type="tel"
                  value={sdzPhoneNumber}
                  onChange={(e) => setSdzPhoneNumber(e.target.value)}
                  placeholder="03-1234-5678"
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-business-hours">営業時間</label>
                <input
                  id="sdz-business-hours"
                  type="text"
                  value={sdzBusinessHours}
                  onChange={(e) => setSdzBusinessHours(e.target.value)}
                  placeholder="月曜日: 9時00分～21時00分 / 火曜日: ..."
                  style={{ width: '100%' }}
                />
              </div>
            </div>
          </fieldset>

          {/* ===== Instagram ===== */}
          <fieldset style={{ border: '1px solid #e0e0e0', borderRadius: 8, padding: 16 }}>
            <legend style={{ fontWeight: 600 }}>📸 Instagram</legend>
            <div style={{ display: 'grid', gap: 12 }}>
              <div>
                <label htmlFor="sdz-instagram-tag">ハッシュタグ</label>
                <input
                  id="sdz-instagram-tag"
                  type="text"
                  value={sdzInstagramTag}
                  onChange={(e) => setSdzInstagramTag(e.target.value)}
                  placeholder="skateparkname"
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-instagram-location-url">Instagram ロケーションURL</label>
                <input
                  id="sdz-instagram-location-url"
                  type="url"
                  value={sdzInstagramLocationUrl}
                  onChange={(e) => setSdzInstagramLocationUrl(e.target.value)}
                  placeholder="https://www.instagram.com/explore/locations/..."
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label htmlFor="sdz-instagram-profile-url">Instagram プロフィールURL</label>
                <input
                  id="sdz-instagram-profile-url"
                  type="url"
                  value={sdzInstagramProfileUrl}
                  onChange={(e) => setSdzInstagramProfileUrl(e.target.value)}
                  placeholder="https://www.instagram.com/..."
                  style={{ width: '100%' }}
                />
              </div>
            </div>
          </fieldset>

          {/* ===== Google Places 情報（自動入力） ===== */}
          <fieldset style={{ border: '1px solid #e0e0e0', borderRadius: 8, padding: 16 }}>
            <legend style={{ fontWeight: 600 }}>🗺️ Google Places 情報</legend>
            <p style={{ fontSize: 12, color: '#888', marginBottom: 8 }}>
              地図検索で場所を選択すると自動入力されます。登録時点の評価情報です。
            </p>
            <div style={{ display: 'grid', gap: 12 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                <div>
                  <label htmlFor="sdz-google-place-id">Place ID</label>
                  <input
                    id="sdz-google-place-id"
                    type="text"
                    value={sdzGooglePlaceId}
                    onChange={(e) => setSdzGooglePlaceId(e.target.value)}
                    style={{ width: '100%' }}
                    readOnly
                  />
                </div>
                <div>
                  <label htmlFor="sdz-google-maps-url">Google Maps URL</label>
                  <input
                    id="sdz-google-maps-url"
                    type="url"
                    value={sdzGoogleMapsUrl}
                    onChange={(e) => setSdzGoogleMapsUrl(e.target.value)}
                    style={{ width: '100%' }}
                    readOnly
                  />
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                <div>
                  <label htmlFor="sdz-google-rating">Google 評価</label>
                  <input
                    id="sdz-google-rating"
                    type="number"
                    step="0.1"
                    min="1"
                    max="5"
                    value={sdzGoogleRating}
                    onChange={(e) => setSdzGoogleRating(e.target.value)}
                    style={{ width: '100%' }}
                    readOnly
                  />
                </div>
                <div>
                  <label htmlFor="sdz-google-rating-count">レビュー数</label>
                  <input
                    id="sdz-google-rating-count"
                    type="number"
                    value={sdzGoogleRatingCount}
                    onChange={(e) => setSdzGoogleRatingCount(e.target.value)}
                    style={{ width: '100%' }}
                    readOnly
                  />
                </div>
              </div>
              <div>
                <label htmlFor="sdz-google-types">施設タイプ</label>
                <input
                  id="sdz-google-types"
                  type="text"
                  value={sdzGoogleTypes}
                  onChange={(e) => setSdzGoogleTypes(e.target.value)}
                  style={{ width: '100%' }}
                  readOnly
                />
              </div>
            </div>
          </fieldset>

          {/* ===== 画像 ===== */}
          <fieldset style={{ border: '1px solid #e0e0e0', borderRadius: 8, padding: 16 }}>
            <legend style={{ fontWeight: 600 }}>🖼️ 画像 ({sdzImages.length}/10)</legend>
            {sdzImages.length > 0 && (
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 8 }}>
                {sdzImages.map((url, i) => (
                  <div key={`${url}-${i}`} style={{ position: 'relative' }}>
                    <img
                      src={url}
                      alt={`画像${i + 1}`}
                      style={{ width: 120, height: 80, objectFit: 'cover', borderRadius: 4 }}
                    />
                    <button
                      type="button"
                      onClick={() => handleRemoveImage(i)}
                      style={{
                        position: 'absolute',
                        top: -4,
                        right: -4,
                        background: '#e53935',
                        color: '#fff',
                        border: 'none',
                        borderRadius: '50%',
                        width: 20,
                        height: 20,
                        cursor: 'pointer',
                        fontSize: 12,
                        lineHeight: '20px',
                        padding: 0,
                      }}
                    >
                      x
                    </button>
                  </div>
                ))}
              </div>
            )}
            {sdzImages.length < 10 && (
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp,image/heic,image/heif"
                multiple
                onChange={handleImageUpload}
                disabled={sdzUploading}
              />
            )}
            {sdzUploading && <p className="sdz-meta">アップロード中...</p>}
          </fieldset>

          {/* ===== 送信 ===== */}
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            <button type="submit" disabled={sdzSubmitting || !sdzName}>
              {sdzSubmitting ? '保存中...' : isEdit ? '更新' : '作成'}
            </button>
            <button type="button" className="sdz-ghost" onClick={() => navigate('/admin')}>
              キャンセル
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
