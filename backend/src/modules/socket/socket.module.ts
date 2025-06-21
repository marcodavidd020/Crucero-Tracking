import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SocketGateway } from './socket.gateway';
import { TrackingGateway } from './tracking.gateway';
import { TrackingLocation } from '../tracking/entities/tracking-location.entity';
import { Micro } from '../micro/entities/micro.entity';

@Module({
  imports: [TypeOrmModule.forFeature([TrackingLocation, Micro])],
  providers: [SocketGateway, TrackingGateway],
  exports: [SocketGateway, TrackingGateway],
})
export class SocketModule {} 