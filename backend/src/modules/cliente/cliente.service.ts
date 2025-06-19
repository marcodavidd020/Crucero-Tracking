import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Cliente } from './entities/cliente.entity';

@Injectable()
export class ClienteService {
  constructor(
    @InjectRepository(Cliente)
    private clienteRepository: Repository<Cliente>,
  ) {}

  async findAll(): Promise<Cliente[]> {
    return this.clienteRepository.find({
      relations: ['usuario']
    });
  }

  async findOne(id: string): Promise<Cliente | null> {
    return this.clienteRepository.findOne({
      where: { id },
      relations: ['usuario']
    });
  }

  async findByUserId(userId: string): Promise<Cliente | null> {
    return this.clienteRepository.findOne({
      where: { userId },
      relations: ['usuario']
    });
  }

  async update(id: string, updateData: Partial<Cliente>): Promise<Cliente | null> {
    await this.clienteRepository.update(id, updateData);
    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.clienteRepository.delete(id);
  }
} 