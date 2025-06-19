import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Cliente } from './entities/cliente.entity';
import { ClienteService } from './cliente.service';
import { ClienteController } from './cliente.controller';
import { UsuarioModule } from '../usuario/usuario.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Cliente]),
    UsuarioModule,
  ],
  controllers: [ClienteController],
  providers: [ClienteService],
  exports: [ClienteService, TypeOrmModule],
})
export class ClienteModule {} 