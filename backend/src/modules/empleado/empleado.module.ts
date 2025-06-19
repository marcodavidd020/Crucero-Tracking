import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Empleado } from './entities/empleado.entity';
import { EmpleadoService } from './empleado.service';
import { EmpleadoController } from './empleado.controller';
import { UsuarioModule } from '../usuario/usuario.module';
import { EntidadOperadoraModule } from '../entidad-operadora/entidad-operadora.module';
import { MicroModule } from '../micro/micro.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Empleado]),
    UsuarioModule,
    EntidadOperadoraModule,
    MicroModule,
  ],
  controllers: [EmpleadoController],
  providers: [EmpleadoService],
  exports: [EmpleadoService, TypeOrmModule],
})
export class EmpleadoModule {} 