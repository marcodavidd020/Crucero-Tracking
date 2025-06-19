import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketServer,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
})
export class SocketGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(SocketGateway.name);
  private readonly connectedClients = new Map<string, Socket>();

  afterInit(server: Server) {
    this.logger.log('💬 General WebSocket Gateway initialized');
  }

  handleConnection(client: Socket) {
    this.logger.log(`🔗 Client connected: ${client.id}`);
    this.connectedClients.set(client.id, client);

    // Notificar a otros usuarios que alguien se conectó
    client.broadcast.emit('userJoined', {
      userId: client.id,
      timestamp: new Date().toISOString(),
      message: 'Un usuario se ha conectado',
    });
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`❌ Client disconnected: ${client.id}`);
    this.connectedClients.delete(client.id);

    // Notificar a otros usuarios que alguien se desconectó
    client.broadcast.emit('userLeft', {
      userId: client.id,
      timestamp: new Date().toISOString(),
      message: 'Un usuario se ha desconectado',
    });
  }

  @SubscribeMessage('message')
  handleMessage(
    @MessageBody() data: { message: string; [key: string]: any },
    @ConnectedSocket() client: Socket,
  ) {
    this.logger.log(`📨 Message from ${client.id}: ${data.message}`);

    // Enviar mensaje a todos los clientes conectados
    this.server.emit('messageResponse', {
      ...data,
      userId: client.id,
      timestamp: new Date().toISOString(),
    });

    return {
      success: true,
      message: 'Mensaje enviado exitosamente',
      timestamp: new Date().toISOString(),
    };
  }

  @SubscribeMessage('joinRoom')
  handleJoinRoom(
    @MessageBody() room: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(room);
    this.logger.log(`🏠 Client ${client.id} joined room: ${room}`);

    // Notificar a la sala que alguien se unió
    client.to(room).emit('userJoined', {
      userId: client.id,
      room,
      timestamp: new Date().toISOString(),
      message: `Usuario se unió a la sala ${room}`,
    });

    return {
      success: true,
      message: `Te uniste a la sala ${room}`,
      room,
      timestamp: new Date().toISOString(),
    };
  }

  @SubscribeMessage('leaveRoom')
  handleLeaveRoom(
    @MessageBody() room: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.leave(room);
    this.logger.log(`🚪 Client ${client.id} left room: ${room}`);

    // Notificar a la sala que alguien se fue
    client.to(room).emit('userLeft', {
      userId: client.id,
      room,
      timestamp: new Date().toISOString(),
      message: `Usuario dejó la sala ${room}`,
    });

    return {
      success: true,
      message: `Saliste de la sala ${room}`,
      room,
      timestamp: new Date().toISOString(),
    };
  }

  @SubscribeMessage('roomMessage')
  handleRoomMessage(
    @MessageBody() data: { room: string; message: string; [key: string]: any },
    @ConnectedSocket() client: Socket,
  ) {
    this.logger.log(`📨 Room message from ${client.id} to room ${data.room}: ${data.message}`);

    // Enviar mensaje solo a los clientes en la sala específica
    this.server.to(data.room).emit('messageResponse', {
      ...data,
      userId: client.id,
      timestamp: new Date().toISOString(),
    });

    return {
      success: true,
      message: 'Mensaje enviado a la sala exitosamente',
      room: data.room,
      timestamp: new Date().toISOString(),
    };
  }

  // Método para obtener estadísticas de conexiones
  getConnectionStats() {
    return {
      totalConnections: this.connectedClients.size,
      connectedClients: Array.from(this.connectedClients.keys()),
    };
  }

  // Método para enviar mensaje desde el servidor
  sendServerMessage(message: string, room?: string) {
    const payload = {
      userId: 'server',
      message,
      timestamp: new Date().toISOString(),
      isServerMessage: true,
    };

    if (room) {
      this.server.to(room).emit('messageResponse', payload);
    } else {
      this.server.emit('messageResponse', payload);
    }
  }
} 