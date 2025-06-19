import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Parada } from './entities/parada.entity';

@Injectable()
export class ParadaService {
  constructor(
    @InjectRepository(Parada)
    private paradaRepository: Repository<Parada>,
  ) {}

  async findAll(): Promise<Parada[]> {
    return this.paradaRepository.find({
      relations: ['ruta'],
      order: { orden: 'ASC' }
    });
  }

  async findOne(id: string): Promise<Parada | null> {
    return this.paradaRepository.findOne({
      where: { id },
      relations: ['ruta']
    });
  }

  async findByRuta(idRuta: string): Promise<Parada[]> {
    return this.paradaRepository.find({
      where: { idRuta },
      relations: ['ruta'],
      order: { orden: 'ASC' }
    });
  }

  async create(paradaData: Partial<Parada>): Promise<Parada> {
    const parada = this.paradaRepository.create(paradaData);
    return this.paradaRepository.save(parada);
  }

  async update(id: string, updateData: Partial<Parada>): Promise<Parada | null> {
    await this.paradaRepository.update(id, updateData);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.paradaRepository.delete(id);
  }
} 