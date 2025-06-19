import { Controller, Get, Post, Body, Param, Put, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { EntidadOperadoraService } from './entidad-operadora.service';
import { CreateEntidadOperadoraDto } from './dto/create-entidad-operadora.dto';
import { UpdateEntidadOperadoraDto } from './dto/update-entidad-operadora.dto';

@ApiTags('entidad')
@Controller('entidad-operadora')
export class EntidadOperadoraController {
  constructor(private readonly entidadOperadoraService: EntidadOperadoraService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Crear nueva entidad operadora' })
  @ApiBody({ type: CreateEntidadOperadoraDto })
  @ApiResponse({
    status: 201,
    description: 'Entidad operadora creada exitosamente',
  })
  async create(@Body() createEntidadOperadoraDto: CreateEntidadOperadoraDto) {
    return await this.entidadOperadoraService.create(createEntidadOperadoraDto);
  }

  @Get()
  @ApiOperation({ summary: 'Obtener todas las entidades operadoras' })
  @ApiResponse({
    status: 200,
    description: 'Lista de entidades operadoras',
  })
  async findAll() {
    return await this.entidadOperadoraService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener entidad operadora por ID' })
  @ApiResponse({
    status: 200,
    description: 'Entidad operadora encontrada',
  })
  @ApiResponse({
    status: 404,
    description: 'Entidad operadora no encontrada',
  })
  async findOne(@Param('id') id: string) {
    return await this.entidadOperadoraService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Actualizar entidad operadora' })
  @ApiBody({ type: UpdateEntidadOperadoraDto })
  @ApiResponse({
    status: 200,
    description: 'Entidad operadora actualizada exitosamente',
  })
  async update(
    @Param('id') id: string,
    @Body() updateEntidadOperadoraDto: UpdateEntidadOperadoraDto,
  ) {
    return await this.entidadOperadoraService.update(id, updateEntidadOperadoraDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar entidad operadora' })
  @ApiResponse({
    status: 200,
    description: 'Entidad operadora eliminada exitosamente',
  })
  async remove(@Param('id') id: string) {
    return await this.entidadOperadoraService.remove(id);
  }
} 