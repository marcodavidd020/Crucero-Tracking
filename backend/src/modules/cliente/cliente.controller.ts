import { Controller, Get, Param, Put, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ClienteService } from './cliente.service';

@ApiTags('Clientes')
@Controller('clientes')
export class ClienteController {
  constructor(private readonly clienteService: ClienteService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todos los clientes' })
  async findAll() {
    return {
      success: true,
      data: await this.clienteService.findAll(),
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener cliente por ID' })
  async findOne(@Param('id') id: string) {
    const cliente = await this.clienteService.findOne(id);
    return {
      success: true,
      data: cliente,
    };
  }

  @Get('usuario/:userId')
  @ApiOperation({ summary: 'Obtener cliente por ID de usuario' })
  async findByUserId(@Param('userId') userId: string) {
    const cliente = await this.clienteService.findByUserId(userId);
    return {
      success: true,
      data: cliente,
    };
  }

  @Put(':id/saldo')
  @ApiOperation({ summary: 'Actualizar saldo del cliente' })
  async updateSaldo(@Param('id') id: string, @Body() body: { saldo: number }) {
    const cliente = await this.clienteService.update(id, { saldo: body.saldo });
    return {
      success: true,
      message: 'Saldo actualizado correctamente',
      data: cliente,
    };
  }
} 