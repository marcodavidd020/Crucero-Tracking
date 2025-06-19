import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Ruta } from './entities/ruta.entity';
import { CreateRutaDto } from './dto/create-ruta.dto';
import { UpdateRutaDto } from './dto/update-ruta.dto';

@Injectable()
export class RutaService {
  constructor(
    @InjectRepository(Ruta)
    private readonly rutaRepository: Repository<Ruta>,
  ) {}

  async create(entidadId: string, createRutaDto: CreateRutaDto) {
    try {
      const ruta = this.rutaRepository.create({
        nombre: createRutaDto.nombre,
        descripcion: createRutaDto.descripcion,
        idEntidad: entidadId,
        origenLat: parseFloat(createRutaDto.origenLat),
        origenLong: parseFloat(createRutaDto.origenLong),
        destinoLat: parseFloat(createRutaDto.destinoLat),
        destinoLong: parseFloat(createRutaDto.destinoLong),
        distancia: createRutaDto.distancia,
        tiempo: createRutaDto.tiempo,
        vertices: createRutaDto.vertices,
      });
      
      const savedRuta = await this.rutaRepository.save(ruta);

      return {
        success: true,
        message: 'Ruta creada exitosamente',
        data: savedRuta,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al crear la ruta',
        error: error.message,
      };
    }
  }

  async findAll() {
    try {
      const rutas = await this.rutaRepository.find({
        relations: ['entidad'],
        order: { createdAt: 'DESC' },
      });

      return {
        success: true,
        message: 'Rutas obtenidas exitosamente',
        data: rutas,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al obtener las rutas',
        error: error.message,
      };
    }
  }

  async findByEntidad(entidadId: string) {
    try {
      const rutas = await this.rutaRepository.find({
        where: { idEntidad: entidadId },
        relations: ['entidad'],
        order: { createdAt: 'DESC' },
      });

      return {
        success: true,
        message: 'Rutas obtenidas exitosamente',
        data: rutas,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al obtener las rutas',
        error: error.message,
      };
    }
  }

  async findOne(id: string) {
    try {
      const ruta = await this.rutaRepository.findOne({
        where: { id },
        relations: ['entidad', 'trackingLocations'],
      });

      if (!ruta) {
        return {
          success: false,
          message: `Ruta con ID ${id} no encontrada`,
        };
      }

      return {
        success: true,
        message: 'Ruta encontrada',
        data: ruta,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al obtener la ruta',
        error: error.message,
      };
    }
  }

  async update(id: string, updateRutaDto: UpdateRutaDto) {
    try {
      const ruta = await this.rutaRepository.findOne({
        where: { id },
      });

      if (!ruta) {
        return {
          success: false,
          message: `Ruta con ID ${id} no encontrada`,
        };
      }

      Object.assign(ruta, updateRutaDto);
      const updatedRuta = await this.rutaRepository.save(ruta);

      return {
        success: true,
        message: 'Ruta actualizada exitosamente',
        data: updatedRuta,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al actualizar la ruta',
        error: error.message,
      };
    }
  }

  async remove(id: string) {
    try {
      const ruta = await this.rutaRepository.findOne({
        where: { id },
      });

      if (!ruta) {
        return {
          success: false,
          message: `Ruta con ID ${id} no encontrada`,
        };
      }

      await this.rutaRepository.remove(ruta);

      return {
        success: true,
        message: 'Ruta eliminada exitosamente',
      };
    } catch (error) {
      return {
        success: false,
        message: 'Error al eliminar la ruta',
        error: error.message,
      };
    }
  }

  async findByIds(ids: string[]): Promise<Ruta[]> {
    return await this.rutaRepository.findByIds(ids);
  }
} 