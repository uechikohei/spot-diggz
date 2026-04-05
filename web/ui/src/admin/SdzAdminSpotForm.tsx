import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../contexts/useAuth';
import type { SdzSpot } from '../types/spot';
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
  const [sdzInstagramUrl, setSdzInstagramUrl] = useState('');
  const [sdzOfficialUrl, setSdzOfficialUrl] = useState('');
  const [sdzBusinessHours, setSdzBusinessHours] = useState('');
  const [sdzSections, setSdzSections] = useState('');
  const [sdzTags, setSdzTags] = useState('');
  const [sdzImages, setSdzImages] = useState<string[]>([]);
  const [sdzUploading, setSdzUploading] = useState(false);

  const handleLocationChange = useCallback((lat: string, lng: string) => {
    setSdzLat(lat);
    setSdzLng(lng);
  }, []);
  const [sdzSubmitting, setSdzSubmitting] = useState(false);
  const [sdzError, setSdzError] = useState<string | null>(null);
  const [sdzSuccess, setSdzSuccess] = useState<string | null>(null);
  const [sdzLoadingSpot, setSdzLoadingSpot] = useState(false);

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
        setSdzSpotType(spot.spotType ?? 'park');
        setSdzInstagramUrl(spot.instagramUrl ?? '');
        setSdzOfficialUrl(spot.officialUrl ?? '');
        setSdzBusinessHours(spot.businessHours ?? '');
        setSdzSections(spot.sections?.join(', ') ?? '');
        setSdzTags(spot.tags?.join(', ') ?? '');
        setSdzImages(spot.images ?? []);
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

    const sdzInstagramUrlError = sdzValidateUrl(sdzInstagramUrl);
    if (sdzInstagramUrlError) {
      setSdzError(`Instagram URL: ${sdzInstagramUrlError}`);
      setSdzSubmitting(false);
      return;
    }
    const sdzOfficialUrlError = sdzValidateUrl(sdzOfficialUrl);
    if (sdzOfficialUrlError) {
      setSdzError(`公式サイトURL: ${sdzOfficialUrlError}`);
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

    try {
      if (isEdit) {
        await sdzAdminUpdateSpot(idToken, id, {
          name: sdzName,
          description: sdzDescription || undefined,
          location,
          tags: parseSplit(sdzTags),
          images: sdzImages,
          spotType: sdzSpotType,
          instagramUrl: sdzInstagramUrl || undefined,
          officialUrl: sdzOfficialUrl || undefined,
          businessHours: sdzBusinessHours || undefined,
          sections: parseSplit(sdzSections),
        });
        setSdzSuccess('スポットを更新しました');
      } else {
        await sdzAdminCreateSpot(idToken, {
          name: sdzName,
          description: sdzDescription || undefined,
          location,
          tags: parseSplit(sdzTags),
          images: sdzImages,
          spotType: sdzSpotType,
          instagramUrl: sdzInstagramUrl || undefined,
          officialUrl: sdzOfficialUrl || undefined,
          businessHours: sdzBusinessHours || undefined,
          sections: parseSplit(sdzSections),
        });
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
            <label>位置情報</label>
            <SdzAdminMapPicker lat={sdzLat} lng={sdzLng} onLocationChange={handleLocationChange} />
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
          </div>

          <div>
            <label htmlFor="sdz-instagram-url">Instagram 位置情報ページURL</label>
            <input
              id="sdz-instagram-url"
              type="url"
              value={sdzInstagramUrl}
              onChange={(e) => setSdzInstagramUrl(e.target.value)}
              placeholder="https://www.instagram.com/explore/locations/..."
              style={{ width: '100%' }}
            />
          </div>

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
            <label htmlFor="sdz-business-hours">営業時間</label>
            <input
              id="sdz-business-hours"
              type="text"
              value={sdzBusinessHours}
              onChange={(e) => setSdzBusinessHours(e.target.value)}
              placeholder="平日 9:00-21:00 / 土日 8:00-22:00"
              style={{ width: '100%' }}
            />
          </div>

          <div>
            <label htmlFor="sdz-sections">セクション（カンマ区切り）</label>
            <input
              id="sdz-sections"
              type="text"
              value={sdzSections}
              onChange={(e) => setSdzSections(e.target.value)}
              placeholder="ミニランプ, フラットレール, ボウル"
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
