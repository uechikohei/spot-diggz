export interface SdzSpotLocation {
  lat: number;
  lng: number;
}

export type SdzSpotType = 'park' | 'street';

export interface SdzSpotTimeRange {
  startMinutes: number;
  endMinutes: number;
}

export interface SdzSpotBusinessHours {
  scheduleType?: 'Regular' | 'WeekdayOnly' | 'WeekendOnly' | 'Irregular' | 'SchoolOnly' | 'Manual';
  is24Hours: boolean;
  sameAsWeekday: boolean;
  weekday?: SdzSpotTimeRange;
  weekend?: SdzSpotTimeRange;
  note?: string;
}

export interface SdzSpotParkAttributes {
  officialUrl?: string;
  businessHours?: SdzSpotBusinessHours;
  accessInfo?: string;
  phoneNumber?: string;
}

export interface SdzStreetSurfaceCondition {
  roughness?: string;
  crack?: string;
}

export interface SdzStreetSection {
  type: string;
  count?: number;
  heightCm?: number;
  widthCm?: number;
  notes?: string;
}

export interface SdzStreetAttributes {
  surfaceMaterial?: string;
  surfaceCondition?: SdzStreetSurfaceCondition;
  sections?: SdzStreetSection[];
  difficulty?: string;
  notes?: string;
}

export interface SdzSpot {
  spotId: string;
  name: string;
  description?: string;
  location?: SdzSpotLocation;
  tags: string[];
  images: string[];
  approvalStatus?: 'pending' | 'approved' | 'rejected';
  parkAttributes?: SdzSpotParkAttributes;
  streetAttributes?: SdzStreetAttributes;
  instagramTag?: string;
  instagramLocationUrl?: string;
  instagramProfileUrl?: string;
  googlePlaceId?: string;
  googleMapsUrl?: string;
  address?: string;
  phoneNumber?: string;
  googleRating?: number;
  googleRatingCount?: number;
  googleTypes?: string[];
  userId: string;
  createdAt: string;
  updatedAt: string;
}

// Google Places Autocomplete から取得した情報
export interface SdzPlaceResult {
  placeId: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  googleMapsUrl?: string;
  phoneNumber?: string;
  website?: string;
  rating?: number;
  ratingCount?: number;
  types?: string[];
  businessHours?: string[];
}
