import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Ruta } from '../../ruta/entities/ruta.entity';

@Entity('tracking_locations')
@Index(['idMicro', 'createdAt'])
export class TrackingLocation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'id_micro', type: 'varchar', length: 100 })
  idMicro: string;

  @Column({ name: 'id_ruta', type: 'varchar', length: 50, nullable: true })
  idRuta: string;

  @Column({ type: 'decimal', precision: 10, scale: 8 })
  latitud: number;

  @Column({ type: 'decimal', precision: 11, scale: 8 })
  longitud: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  altura: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  precision: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  bateria: number;

  @Column({ type: 'varchar', length: 100, nullable: true })
  imei: string;

  @Column({ type: 'varchar', length: 50, default: 'app_flutter' })
  fuente: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // Relaciones
  @ManyToOne(() => Ruta, ruta => ruta.trackingLocations, { nullable: true })
  @JoinColumn({ name: 'id_ruta' })
  ruta: Ruta;
} 