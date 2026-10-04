import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { FaresController } from './fares.controller';
import { FareEngineService } from './fare-engine.service';

@Module({
  imports: [AuditModule],
  controllers: [FaresController],
  providers: [FareEngineService],
  exports: [FareEngineService],
})
export class FaresModule {}
