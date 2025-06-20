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
import { TrackingService } from '../tracking/tracking.service';

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
  private readonly trackingClients = new Map<string, { socket: Socket; microId?: string; routeId?: string }>();

  constructor(private readonly trackingService: TrackingService) {}

  afterInit(server: Server) {
    this.logger.log('💬 General WebSocket Gateway initialized');
    this.logger.log('🔌 Tracking functionality integrated');
  }

  handleConnection(client: Socket) {
    this.logger.log(`🔗 Client connected: ${client.id}`);
    this.connectedClients.set(client.id, client);

    const microId = client.handshake.auth?.microId;
    const clientType = client.handshake.auth?.type;
    
    if (microId) {
      this.logger.log(`🚌 Tracking client connected - ID: ${client.id}, MicroId: ${microId}, Type: ${clientType}`);
      this.trackingClients.set(client.id, { socket: client, microId });
    }

    client.broadcast.emit('userJoined', {
      userId: client.id,
      timestamp: new Date().toISOString(),
      message: 'Un usuario se ha conectado',
    });
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`❌ Client disconnected: ${client.id}`);
    this.connectedClients.delete(client.id);

    const trackingClient = this.trackingClients.get(client.id);
    if (trackingClient?.routeId) {
      client.leave(`route_${trackingClient.routeId}`);
    }
    this.trackingClients.delete(client.id);

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

  getConnectionStats() {
    return {
      totalConnections: this.connectedClients.size,
      connectedClients: Array.from(this.connectedClients.keys()),
    };
  }

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

  @SubscribeMessage('updateLocation')
  async handleLocationUpdate(
    @MessageBody() data: any,
    @ConnectedSocket() client: Socket,
  ) {
    try {
      this.logger.log(`📍 Location update from client ${client.id}: ${data.latitud}, ${data.longitud}, Route: ${data.id_ruta}`);

      const savedLocation = await this.trackingService.createLocation(data);

      const clientInfo = this.trackingClients.get(client.id);
      if (clientInfo) {
        clientInfo.microId = data.id_micro;
        this.trackingClients.set(client.id, clientInfo);
      }

      this.server.emit('locationUpdate', {
        microId: data.id_micro,
        location: savedLocation,
        timestamp: new Date().toISOString(),
      });

      if (data.id_ruta) {
        const routeRoomName = `route_${data.id_ruta}`;
        this.logger.log(`📡 Emitiendo routeLocationUpdate a sala: ${routeRoomName}`);
        
        this.server.to(routeRoomName).emit('routeLocationUpdate', {
          routeId: data.id_ruta,
          microId: data.id_micro,
          location: savedLocation,
          timestamp: new Date().toISOString(),
        });
        
        this.logger.log(`✅ routeLocationUpdate emitido para ruta ${data.id_ruta} a ${this.server.sockets.adapter.rooms.get(routeRoomName)?.size || 0} clientes`);
      }

      this.logger.log(`📍 Location updated for micro ${data.id_micro}: ${data.latitud}, ${data.longitud}`);

    } catch (error) {
      this.logger.error(`Error updating location for micro ${data.id_micro}:`, error);
      client.emit('error', {
        message: 'Error al actualizar ubicación',
        error: error.message,
      });
    }
  }

  @SubscribeMessage('joinRoute')
  async handleJoinRoute(
    @MessageBody() routeId: string,
    @ConnectedSocket() client: Socket,
  ) {
    try {
      this.logger.log(`🛣️ Client ${client.id} joining route: ${routeId}`);

      const clientInfo = this.trackingClients.get(client.id);
      if (clientInfo?.routeId) {
        const oldRoomName = `route_${clientInfo.routeId}`;
        client.leave(oldRoomName);
        this.logger.log(`🚪 Client ${client.id} left previous route room: ${oldRoomName}`);
      }

      const newRoomName = `route_${routeId}`;
      client.join(newRoomName);
      this.logger.log(`✅ Client ${client.id} joined route room: ${newRoomName}`);

      if (clientInfo) {
        clientInfo.routeId = routeId;
        this.trackingClients.set(client.id, clientInfo);
      } else {
        this.trackingClients.set(client.id, { socket: client, routeId });
      }

      const recentLocations = await this.trackingService.getLocationsByRoute(routeId, 10);

      client.emit('joinedRoute', {
        routeId,
        message: `Unido a la ruta ${routeId}`,
        recentLocations,
      });

      const roomSize = this.server.sockets.adapter.rooms.get(newRoomName)?.size || 0;
      this.logger.log(`🛣️ Client ${client.id} joined route ${routeId} - Room size: ${roomSize}`);

    } catch (error) {
      this.logger.error(`Error joining route ${routeId}:`, error);
      client.emit('error', {
        message: 'Error al unirse a la ruta',
        error: error.message,
      });
    }
  }

  @SubscribeMessage('leaveRoute')
  async handleLeaveRoute(
    @MessageBody() routeId: string,
    @ConnectedSocket() client: Socket,
  ) {
    try {
      const roomName = `route_${routeId}`;
      client.leave(roomName);

      const clientInfo = this.trackingClients.get(client.id);
      if (clientInfo) {
        clientInfo.routeId = undefined;
        this.trackingClients.set(client.id, clientInfo);
      }

      client.emit('leftRoute', {
        routeId,
        message: `Saliste de la ruta ${routeId}`,
      });

      this.logger.log(`🚪 Client ${client.id} left route ${routeId}`);

    } catch (error) {
      this.logger.error(`Error leaving route ${routeId}:`, error);
    }
  }
} 