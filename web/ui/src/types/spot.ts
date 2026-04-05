export interface SdzSpotLocation {
  lat: number;
  lng: number;
}

export type SdzSpotType = 'park' | 'street';

export interface SdzSpot {
  spotId: string;
  name: string;
  description?: string;
  location?: SdzSpotLocation;
  tags: string[];
  images: string[];
  trustLevel: 'verified' | 'unverified';
  trustSources?: string[];
  spotType?: SdzSpotType;
  instagramUrl?: string;
  officialUrl?: string;
  businessHours?: string;
  sections?: string[];
  userId: string;
  createdAt: string;
  updatedAt: string;
}
