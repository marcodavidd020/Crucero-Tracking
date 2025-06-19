import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Parada } from './entities/parada.entity';
import { ParadaService } from './parada.service';
import { ParadaController } from './parada.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Parada])],
  controllers: [ParadaController],
  providers: [ParadaService],
  exports: [ParadaService, TypeOrmModule],
})
export class ParadaModule {} 