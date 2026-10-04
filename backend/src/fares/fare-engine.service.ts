import { Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FareStrategyFactory } from './strategies/fare-strategy.factory';
import { FareContext } from './strategies/fare-strategy.interface';
import { CreateFareRuleDto } from './dto/fare-rule.dto';
import { AuditService } from '../audit/audit.service';
import { AuthUser } from '../common/interfaces/auth-user.interface';

@Injectable()
export class FareEngineService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

  async calculateFare(routeId: string, startStationId: string, destStationId: string) {
    if (startStationId === destStationId) {
      throw new UnprocessableEntityException({
        code: 'INVALID_STATION_PAIR',
        message: 'Start and destination stations must differ',
      });
    }

    const fareRule = await this.prisma.fareRule.findFirst({
      where: { route_id: routeId, is_active: true },
    });
    if (!fareRule) {
      throw new NotFoundException({
        code: 'FARE_RULE_NOT_FOUND',
        message: 'No active fare rule exists for this route.',
      });
    }

    const segment = await this.resolveSegment(routeId, startStationId, destStationId);
    const context: FareContext = {
      baseFareCents: fareRule.base_fare_cents,
      perKmRateCents: fareRule.per_km_rate_cents,
      perStationRateCents: fareRule.per_station_rate_cents,
      minFareCents: fareRule.min_fare_cents,
      maxFareCents: fareRule.max_fare_cents,
      currency: fareRule.currency || 'EGP',
      distanceKm: segment.distanceKm,
      stationCount: segment.stationCount,
    };

    const strategy = FareStrategyFactory.getStrategy(fareRule.fare_type);
    const result = strategy.calculate(context);

    return {
      routeId,
      fareRuleId: fareRule.id,
      fareType: fareRule.fare_type,
      breakdown: result.breakdown,
      totalCents: result.totalCents,
      currency: result.currency,
      distanceKm: segment.distanceKm,
      estimatedDurationSec: Math.round(segment.distanceKm * 127.66),
    };
  }

  async resolveSegment(routeId: string, startStationId: string, destStationId: string) {
    const routeStations = await this.prisma.routeStation.findMany({
      where: { route_id: routeId },
      orderBy: { station_order: 'asc' },
    });

    const start = routeStations.find((rs) => rs.station_id === startStationId);
    const dest = routeStations.find((rs) => rs.station_id === destStationId);

    if (!start || !dest || start.station_order >= dest.station_order) {
      throw new UnprocessableEntityException({
        code: 'INVALID_STATION_PAIR',
        message: 'Stations are not on the same route in valid order',
      });
    }

    const between = routeStations.filter(
      (rs) => rs.station_order >= start.station_order && rs.station_order <= dest.station_order,
    );

    return {
      distanceKm: dest.distance_from_start_km - start.distance_from_start_km,
      stationCount: between.length,
    };
  }

  async listFareRules(routeId: string) {
    const rules = await this.prisma.fareRule.findMany({
      where: { route_id: routeId },
      orderBy: { created_at: 'desc' },
    });
    return { data: rules };
  }

  async createFareRule(routeId: string, dto: CreateFareRuleDto, user: AuthUser) {
    const route = await this.prisma.route.findUnique({ where: { id: routeId } });
    if (!route) {
      throw new NotFoundException({ code: 'ROUTE_NOT_FOUND', message: 'Route not found' });
    }

    const rule = await this.prisma.fareRule.create({
      data: {
        route_id: routeId,
        fare_type: dto.fareType,
        base_fare_cents: dto.baseFareCents ?? 0,
        per_km_rate_cents: dto.perKmRateCents ?? 0,
        per_station_rate_cents: dto.perStationRateCents ?? 0,
        min_fare_cents: dto.minFareCents ?? 0,
        max_fare_cents: dto.maxFareCents,
        currency: dto.currency ?? 'EGP',
        effective_from: dto.effectiveFrom ? new Date(dto.effectiveFrom) : new Date(),
        effective_to: dto.effectiveTo ? new Date(dto.effectiveTo) : undefined,
        is_active: false,
        drafted_by: user.userId,
      },
    });

    await this.auditService.log({
      actorUserId: user.userId,
      action: 'CREATE',
      entityType: 'FareRule',
      entityId: rule.id,
      afterState: rule,
    });

    return rule;
  }

  async approveFareRule(ruleId: string, user: AuthUser) {
    const rule = await this.prisma.fareRule.findUnique({ where: { id: ruleId } });
    if (!rule) {
      throw new NotFoundException({ code: 'FARE_RULE_NOT_FOUND', message: 'Fare rule not found' });
    }

    const priorActive = await this.prisma.fareRule.findFirst({
      where: { route_id: rule.route_id, is_active: true },
    });

    if (priorActive && priorActive.id !== rule.id) {
      await this.prisma.fareRule.update({
        where: { id: priorActive.id },
        data: { is_active: false },
      });
    }

    const updated = await this.prisma.fareRule.update({
      where: { id: ruleId },
      data: { is_active: true, approved_by: user.userId },
    });

    await this.auditService.log({
      actorUserId: user.userId,
      action: 'APPROVE',
      entityType: 'FareRule',
      entityId: ruleId,
      beforeState: rule,
      afterState: updated,
    });

    return updated;
  }
}
