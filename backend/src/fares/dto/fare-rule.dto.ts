import { Type } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { FARE_TYPES, FareTypeCode } from '../../common/constants/fare-types.constant';

export class CreateFareRuleDto {
  @IsEnum(FARE_TYPES)
  fareType!: FareTypeCode;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  baseFareCents?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  perKmRateCents?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  perStationRateCents?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minFareCents?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxFareCents?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsDateString()
  effectiveFrom?: string;

  @IsOptional()
  @IsDateString()
  effectiveTo?: string;
}

export class CalculateFareQueryDto {
  @IsString()
  routeId!: string;

  @IsString()
  startStationId!: string;

  @IsString()
  destStationId!: string;
}
