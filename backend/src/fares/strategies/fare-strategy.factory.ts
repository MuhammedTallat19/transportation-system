import { BadRequestException } from '@nestjs/common';
import { FARE_TYPES } from '../../common/constants/fare-types.constant';
import { DistanceFareStrategy } from './distance-fare.strategy';
import { FixedFareStrategy } from './fixed-fare.strategy';
import { IFareStrategy } from './fare-strategy.interface';
import { StationCountFareStrategy } from './station-count-fare.strategy';

export class FareStrategyFactory {
  private static strategies: Record<string, IFareStrategy> = {
    [FARE_TYPES.FIXED]: new FixedFareStrategy(),
    [FARE_TYPES.DISTANCE_BASED]: new DistanceFareStrategy(),
    [FARE_TYPES.STATION_BASED]: new StationCountFareStrategy(),
    [FARE_TYPES.STATION_COUNT]: new StationCountFareStrategy(),
  };

  static getStrategy(fareType: string): IFareStrategy {
    const strategy = this.strategies[fareType];
    if (!strategy) {
      throw new BadRequestException({ code: 'UNSUPPORTED_FARE_TYPE', message: `Unsupported fare type: ${fareType}` });
    }
    return strategy;
  }
}
