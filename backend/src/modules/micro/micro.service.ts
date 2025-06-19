import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Micro } from './entities/micro.entity';

@Injectable()
export class MicroService {
  constructor(
    @InjectRepository(Micro)
    private microRepository: Repository<Micro>,
  ) {}

  async findAll(): Promise<Micro[]> {
    return this.microRepository.find({
      relations: ['entidad', 'empleados']
    });
  }

  async findOne(id: string): Promise<Micro | null> {
    return this.microRepository.findOne({
      where: { id },
      relations: ['entidad', 'empleados']
    });
  }

  async findByEntidad(idEntidad: string): Promise<Micro[]> {
    return this.microRepository.find({
      where: { idEntidad },
      relations: ['entidad', 'empleados']
    });
  }

  async create(microData: Partial<Micro>): Promise<Micro> {
    const micro = this.microRepository.create(microData);
    return this.microRepository.save(micro);
  }

  async update(id: string, updateData: Partial<Micro>): Promise<Micro | null> {
    await this.microRepository.update(id, updateData);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.microRepository.delete(id);
  }
} 