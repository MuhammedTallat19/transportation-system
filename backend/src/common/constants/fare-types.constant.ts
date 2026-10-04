export const FARE_TYPES = {
  FIXED: 'FIXED',
  DISTANCE_BASED: 'DISTANCE_BASED',
  STATION_BASED: 'STATION_BASED',
  STATION_COUNT: 'STATION_COUNT',
  DYNAMIC: 'DYNAMIC',
} as const;

export type FareTypeCode = (typeof FARE_TYPES)[keyof typeof FARE_TYPES];
