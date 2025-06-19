import { Controller, Get, Post, Body, Param, Put, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { RutaService } from './ruta.service';
import { CreateRutaDto } from './dto/create-ruta.dto';
import { UpdateRutaDto } from './dto/update-ruta.dto';

@ApiTags('ruta')
@Controller('ruta')
export class RutaController {
  constructor(private readonly rutaService: RutaService) {}

  @Get()
  @ApiOperation({ summary: 'Obtener todas las rutas' })
  @ApiResponse({
    status: 200,
    description: 'Lista de todas las rutas',
  })
  async findAll() {
    return await this.rutaService.findAll();
  }

  @Get(':entidadId')
  @ApiOperation({ summary: 'Obtener rutas por ID de entidad operadora' })
  @ApiResponse({
    status: 200,
    description: 'Lista de rutas de la entidad operadora',
  })
  async findByEntidad(@Param('entidadId') entidadId: string) {
    return await this.rutaService.findByEntidad(entidadId);
  }

  @Get('find/:id')
  @ApiOperation({ summary: 'Obtener ruta por ID' })
  @ApiResponse({
    status: 200,
    description: 'Ruta encontrada',
  })
  @ApiResponse({
    status: 404,
    description: 'Ruta no encontrada',
  })
  async findOne(@Param('id') id: string) {
    return await this.rutaService.findOne(id);
  }

  @Post(':entidadId')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Crear nueva ruta para una entidad operadora' })
  @ApiBody({ type: CreateRutaDto })
  @ApiResponse({
    status: 201,
    description: 'Ruta creada exitosamente',
  })
  async create(
    @Param('entidadId') entidadId: string,
    @Body() createRutaDto: CreateRutaDto,
  ) {
    return await this.rutaService.create(entidadId, createRutaDto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Actualizar ruta' })
  @ApiBody({ type: UpdateRutaDto })
  @ApiResponse({
    status: 200,
    description: 'Ruta actualizada exitosamente',
  })
  async update(
    @Param('id') id: string,
    @Body() updateRutaDto: UpdateRutaDto,
  ) {
    return await this.rutaService.update(id, updateRutaDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar ruta' })
  @ApiResponse({
    status: 200,
    description: 'Ruta eliminada exitosamente',
  })
  async remove(@Param('id') id: string) {
    return await this.rutaService.remove(id);
  }
} 