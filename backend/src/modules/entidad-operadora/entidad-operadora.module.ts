import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EntidadOperadoraController } from './entidad-operadora.controller';
import { EntidadOperadoraService } from './entidad-operadora.service';
import { EntidadOperadora } from './entities/entidad-operadora.entity';

@Module({
  imports: [TypeOrmModule.forFeature([EntidadOperadora])],
  controllers: [EntidadOperadoraController],
  providers: [EntidadOperadoraService],
  exports: [EntidadOperadoraService, TypeOrmModule],
})
export class EntidadOperadoraModule {} 