import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrackingLocation } from './entities/tracking-location.entity';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class TrackingService {
  private readonly logger = new Logger(TrackingService.name);

  constructor(
    @InjectRepository(TrackingLocation)
    private readonly trackingRepository: Repository<TrackingLocation>,
  ) {}

  async createLocation(updateLocationDto: UpdateLocationDto): Promise<TrackingLocation> {
    const trackingLocation = this.trackingRepository.create({
      idMicro: updateLocationDto.id_micro,
      latitud: updateLocationDto.latitud,
      longitud: updateLocationDto.longitud,
      altura: updateLocationDto.altura,
      precision: updateLocationDto.precision,
      bateria: updateLocationDto.bateria,
      imei: updateLocationDto.imei,
      fuente: updateLocationDto.fuente || 'app_flutter',
      idRuta: updateLocationDto.id_ruta,
    });

    const saved = await this.trackingRepository.save(trackingLocation);
    this.logger.log(`Nueva ubicación guardada para micro ${updateLocationDto.id_micro}`);
    
    return saved;
  }

  async getLocationsByMicro(idMicro: string, limit = 50): Promise<TrackingLocation[]> {
    return await this.trackingRepository.find({
      where: { idMicro },
      order: { createdAt: 'DESC' },
      take: limit,
      relations: ['ruta'],
    });
  }

  async getLocationsByRoute(idRuta: string, limit = 100): Promise<TrackingLocation[]> {
    return await this.trackingRepository.find({
      where: { idRuta },
      order: { createdAt: 'DESC' },
      take: limit,
      relations: ['ruta'],
    });
  }

  async getLatestLocationByMicro(idMicro: string): Promise<TrackingLocation | null> {
    return await this.trackingRepository.findOne({
      where: { idMicro },
      order: { createdAt: 'DESC' },
      relations: ['ruta'],
    });
  }

  async getActiveMicros(): Promise<{ idMicro: string; latestLocation: TrackingLocation }[]> {
    // Obtener micros que han enviado ubicación en los últimos 10 minutos
    const tenMinutesAgo = new Date();
    tenMinutesAgo.setMinutes(tenMinutesAgo.getMinutes() - 10);

    const activeLocations = await this.trackingRepository
      .createQueryBuilder('tracking')
      .distinctOn(['tracking.idMicro'])
      .where('tracking.createdAt > :tenMinutesAgo', { tenMinutesAgo })
      .orderBy('tracking.idMicro')
      .addOrderBy('tracking.createdAt', 'DESC')
      .leftJoinAndSelect('tracking.ruta', 'ruta')
      .getMany();

    return activeLocations.map(location => ({
      idMicro: location.idMicro,
      latestLocation: location,
    }));
  }

  async deleteOldLocations(daysOld = 30): Promise<number> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await this.trackingRepository
      .createQueryBuilder()
      .delete()
      .where('createdAt < :cutoffDate', { cutoffDate })
      .execute();

    this.logger.log(`Eliminadas ${result.affected} ubicaciones antiguas`);
    return result.affected || 0;
  }
} 