import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne, JoinColumn, ManyToOne } from 'typeorm';
import { Usuario } from '../../usuario/entities/usuario.entity';
import { EntidadOperadora } from '../../entidad-operadora/entities/entidad-operadora.entity';
import { Micro } from '../../micro/entities/micro.entity';

export enum TipoEmpleado {
  CHOFER = 'CHOFER',
  ADMIN = 'ADMIN',
  SUPERVISOR = 'SUPERVISOR',
}

@Entity('empleados')
export class Empleado {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ name: 'user_id', type: 'varchar', length: 50 })
  userId: string;

  @Column({
    type: 'enum',
    enum: TipoEmpleado,
    default: TipoEmpleado.CHOFER,
  })
  tipo: TipoEmpleado;

  @Column({ name: 'id_entidad', type: 'varchar', length: 50 })
  idEntidad: string;

  @Column({ name: 'id_micro', type: 'varchar', length: 50, nullable: true })
  idMicro: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  licencia: string;

  @Column({ type: 'date', nullable: true })
  fechaContratacion: Date;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  salario: number;

  @Column({ type: 'boolean', default: true })
  activo: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relaciones
  @OneToOne(() => Usuario, usuario => usuario.empleado)
  @JoinColumn({ name: 'user_id' })
  usuario: Usuario;

  @ManyToOne(() => EntidadOperadora, entidad => entidad.empleados)
  @JoinColumn({ name: 'id_entidad' })
  entidad: EntidadOperadora;

  @ManyToOne(() => Micro, micro => micro.empleados, { nullable: true })
  @JoinColumn({ name: 'id_micro' })
  micro: Micro;
} 