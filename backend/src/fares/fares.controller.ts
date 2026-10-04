import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { FareEngineService } from './fare-engine.service';
import { CalculateFareQueryDto, CreateFareRuleDto } from './dto/fare-rule.dto';
import { Roles } from '../common/decorators/roles.decorator';
import { ROLES } from '../common/constants/roles.constant';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthUser } from '../common/interfaces/auth-user.interface';
import { Public } from '../common/decorators/public.decorator';

@Controller()
export class FaresController {
  constructor(private readonly fareEngine: FareEngineService) {}

  @Public()
  @Get('fares/calculate')
  calculate(@Query() query: CalculateFareQueryDto) {
    return this.fareEngine.calculateFare(query.routeId, query.startStationId, query.destStationId);
  }

  @Roles(ROLES.ADMIN, ROLES.TRANSPORT_AUTHORITY)
  @Get('routes/:id/fare-rules')
  listRules(@Param('id') routeId: string) {
    return this.fareEngine.listFareRules(routeId);
  }

  @Roles(ROLES.ADMIN, ROLES.TRANSPORT_AUTHORITY)
  @Post('routes/:id/fare-rules')
  createRule(@Param('id') routeId: string, @Body() dto: CreateFareRuleDto, @CurrentUser() user: AuthUser) {
    return this.fareEngine.createFareRule(routeId, dto, user);
  }

  @Roles(ROLES.TRANSPORT_AUTHORITY)
  @Post('fare-rules/:id/approve')
  approve(@Param('id') ruleId: string, @CurrentUser() user: AuthUser) {
    return this.fareEngine.approveFareRule(ruleId, user);
  }
}
