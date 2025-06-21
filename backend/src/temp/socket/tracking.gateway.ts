import { ConnectedSocket, MessageBody, OnGatewayConnection, OnGatewayDisconnect, SubscribeMessage, WebSocketGateway, WebSocketServer } from "@nestjs/websockets";
import { Server, Socket } from 'socket.io';
import { Logger, Inject } from '@nestjs/common';
import { PrismaService } from "src/prisma/services";


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

    constructor(private prisma: PrismaService) {}

    async handleConnection(client: Socket): Promise<void> {
        const { id } = client;
        this.logger.log(`Cliente conectado: ${id}`);
        
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
        const micro = await this.prisma.micro.findUnique({
            where: { id: microId },
            select: { id_ruta: true },
        });
        
        client.join('tracking:all');
        
        if (micro?.id_ruta) {
            client.join(`tracking:route:${micro.id_ruta}`);
            this.logger.log(`Cliente ${id} asociado a ruta ${micro.id_ruta}`);
        }
        
        // Enviar los últimos datos de tracking de todos los micros al cliente recién conectado
        const latestTrackings = await this.prisma.tracking.findMany({
            distinct: ['id_micro'],
            orderBy: { updatedAt: 'desc' },
            where: {
            micro: {
                estado: true
            }
            },
            include: {
            micro: {
                select: {
                placa: true,
                color: true,
                id_ruta: true
                }
            }
            }
        });
        
        client.emit('initialTrackingData', latestTrackings);
        
        } catch (error) {
            this.logger.error(`Error en la conexión del cliente ${id}: ${error.message}`);
            client.disconnect();
        }
    }

    async handleDisconnect(client: Socket): Promise<void> {
        this.logger.log(`Cliente desconectado: ${client.id}`);
        
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
        const tracking = await this.prisma.tracking.create({
            data: {
            id_micro: data.id_micro,
            latitud: data.latitud,
            longitud: data.longitud,
            altura: data.altura,
            precision: data.precision,
            bateria: data.bateria,
            imei: data.imei,
            fuente: data.fuente,
            },
            include: {
            micro: {
                select: {
                placa: true,
                color: true,
                id_ruta: true
                }
            }
            }
        });
        
        // Emitir la actualización a todos los clientes en la sala general
        this.server.to('tracking:all').emit('locationUpdate', tracking);
        
        // Si el micro tiene una ruta asignada, emitir también a esa sala específica
        if (tracking.micro.id_ruta) {
            this.server.to(`tracking:route:${tracking.micro.id_ruta}`).emit('routeLocationUpdate', tracking);
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