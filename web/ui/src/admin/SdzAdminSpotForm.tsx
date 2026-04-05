import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../contexts/useAuth';
import type { SdzSpot, SdzPlaceResult } from '../types/spot';
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

  const [sdzName, setSdzName] = useState('');
  const [sdzDescription, setSdzDescription] = useState('');
  const [sdzLat, setSdzLat] = useState('');
  const [sdzLng, setSdzLng] = useState('');
  const [sdzSpotType, setSdzSpotType] = useState('park');
  const [sdzTags, setSdzTags] = useState('');
  const [sdzImages, setSdzImages] = useState<string[]>([]);
  const [sdzOfficialUrl, setSdzOfficialUrl] = useState('');
  const [sdzBusinessHoursNote, setSdzBusinessHoursNote] = useState('');
  const [sdzAccessInfo, setSdzAccessInfo] = useState('');
  const [sdzInstagramLocationUrl, setSdzInstagramLocationUrl] = useState('');
  const [sdzGooglePlaceId, setSdzGooglePlaceId] = useState('');
  const [sdzGoogleMapsUrl, setSdzGoogleMapsUrl] = useState('');
  const [sdzAddress, setSdzAddress] = useState('');
  const [sdzPhoneNumber, setSdzPhoneNumber] = useState('');
  const [sdzGoogleRating, setSdzGoogleRating] = useState('');
  const [sdzGoogleRatingCount, setSdzGoogleRatingCount] = useState('');
  const [sdzGoogleTypes, setSdzGoogleTypes] = useState<string[]>([]);
  const [sdzUploading, setSdzUploading] = useState(false);
  const [sdzSubmitting, setSdzSubmitting] = useState(false);
  const [sdzError, setSdzError] = useState<string | null>(null);
  const [sdzSuccess, setSdzSuccess] = useState<string | null>(null);
  const [sdzLoadingSpot, setSdzLoadingSpot] = useState(false);

  const handleLocationChange = useCallback((lat: string, lng: string) => {
    setSdzLat(lat);
    setSdzLng(lng);
  }, []);

  const handlePlaceSelect = useCallback(
    (place: SdzPlaceResult) => {
      if (!sdzName && place.name) setSdzName(place.name);
      if (!sdzOfficialUrl && place.website) setSdzOfficialUrl(place.website);
      if (place.placeId) setSdzGooglePlaceId(place.placeId);
      if (place.googleMapsUrl) setSdzGoogleMapsUrl(place.googleMapsUrl);
      if (place.address) setSdzAddress(place.address);
      if (place.phoneNumber) setSdzPhoneNumber(place.phoneNumber);
      if (place.rating != null) setSdzGoogleRating(String(place.rating));
      if (place.ratingCount != null) setSdzGoogleRatingCount(String(place.ratingCount));
      if (place.types) setSdzGoogleTypes(place.types);
      if (place.businessHours?.length) {
        setSdzBusinessHoursNote(place.businessHours.join('\n'));
      }
    },
    [sdzName, sdzOfficialUrl],
  );

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
        setSdzSpotType(spot.parkAttributes ? 'park' : spot.streetAttributes ? 'street' : 'park');
        setSdzTags(spot.tags?.join(', ') ?? '');
        setSdzImages(spot.images ?? []);
        setSdzOfficialUrl(spot.parkAttributes?.officialUrl ?? '');
        setSdzBusinessHoursNote(spot.parkAttributes?.businessHours?.note ?? '');
        setSdzAccessInfo(spot.parkAttributes?.accessInfo ?? '');
        setSdzInstagramLocationUrl(spot.instagramLocationUrl ?? '');
        setSdzGooglePlaceId(spot.googlePlaceId ?? '');
        setSdzGoogleMapsUrl(spot.googleMapsUrl ?? '');
        setSdzAddress(spot.address ?? '');
        setSdzPhoneNumber(spot.phoneNumber ?? '');
        setSdzGoogleRating(spot.googleRating != null ? String(spot.googleRating) : '');
        setSdzGoogleRatingCount(
          spot.googleRatingCount != null ? String(spot.googleRatingCount) : '',
        );
        setSdzGoogleTypes(spot.googleTypes ?? []);
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

    const sdzOfficialUrlError = sdzValidateUrl(sdzOfficialUrl);
    if (sdzOfficialUrlError) {
      setSdzError(`公式サイトURL: ${sdzOfficialUrlError}`);
      setSdzSubmitting(false);
      return;
    }
    const sdzInstagramUrlError = sdzValidateUrl(sdzInstagramLocationUrl);
    if (sdzInstagramUrlError) {
      setSdzError(`Instagram URL: ${sdzInstagramUrlError}`);
      setSdzSubmitting(false);
      return;
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

    const hasParkData = sdzOfficialUrl || sdzBusinessHoursNote || sdzAccessInfo || sdzPhoneNumber;
    const parkAttributes =
      sdzSpotType === 'park' && hasParkData
        ? {
            officialUrl: sdzOfficialUrl || undefined,
            businessHours: sdzBusinessHoursNote
              ? {
                  scheduleType: 'manual' as const,
                  is24Hours: false,
                  sameAsWeekday: false,
                  note: sdzBusinessHoursNote,
                }
              : undefined,
            accessInfo: sdzAccessInfo || undefined,
            phoneNumber: sdzPhoneNumber || undefined,
          }
        : undefined;

    try {
      const payload = {
        name: sdzName,
        description: sdzDescription || undefined,
        location,
        tags: parseSplit(sdzTags),
        images: sdzImages,
        parkAttributes,
        instagramLocationUrl: sdzInstagramLocationUrl || undefined,
        googlePlaceId: sdzGooglePlaceId || undefined,
        googleMapsUrl: sdzGoogleMapsUrl || undefined,
        address: sdzAddress || undefined,
        phoneNumber: !parkAttributes ? sdzPhoneNumber || undefined : undefined,
        googleRating: sdzGoogleRating ? parseFloat(sdzGoogleRating) : undefined,
        googleRatingCount: sdzGoogleRatingCount ? parseInt(sdzGoogleRatingCount) : undefined,
        googleTypes: sdzGoogleTypes.length > 0 ? sdzGoogleTypes : undefined,
      };

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
            <label>スポットタイプ</label>
            <div style={{ display: 'flex', gap: 16 }}>
              <label>
                <input
                  type="radio"
                  name="spotType"
                  value="park"
                  checked={sdzSpotType === 'park'}
                  onChange={(e) => setSdzSpotType(e.target.value)}
                />{' '}
                パーク
              </label>
              <label>
                <input
                  type="radio"
                  name="spotType"
                  value="street"
                  checked={sdzSpotType === 'street'}
                  onChange={(e) => setSdzSpotType(e.target.value)}
                />{' '}
                ストリート
              </label>
            </div>
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
            <label>位置情報・場所検索</label>
            <SdzAdminMapPicker
              lat={sdzLat}
              lng={sdzLng}
              onLocationChange={handleLocationChange}
              onPlaceSelect={handlePlaceSelect}
            />
            {(sdzLat || sdzLng) && (
              <div style={{ marginTop: 8, fontSize: 13, color: '#666' }}>
                📍 緯度: {sdzLat || '—'} / 経度: {sdzLng || '—'}
              </div>
            )}
          </div>

          {sdzGooglePlaceId && (
            <div style={{ padding: 12, background: '#f5f5f5', borderRadius: 6, fontSize: 13 }}>
              <strong>Google Places 情報</strong>
              <div style={{ display: 'grid', gap: 4, marginTop: 6 }}>
                {sdzAddress && <div>住所: {sdzAddress}</div>}
                {sdzGoogleMapsUrl && (
                  <div>
                    Google Maps:{' '}
                    <a href={sdzGoogleMapsUrl} target="_blank" rel="noopener noreferrer">
                      開く
                    </a>
                  </div>
                )}
                {sdzPhoneNumber && <div>電話: {sdzPhoneNumber}</div>}
                {sdzGoogleRating && (
                  <div>
                    評価: {sdzGoogleRating} ({sdzGoogleRatingCount} 件)
                  </div>
                )}
                {sdzGoogleTypes.length > 0 && (
                  <div>
                    タイプ:{' '}
                    {sdzGoogleTypes.map((t) => (
                      <span
                        key={t}
                        style={{
                          display: 'inline-block',
                          background: '#e0e0e0',
                          borderRadius: 4,
                          padding: '1px 6px',
                          marginRight: 4,
                          fontSize: 11,
                        }}
                      >
                        {t}
                      </span>
                    ))}
                  </div>
                )}
                <div style={{ fontSize: 11, color: '#999', marginTop: 2 }}>
                  Place ID: {sdzGooglePlaceId}
                </div>
              </div>
            </div>
          )}

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
            <label htmlFor="sdz-business-hours">営業時間メモ</label>
            <textarea
              id="sdz-business-hours"
              value={sdzBusinessHoursNote}
              onChange={(e) => setSdzBusinessHoursNote(e.target.value)}
              rows={3}
              placeholder={'月曜日: 9:00〜21:00\n火曜日: 9:00〜21:00\n...'}
              style={{ width: '100%' }}
            />
          </div>

          <div>
            <label htmlFor="sdz-access-info">アクセス情報</label>
            <input
              id="sdz-access-info"
              type="text"
              value={sdzAccessInfo}
              onChange={(e) => setSdzAccessInfo(e.target.value)}
              placeholder="最寄り駅から徒歩10分、無料駐車場あり"
              style={{ width: '100%' }}
            />
          </div>

          <div>
            <label htmlFor="sdz-instagram-location-url">Instagram 位置情報ページURL</label>
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

          <div>
            <label>画像 ({sdzImages.length}/10)</label>
            {sdzImages.length > 0 && (
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 8 }}>
                {sdzImages.map((url, i) => (
                  <div key={url} style={{ position: 'relative' }}>
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
          </div>

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
