import { ConnectedSocket, MessageBody, OnGatewayConnection, OnGatewayDisconnect, SubscribeMessage, WebSocketGateway, WebSocketServer } from "@nestjs/websockets";
import { Server, Socket } from 'socket.io';
import { Logger, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrackingLocation } from '../tracking/entities/tracking-location.entity';
import { Micro } from '../micro/entities/micro.entity';
import { SocketGateway } from './socket.gateway';

interface TrackingData {
    id_micro: string;
    latitud: number;
    longitud: number;
    altura: number;
    precision: number;
    bateria: number;
    imei: string;
    fuente: string;
}

@WebSocketGateway({
    cors:{
        origin: "*",
    },
    namespace: "tracking",
})
export class TrackingGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer() server: Server;
    private readonly logger = new Logger(TrackingGateway.name);
    private userMicroMap = new Map<string, string>(); // socketId -> microId

    constructor(
        @InjectRepository(TrackingLocation)
        private readonly trackingRepository: Repository<TrackingLocation>,
        @InjectRepository(Micro)
        private readonly microRepository: Repository<Micro>,
        @Inject(forwardRef(() => SocketGateway))
        private readonly socketGateway: SocketGateway,
    ) {}

    async handleConnection(client: Socket): Promise<void> {
        const { id } = client;
        this.logger.log(`Cliente conectado al namespace tracking: ${id}`);
        
        // Autenticación con token
        const token = client.handshake.auth.token;
        const microId = client.handshake.auth.microId;
        
        if (!token || !microId) {
            this.logger.error(`Cliente ${id} rechazado: falta token o microId`);
            client.disconnect();
            return;
        }
        
        try {
            // Aquí puedes agregar verificación del token
            
            // Almacenar la asociación del socket con el micro
            this.userMicroMap.set(client.id, microId);
            
            // Unir al cliente a la sala general y a la sala específica de su ruta
            const micro = await this.microRepository.findOne({
                where: { id: microId },
                select: ['idRuta'],
            });
            
            client.join('tracking:all');
            
            if (micro?.idRuta) {
                client.join(`tracking:route:${micro.idRuta}`);
                this.logger.log(`Cliente ${id} asociado a ruta ${micro.idRuta}`);
            }
            
            // Enviar los últimos datos de tracking de todos los micros al cliente recién conectado
            const latestTrackings = await this.trackingRepository
                .createQueryBuilder('tracking')
                .leftJoinAndSelect('tracking.micro', 'micro')
                .where('micro.estado = :estado', { estado: true })
                .distinctOn(['tracking.idMicro'])
                .orderBy('tracking.idMicro')
                .addOrderBy('tracking.updatedAt', 'DESC')
                .getMany();
            
            client.emit('initialTrackingData', latestTrackings);
            
        } catch (error) {
            this.logger.error(`Error en la conexión del cliente ${id}: ${error.message}`);
            client.disconnect();
        }
    }

    async handleDisconnect(client: Socket): Promise<void> {
        this.logger.log(`Cliente desconectado del tracking: ${client.id}`);
        
        // Obtener el microId asociado a este socket
        const microId = this.userMicroMap.get(client.id);
        if (microId) {
            // Actualizar el estado de conexión o marcar la última ubicación como "final"
            // Esta lógica depende de tus necesidades específicas
            this.logger.log(`Actualizando último estado conocido para micro ${microId}`);
            
            // Eliminar la asociación
            this.userMicroMap.delete(client.id);
        }
    }

    @SubscribeMessage('updateLocation')
    async handleLocationUpdate(
        @ConnectedSocket() client: Socket, 
        @MessageBody() data: TrackingData
    ): Promise<void> {
        const microId = this.userMicroMap.get(client.id);
        
        if (!microId || microId !== data.id_micro) {
            this.logger.warn(`ID de micro no coincidente o no autorizado: ${data.id_micro}`);
            return;
        }
        
        try {
            // Guardar en la base de datos
            const tracking = this.trackingRepository.create({
                idMicro: data.id_micro,
                latitud: data.latitud,
                longitud: data.longitud,
                altura: data.altura,
                precision: data.precision,
                bateria: data.bateria,
                imei: data.imei,
                fuente: data.fuente,
            });
            
            const savedTracking = await this.trackingRepository.save(tracking);
            
            // Obtener información del micro
            const micro = await this.microRepository.findOne({
                where: { id: data.id_micro },
                select: ['placa', 'color', 'idRuta'],
            });
            
            const trackingWithMicro = {
                ...savedTracking,
                micro: {
                    placa: micro?.placa,
                    color: micro?.color,
                    id_ruta: micro?.idRuta,
                }
            };
            
            // Emitir la actualización a todos los clientes en la sala general del tracking
            this.server.to('tracking:all').emit('locationUpdate', trackingWithMicro);
            
            // Si el micro tiene una ruta asignada, emitir también a esa sala específica
            if (micro?.idRuta) {
                this.server.to(`tracking:route:${micro.idRuta}`).emit('routeLocationUpdate', trackingWithMicro);
                
                // CRÍTICO: Redistribuir a clientes conectados al namespace principal
                this.socketGateway.redistributeLocationUpdate(micro.idRuta, trackingWithMicro);
            }
            
        } catch (error) {
            this.logger.error(`Error al procesar actualización de ubicación: ${error.message}`);
        }
    }

    @SubscribeMessage('joinRoute')
    handleJoinRoute(@ConnectedSocket() client: Socket, @MessageBody() routeId: string): void {
        client.join(`tracking:route:${routeId}`);
        this.logger.log(`Cliente ${client.id} se unió a la sala de la ruta: ${routeId}`);
    }

    @SubscribeMessage('leaveRoute')
    handleLeaveRoute(@ConnectedSocket() client: Socket, @MessageBody() routeId: string): void {
        client.leave(`tracking:route:${routeId}`);
        this.logger.log(`Cliente ${client.id} dejó la sala de la ruta: ${routeId}`);
    }
} 