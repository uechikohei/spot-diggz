export interface SdzSpotLocation {
  lat: number;
  lng: number;
}

export interface SdzSpot {
  spotId: string;
  name: string;
  description?: string;
  location?: SdzSpotLocation;
  tags: string[];
  images: string[];
  trustLevel: 'verified' | 'unverified';
  trustSources?: string[];
  userId: string;
  createdAt: string;
  updatedAt: string;
}
