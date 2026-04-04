/* eslint-disable @typescript-eslint/no-explicit-any */
import { useCallback, useEffect, useRef, useState } from 'react';

// Google Maps API はランタイムで読み込まれるため、型はany扱い
declare const google: any;

interface SdzAdminMapPickerProps {
  lat: string;
  lng: string;
  onLocationChange: (lat: string, lng: string) => void;
}

// 管理画面用の簡易マップピッカー
// Google Maps API が利用できない場合はテキスト入力のフォールバックを表示
export function SdzAdminMapPicker({
  lat,
  lng,
  onLocationChange,
}: SdzAdminMapPickerProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const [sdzMapError, setSdzMapError] = useState(false);

  const handleMapClick = useCallback(
    (e: { lat: number; lng: number }) => {
      onLocationChange(e.lat.toFixed(6), e.lng.toFixed(6));
    },
    [onLocationChange],
  );

  useEffect(() => {
    // Google Maps API がロードされていない場合はフォールバック
    if (typeof google === 'undefined' || !google.maps) {
      setSdzMapError(true);
      return;
    }

    if (!mapRef.current) return;

    const center = {
      lat: parseFloat(lat) || 35.6812,
      lng: parseFloat(lng) || 139.7671,
    };

    const map = new google.maps.Map(mapRef.current, {
      center,
      zoom: 15,
      mapTypeControl: false,
      streetViewControl: false,
    });

    const marker = new google.maps.Marker({
      position: center,
      map,
      draggable: true,
    });

    map.addListener('click', (e: any) => {
      if (e.latLng) {
        marker.setPosition(e.latLng);
        handleMapClick({ lat: e.latLng.lat(), lng: e.latLng.lng() });
      }
    });

    marker.addListener('dragend', () => {
      const pos = marker.getPosition();
      if (pos) {
        handleMapClick({ lat: pos.lat(), lng: pos.lng() });
      }
    });
  }, [lat, lng, handleMapClick]);

  if (sdzMapError) {
    return (
      <p style={{ color: '#888', fontSize: 12 }}>
        地図ピッカーは利用できません。緯度・経度を直接入力してください。
      </p>
    );
  }

  return <div ref={mapRef} style={{ width: '100%', height: 300, borderRadius: 4 }} />;
}
