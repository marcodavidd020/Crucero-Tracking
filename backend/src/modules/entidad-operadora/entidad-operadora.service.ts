import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EntidadOperadora } from './entities/entidad-operadora.entity';
import { CreateEntidadOperadoraDto } from './dto/create-entidad-operadora.dto';
import { UpdateEntidadOperadoraDto } from './dto/update-entidad-operadora.dto';

@Injectable()
export class EntidadOperadoraService {
  constructor(
    @InjectRepository(EntidadOperadora)
    private readonly entidadRepository: Repository<EntidadOperadora>,
  ) {}

  async create(createDto: CreateEntidadOperadoraDto) {
    try {
      const entidad = this.entidadRepository.create({
        nombre: createDto.nombre,
        nit: createDto.nit,
        direccion: createDto.direccion,
        telefono: createDto.telefono,
        email: createDto.email,
        representante: createDto.representante,
        activo: true,
      });

      const savedEntidad = await this.entidadRepository.save(entidad);

      return {
        success: true,
        message: 'Entidad operadora creada exitosamente',
        data: savedEntidad,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al crear la entidad operadora',
        error: error.message,
      };
    }
  }

  async findAll() {
    try {
      const entidades = await this.entidadRepository.find({
        where: { activo: true },
        relations: ['rutas', 'empleados', 'micros'],
        order: { createdAt: 'DESC' },
      });

      return {
        success: true,
        message: 'Entidades operadoras obtenidas exitosamente',
        data: entidades,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al obtener las entidades operadoras',
        error: error.message,
      };
    }
  }

  async findOne(id: string) {
    try {
      const entidad = await this.entidadRepository.findOne({
        where: { id, activo: true },
        relations: ['rutas', 'empleados', 'micros'],
      });

      if (!entidad) {
        return {
          success: false,
          message: `Entidad operadora con ID ${id} no encontrada`,
        };
      }

      return {
        success: true,
        message: 'Entidad operadora encontrada',
        data: entidad,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al obtener la entidad operadora',
        error: error.message,
      };
    }
  }

  async update(id: string, updateDto: UpdateEntidadOperadoraDto) {
    try {
      const entidad = await this.entidadRepository.findOne({
        where: { id, activo: true },
      });

      if (!entidad) {
        return {
          success: false,
          message: `Entidad operadora con ID ${id} no encontrada`,
        };
      }

      Object.assign(entidad, updateDto);
      const updatedEntidad = await this.entidadRepository.save(entidad);

      return {
        success: true,
        message: 'Entidad operadora actualizada exitosamente',
        data: updatedEntidad,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al actualizar la entidad operadora',
        error: error.message,
      };
    }
  }

  async remove(id: string) {
    try {
      const entidad = await this.entidadRepository.findOne({
        where: { id, activo: true },
      });

      if (!entidad) {
        return {
          success: false,
          message: `Entidad operadora con ID ${id} no encontrada`,
        };
      }

      entidad.activo = false;
      await this.entidadRepository.save(entidad);

      return {
        success: true,
        message: 'Entidad operadora eliminada exitosamente',
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al eliminar la entidad operadora',
        error: error.message,
      };
    }
  }
} 