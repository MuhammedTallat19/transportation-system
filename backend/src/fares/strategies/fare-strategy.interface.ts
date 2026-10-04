export interface FareBreakdown {
  baseFareCents: number;
  distanceComponentCents: number;
  stationComponentCents: number;
  surchargeCents: number;
}

export interface FareCalculationResult {
  breakdown: FareBreakdown;
  totalCents: number;
  currency: string;
}

export interface FareContext {
  baseFareCents: number;
  perKmRateCents: number;
  perStationRateCents: number;
  minFareCents: number;
  maxFareCents?: number | null;
  currency: string;
  distanceKm: number;
  stationCount: number;
}

export interface IFareStrategy {
  calculate(context: FareContext): FareCalculationResult;
}
