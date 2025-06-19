import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Empleado } from './entities/empleado.entity';

@Injectable()
export class EmpleadoService {
  constructor(
    @InjectRepository(Empleado)
    private empleadoRepository: Repository<Empleado>,
  ) {}

  async findAll(): Promise<Empleado[]> {
    return this.empleadoRepository.find({
      relations: ['usuario', 'entidad', 'micro']
    });
  }

  async findOne(id: string): Promise<Empleado | null> {
    return this.empleadoRepository.findOne({
      where: { id },
      relations: ['usuario', 'entidad', 'micro']
    });
  }

  async findByUserId(userId: string): Promise<Empleado | null> {
    return this.empleadoRepository.findOne({
      where: { userId },
      relations: ['usuario', 'entidad', 'micro']
    });
  }

  async findByEntidad(idEntidad: string): Promise<Empleado[]> {
    return this.empleadoRepository.find({
      where: { idEntidad },
      relations: ['usuario', 'entidad', 'micro']
    });
  }

  async create(empleadoData: Partial<Empleado>): Promise<Empleado> {
    const empleado = this.empleadoRepository.create(empleadoData);
    return this.empleadoRepository.save(empleado);
  }

  async update(id: string, updateData: Partial<Empleado>): Promise<Empleado | null> {
    await this.empleadoRepository.update(id, updateData);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.empleadoRepository.delete(id);
  }
} 