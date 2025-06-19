import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UsuarioService } from './usuario.service';

@ApiTags('Usuarios')
@Controller('usuarios')
export class UsuarioController {
  constructor(private readonly usuarioService: UsuarioService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todos los usuarios' })
  async findAll() {
    return {
      success: true,
      data: await this.usuarioService.findAll(),
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener usuario por ID' })
  async findOne(@Param('id') id: string) {
    const usuario = await this.usuarioService.findOne(id);
    return {
      success: true,
      data: usuario,
    };
  }
} 