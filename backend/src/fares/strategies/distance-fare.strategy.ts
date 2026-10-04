import { FareCalculationResult, FareContext, IFareStrategy } from './fare-strategy.interface';

export class DistanceFareStrategy implements IFareStrategy {
  calculate(context: FareContext): FareCalculationResult {
    const distanceComponentCents = Math.round(context.distanceKm * context.perKmRateCents);
    const totalCents = context.baseFareCents + distanceComponentCents;
    return {
      breakdown: {
        baseFareCents: context.baseFareCents,
        distanceComponentCents,
        stationComponentCents: 0,
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
