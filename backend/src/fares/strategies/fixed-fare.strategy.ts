import { FareCalculationResult, FareContext, IFareStrategy } from './fare-strategy.interface';

export class FixedFareStrategy implements IFareStrategy {
  calculate(context: FareContext): FareCalculationResult {
    const totalCents = context.baseFareCents;
    return {
      breakdown: {
        baseFareCents: totalCents,
        distanceComponentCents: 0,
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
