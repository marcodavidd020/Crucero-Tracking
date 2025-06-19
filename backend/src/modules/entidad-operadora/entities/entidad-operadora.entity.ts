import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { Ruta } from '../../ruta/entities/ruta.entity';
import { Empleado } from '../../empleado/entities/empleado.entity';
import { Micro } from '../../micro/entities/micro.entity';

@Entity('entidades_operadoras')
export class EntidadOperadora {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ type: 'varchar', length: 200 })
  nombre: string;

  @Column({ type: 'varchar', length: 20, unique: true })
  nit: string;

  @Column({ type: 'varchar', length: 200, nullable: true })
  direccion: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  telefono: string;

  @Column({ type: 'varchar', length: 200, nullable: true })
  email: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  representante: string;

  @Column({ type: 'boolean', default: true })
  activo: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relaciones
  @OneToMany(() => Ruta, ruta => ruta.entidad)
  rutas: Ruta[];

  @OneToMany(() => Empleado, empleado => empleado.entidad)
  empleados: Empleado[];

  @OneToMany(() => Micro, micro => micro.entidad)
  micros: Micro[];
} 