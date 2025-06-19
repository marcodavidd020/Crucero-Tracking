import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Micro } from './entities/micro.entity';
import { MicroService } from './micro.service';
import { MicroController } from './micro.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Micro])],
  controllers: [MicroController],
  providers: [MicroService],
  exports: [MicroService, TypeOrmModule],
})
export class MicroModule {}