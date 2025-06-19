import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne } from 'typeorm';
import { Cliente } from '../../cliente/entities/cliente.entity';
import { Empleado } from '../../empleado/entities/empleado.entity';

export enum TipoUsuario {
  CLIENTE = 'CLIENTE',
  EMPLEADO = 'EMPLEADO',
  ADMIN = 'ADMIN',
}

@Entity('usuarios')
export class Usuario {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 200 })
  nombre: string;

  @Column({ type: 'varchar', length: 200, unique: true })
  correo: string;

  @Column({ type: 'varchar', length: 255 })
  contrasena: string;

  @Column({
    type: 'enum',
    enum: TipoUsuario,
    default: TipoUsuario.CLIENTE,
  })
  tipo: TipoUsuario;

  @Column({ type: 'boolean', default: true })
  activo: boolean;

  @Column({ type: 'timestamp', nullable: true })
  ultimoLogin: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relaciones
  @OneToOne(() => Cliente, cliente => cliente.usuario, { cascade: true })
  cliente: Cliente;

  @OneToOne(() => Empleado, empleado => empleado.usuario, { cascade: true })
  empleado: Empleado;
} 