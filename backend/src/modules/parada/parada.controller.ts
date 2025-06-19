import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ParadaService } from './parada.service';

@ApiTags('Paradas')
@Controller('paradas')
export class ParadaController {
  constructor(private readonly paradaService: ParadaService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todas las paradas' })
  async findAll() {
    return {
      success: true,
      data: await this.paradaService.findAll(),
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener parada por ID' })
  async findOne(@Param('id') id: string) {
    const parada = await this.paradaService.findOne(id);
    return {
      success: true,
      data: parada,
    };
  }

  @Get('ruta/:rutaId')
  @ApiOperation({ summary: 'Obtener paradas de una ruta' })
  async findByRuta(@Param('rutaId') rutaId: string) {
    const paradas = await this.paradaService.findByRuta(rutaId);
    return {
      success: true,
      data: paradas,
    };
  }

  @Post()
  @ApiOperation({ summary: 'Crear nueva parada' })
  async create(@Body() paradaData: any) {
    const parada = await this.paradaService.create(paradaData);
    return {
      success: true,
      message: 'Parada creada correctamente',
      data: parada,
    };
  }

  @Put(':id')
  @ApiOperation({ summary: 'Actualizar parada' })
  async update(@Param('id') id: string, @Body() updateData: any) {
    const parada = await this.paradaService.update(id, updateData);
    return {
      success: true,
      message: 'Parada actualizada correctamente',
      data: parada,
    };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar parada' })
  async remove(@Param('id') id: string) {
    await this.paradaService.remove(id);
    return {
      success: true,
      message: 'Parada eliminada correctamente',
    };
  }
}