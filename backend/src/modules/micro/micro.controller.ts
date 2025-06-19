import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { MicroService } from './micro.service';

@ApiTags('Micros')
@Controller('micros')
export class MicroController {
  constructor(private readonly microService: MicroService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todos los micros' })
  async findAll() {
    return {
      success: true,
      data: await this.microService.findAll(),
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener micro por ID' })
  async findOne(@Param('id') id: string) {
    const micro = await this.microService.findOne(id);
    return {
      success: true,
      data: micro,
    };
  }

  @Get('entidad/:entidadId')
  @ApiOperation({ summary: 'Obtener micros de una entidad' })
  async findByEntidad(@Param('entidadId') entidadId: string) {
    const micros = await this.microService.findByEntidad(entidadId);
    return {
      success: true,
      data: micros,
    };
  }

  @Post()
  @ApiOperation({ summary: 'Crear nuevo micro' })
  async create(@Body() microData: any) {
    const micro = await this.microService.create(microData);
    return {
      success: true,
      message: 'Micro creado correctamente',
      data: micro,
    };
  }

  @Put(':id')
  @ApiOperation({ summary: 'Actualizar micro' })
  async update(@Param('id') id: string, @Body() updateData: any) {
    const micro = await this.microService.update(id, updateData);
    return {
      success: true,
      message: 'Micro actualizado correctamente',
      data: micro,
    };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar micro' })
  async remove(@Param('id') id: string) {
    await this.microService.remove(id);
    return {
      success: true,
      message: 'Micro eliminado correctamente',
    };
  }
} 