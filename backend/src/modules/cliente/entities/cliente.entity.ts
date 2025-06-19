import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne, JoinColumn } from 'typeorm';
import { Usuario } from '../../usuario/entities/usuario.entity';

@Entity('clientes')
export class Cliente {
  @PrimaryColumn({ type: 'varchar', length: 50 })
  id: string;

  @Column({ name: 'user_id', type: 'varchar', length: 50 })
  userId: string;

  @Column({ name: 'wallet_address', type: 'varchar', length: 100, nullable: true })
  walletAddress: string;

  @Column({ type: 'json', nullable: true })
  registros: any[];

  @Column({ type: 'json', nullable: true })
  notificaciones: any[];

  @Column({ type: 'json', nullable: true })
  tarjetas: any[];

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  saldo: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Relaciones
  @OneToOne(() => Usuario, usuario => usuario.cliente)
  @JoinColumn({ name: 'user_id' })
  usuario: Usuario;
} 