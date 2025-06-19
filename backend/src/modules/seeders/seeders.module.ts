import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeedersService } from './seeders.service';
import { SeedersController } from './seeders.controller';
import { EntidadOperadora } from '../entidad-operadora/entities/entidad-operadora.entity';
import { Ruta } from '../ruta/entities/ruta.entity';
import { Usuario } from '../usuario/entities/usuario.entity';
import { Cliente } from '../cliente/entities/cliente.entity';
import { Empleado } from '../empleado/entities/empleado.entity';
import { Micro } from '../micro/entities/micro.entity';
import { Parada } from '../parada/entities/parada.entity';
import { TrackingLocation } from '../tracking/entities/tracking-location.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      EntidadOperadora,
      Ruta,
      Usuario,
      Cliente,
      Empleado,
      Micro,
      Parada,
      TrackingLocation,
    ])
  ],
  controllers: [SeedersController],
  providers: [SeedersService],
  exports: [SeedersService],
})
export class SeedersModule {} 