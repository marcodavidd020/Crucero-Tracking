import { Module } from '@nestjs/common';
import { SocketGateway } from './socket.gateway';
import { TrackingModule } from '../tracking/tracking.module';
 
@Module({
  imports: [TrackingModule],
  providers: [SocketGateway],
  exports: [SocketGateway],
})
export class SocketModule {} 