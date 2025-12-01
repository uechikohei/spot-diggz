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
  userId: string;
  createdAt: string;
  updatedAt: string;
}
