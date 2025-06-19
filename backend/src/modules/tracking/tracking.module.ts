import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TrackingService } from './tracking.service';
import { TrackingGateway } from './tracking.gateway';
import { TrackingLocation } from './entities/tracking-location.entity';

@Module({
  imports: [TypeOrmModule.forFeature([TrackingLocation])],
  providers: [TrackingService, TrackingGateway],
  exports: [TrackingService, TypeOrmModule],
})
export class TrackingModule {} 