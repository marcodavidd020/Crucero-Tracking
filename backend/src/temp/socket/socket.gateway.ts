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

    handleConnection(client: Socket): void {
        const {id} = client;
        this.logger.log(`Cliente conectado: ${id}`);

        const token = client.handshake.auth.token;
        if (!token) {
            // Autenticar usuario y asignar a una sala específica
            // client.join(`user_${userId}`);
        }
    }

    handleDisconnect(client: Socket): void {
        this.logger.log(`Cliente desconectado: ${client.id}`);
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

    emitToRoom(room: string, event: string, data: any): void {
        this.logger.log(`Emitiendo a la sala ${room}: ${event} - ${JSON.stringify(data)}`);
        this.server.to(room).emit(event, data);
    }

}