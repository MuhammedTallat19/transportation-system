import { Controller, Get } from '@nestjs/common';
import { GovernoratesService } from './governorates.service';
import { Public } from '../common/decorators/public.decorator';

@Controller('governorates')
export class GovernoratesController {
  constructor(private readonly governoratesService: GovernoratesService) {}

  @Public()
  @Get()
  findAll() {
    return this.governoratesService.findAll();
  }
}
