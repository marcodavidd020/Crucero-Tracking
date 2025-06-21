import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { EntidadOperadora } from '../../entidad-operadora/entities/entidad-operadora.entity';
import { Empleado } from '../../empleado/entities/empleado.entity';
import { TrackingLocation } from '../../tracking/entities/tracking-location.entity';

@Entity('micros')
export class Micro {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ name: 'id_entidad', type: 'varchar', length: 50 })
  idEntidad: string;

  @Column({ name: 'id_ruta', type: 'varchar', length: 50, nullable: true })
  idRuta: string;

  @Column({ type: 'varchar', length: 20 })
  placa: string;

  @Column({ type: 'varchar', length: 100 })
  modelo: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  color: string;

  @Column({ type: 'int', default: 30 })
  capacidad: number;

  @Column({ type: 'int', nullable: true })
  anio: number;

  @Column({ type: 'varchar', length: 100, nullable: true })
  imei: string;

  @Column({ type: 'boolean', default: true })
  activo: boolean;

  @Column({ type: 'boolean', default: true })
  estado: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relaciones
  @ManyToOne(() => EntidadOperadora, entidad => entidad.micros)
  @JoinColumn({ name: 'id_entidad' })
  entidad: EntidadOperadora;

  @OneToMany(() => Empleado, empleado => empleado.micro)
  empleados: Empleado[];

  @OneToMany(() => TrackingLocation, tracking => tracking.micro)
  trackingLocations: TrackingLocation[];
} 