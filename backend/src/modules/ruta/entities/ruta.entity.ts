import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { EntidadOperadora } from '../../entidad-operadora/entities/entidad-operadora.entity';
import { TrackingLocation } from '../../tracking/entities/tracking-location.entity';
import { Parada } from '../../parada/entities/parada.entity';

@Entity('rutas')
export class Ruta {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ name: 'id_entidad', type: 'varchar', length: 50 })
  idEntidad: string;

  @Column({ type: 'varchar', length: 200 })
  nombre: string;

  @Column({ type: 'text', nullable: true })
  descripcion: string;

  @Column({ name: 'origen_lat', type: 'decimal', precision: 10, scale: 8 })
  origenLat: number;

  @Column({ name: 'origen_long', type: 'decimal', precision: 11, scale: 8 })
  origenLong: number;

  @Column({ name: 'destino_lat', type: 'decimal', precision: 10, scale: 8 })
  destinoLat: number;

  @Column({ name: 'destino_long', type: 'decimal', precision: 11, scale: 8 })
  destinoLong: number;

  @Column({ type: 'text' })
  vertices: string; // JSON string con coordenadas

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  distancia: number; // En kilómetros

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  tiempo: number; // En minutos

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relaciones
  @ManyToOne(() => EntidadOperadora, entidad => entidad.rutas)
  @JoinColumn({ name: 'id_entidad' })
  entidad: EntidadOperadora;

  @OneToMany(() => TrackingLocation, tracking => tracking.ruta)
  trackingLocations: TrackingLocation[];

  @OneToMany(() => Parada, parada => parada.ruta)
  paradas: Parada[];

  // Método para transformar al formato esperado por el móvil
  toJSON() {
    return {
      id: this.id,
      id_entidad: this.idEntidad,
      nombre: this.nombre,
      descripcion: this.descripcion,
      origenLat: this.origenLat.toString(),
      origenLong: this.origenLong.toString(),
      destinoLat: this.destinoLat.toString(),
      destinoLong: this.destinoLong.toString(),
      vertices: this.vertices,
      distancia: this.distancia,
      tiempo: this.tiempo,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      ...(this.entidad && { entidad: this.entidad }),
      ...(this.paradas && { paradas: this.paradas })
    };
  }
} 