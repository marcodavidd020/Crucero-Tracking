import { Logger } from "@nestjs/common";
import { ConnectedSocket, MessageBody, OnGatewayConnection, OnGatewayDisconnect, SubscribeMessage, WebSocketGateway, WebSocketServer } from "@nestjs/websockets";
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
    cors:{
        origin: "*",
    }
})
export class SocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer() server: Server;
    private readonly  logger = new Logger(SocketGateway.name);
    private clientRouteMap = new Map<string, string>(); // socketId -> routeId

    handleConnection(client: Socket): void {
        const {id} = client;
        this.logger.log(`Cliente conectado al namespace principal: ${id}`);

        const token = client.handshake.auth.token;
        const clientType = client.handshake.auth.type || 'unknown';
        
        if (!token) {
            this.logger.warn(`Cliente ${id} sin token, permitiendo conexión para clientes`);
        }
        
        this.logger.log(`Cliente ${id} tipo: ${clientType}`);
    }

    handleDisconnect(client: Socket): void {
        this.logger.log(`Cliente desconectado del namespace principal: ${client.id}`);
        
        // Limpiar mapeo de ruta si existe
        const routeId = this.clientRouteMap.get(client.id);
        if (routeId) {
            this.clientRouteMap.delete(client.id);
            this.logger.log(`Cliente ${client.id} removido de ruta ${routeId}`);
        }
    }

    @SubscribeMessage('message')
    handleMessage(@ConnectedSocket() client: Socket, @MessageBody() payload: any): void {
        this.logger.log(`Mensaje recibido de ${client.id}: ${JSON.stringify(payload)}`);
        // Emitir el mensaje a todos los clientes conectados
        this.server.emit('messageResponse', {
            message: payload.message,
            senderId: client.id,
            timestamp: new Date()
        });
    }

    @SubscribeMessage('joinRoom')
    handleJoinRoom(@ConnectedSocket() client: Socket, @MessageBody() room: string ): void {
        client.join(room);
        this.logger.log(`Cliente ${client.id} se unió a la sala: ${room}`);

        client.to(room).emit('userJoined', {
            userId: client.id,
            room
        });
    }

    @SubscribeMessage('leaveRoom')
    handleLeaveRoom(@ConnectedSocket() client: Socket, @MessageBody() room: string ): void {
        client.leave(room);
        this.logger.log(`Cliente ${client.id} salió de la sala: ${room}`);

        client.to(room).emit('userLeft', {
            userId: client.id,
            room
        });
    }

    // NUEVO: Permitir que clientes se unan al tracking de rutas específicas
    @SubscribeMessage('joinRouteTracking')
    handleJoinRouteTracking(@ConnectedSocket() client: Socket, @MessageBody() routeId: string): void {
        // Salir de ruta anterior si existe
        const previousRoute = this.clientRouteMap.get(client.id);
        if (previousRoute) {
            client.leave(`client:route:${previousRoute}`);
        }
        
        // Unirse a nueva ruta
        client.join(`client:route:${routeId}`);
        this.clientRouteMap.set(client.id, routeId);
        
        this.logger.log(`Cliente ${client.id} ahora escucha ruta: ${routeId}`);
        
        // Confirmar al cliente
        client.emit('joinedRouteTracking', {
            routeId,
            timestamp: new Date().toISOString(),
            message: `Conectado al tracking de ruta ${routeId}`
        });
    }

    @SubscribeMessage('leaveRouteTracking')
    handleLeaveRouteTracking(@ConnectedSocket() client: Socket, @MessageBody() routeId: string): void {
        client.leave(`client:route:${routeId}`);
        this.clientRouteMap.delete(client.id);
        
        this.logger.log(`Cliente ${client.id} dejó de escuchar ruta: ${routeId}`);
        
        client.emit('leftRouteTracking', {
            routeId,
            timestamp: new Date().toISOString(),
            message: `Desconectado del tracking de ruta ${routeId}`
        });
    }

    // NUEVO: Método para redistribuir actualizaciones de tracking a clientes
    redistributeLocationUpdate(routeId: string, locationData: any): void {
        this.server.to(`client:route:${routeId}`).emit('routeLocationUpdate', locationData);
        this.logger.log(`Redistribuida actualización de ruta ${routeId} a clientes`);
    }

    emitToRoom(room: string, event: string, data: any): void {
        this.logger.log(`Emitiendo a la sala ${room}: ${event} - ${JSON.stringify(data)}`);
        this.server.to(room).emit(event, data);
    }

} 