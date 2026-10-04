import { FareCalculationResult, FareContext, IFareStrategy } from './fare-strategy.interface';

export class StationCountFareStrategy implements IFareStrategy {
  calculate(context: FareContext): FareCalculationResult {
    const stationComponentCents = context.stationCount * context.perStationRateCents;
    const totalCents = Math.max(stationComponentCents, context.minFareCents);
    return {
      breakdown: {
        baseFareCents: 0,
        distanceComponentCents: 0,
        stationComponentCents,
        surchargeCents: 0,
      },
      totalCents: this.applyBounds(totalCents, context),
      currency: context.currency,
    };
  }

  private applyBounds(total: number, context: FareContext): number {
    let result = Math.max(total, context.minFareCents);
    if (context.maxFareCents != null) {
      result = Math.min(result, context.maxFareCents);
    }
    return result;
  }
}
