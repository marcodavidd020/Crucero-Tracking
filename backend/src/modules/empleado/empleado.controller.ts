import { Controller, Get, Post, Body, Param, Put, Delete } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { EmpleadoService } from './empleado.service';

@ApiTags('Empleados')
@Controller('empleados')
export class EmpleadoController {
  constructor(private readonly empleadoService: EmpleadoService) {}

  @Get()
  @ApiOperation({ summary: 'Listar todos los empleados' })
  async findAll() {
    return {
      success: true,
      data: await this.empleadoService.findAll(),
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Obtener empleado por ID' })
  async findOne(@Param('id') id: string) {
    const empleado = await this.empleadoService.findOne(id);
    return {
      success: true,
      data: empleado,
    };
  }

  @Get('usuario/:userId')
  @ApiOperation({ summary: 'Obtener empleado por ID de usuario' })
  async findByUserId(@Param('userId') userId: string) {
    const empleado = await this.empleadoService.findByUserId(userId);
    return {
      success: true,
      data: empleado,
    };
  }

  @Get('entidad/:entidadId')
  @ApiOperation({ summary: 'Obtener empleados de una entidad' })
  async findByEntidad(@Param('entidadId') entidadId: string) {
    const empleados = await this.empleadoService.findByEntidad(entidadId);
    return {
      success: true,
      data: empleados,
    };
  }

  @Post()
  @ApiOperation({ summary: 'Crear nuevo empleado' })
  async create(@Body() empleadoData: any) {
    const empleado = await this.empleadoService.create(empleadoData);
    return {
      success: true,
      message: 'Empleado creado correctamente',
      data: empleado,
    };
  }

  @Put(':id')
  @ApiOperation({ summary: 'Actualizar empleado' })
  async update(@Param('id') id: string, @Body() updateData: any) {
    const empleado = await this.empleadoService.update(id, updateData);
    return {
      success: true,
      message: 'Empleado actualizado correctamente',
      data: empleado,
    };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar empleado' })
  async remove(@Param('id') id: string) {
    await this.empleadoService.remove(id);
    return {
      success: true,
      message: 'Empleado eliminado correctamente',
    };
  }
} 