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
import { Logger, UseGuards } from '@nestjs/common';
import { TrackingService } from './tracking.service';
import { UpdateLocationDto } from './dto/update-location.dto';

@WebSocketGateway({
  namespace: '/tracking',
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
})
export class TrackingGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(TrackingGateway.name);
  private readonly connectedClients = new Map<string, { socket: Socket; microId?: string; routeId?: string }>();

  constructor(private readonly trackingService: TrackingService) {}

  afterInit(server: Server) {
    this.logger.log('🔌 Tracking WebSocket Gateway initialized');
  }

  async handleConnection(client: Socket) {
    const microId = client.handshake.auth?.microId;
    const token = client.handshake.auth?.token;

    this.logger.log(`🔗 Client connected to tracking: ${client.id}, microId: ${microId}`);

    // Almacenar información del cliente
    this.connectedClients.set(client.id, { socket: client, microId });

    // Enviar datos iniciales si es necesario
    if (microId) {
      const latestLocation = await this.trackingService.getLatestLocationByMicro(microId);
      if (latestLocation) {
        client.emit('initialTrackingData', {
          microId,
          latestLocation,
          message: 'Datos iniciales de tracking',
        });
      }
    }

    // Notificar estado de conexión
    client.emit('connectionStatusChanged', { connected: true, microId });
  }

  handleDisconnect(client: Socket) {
    const clientInfo = this.connectedClients.get(client.id);
    this.logger.log(`❌ Client disconnected from tracking: ${client.id}, microId: ${clientInfo?.microId}`);

    // Salir de la sala de ruta si estaba en una
    if (clientInfo?.routeId) {
      client.leave(`route_${clientInfo.routeId}`);
    }

    this.connectedClients.delete(client.id);
  }

  @SubscribeMessage('updateLocation')
  async handleLocationUpdate(
    @MessageBody() data: UpdateLocationDto,
    @ConnectedSocket() client: Socket,
  ) {
    try {
      // Guardar la ubicación en la base de datos
      const savedLocation = await this.trackingService.createLocation(data);

      // Actualizar información del cliente
      const clientInfo = this.connectedClients.get(client.id);
      if (clientInfo) {
        clientInfo.microId = data.id_micro;
        this.connectedClients.set(client.id, clientInfo);
      }

      // Emitir a todos los clientes la nueva ubicación
      this.server.emit('locationUpdate', {
        microId: data.id_micro,
        location: savedLocation,
        timestamp: new Date().toISOString(),
      });

      // Si está en una ruta específica, emitir a esa sala
      if (data.id_ruta) {
        this.server.to(`route_${data.id_ruta}`).emit('routeLocationUpdate', {
          routeId: data.id_ruta,
          microId: data.id_micro,
          location: savedLocation,
          timestamp: new Date().toISOString(),
        });
      }

      this.logger.debug(`📍 Location updated for micro ${data.id_micro}: ${data.latitud}, ${data.longitud}`);

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
      // Salir de la sala anterior si estaba en una
      const clientInfo = this.connectedClients.get(client.id);
      if (clientInfo?.routeId) {
        client.leave(`route_${clientInfo.routeId}`);
      }

      // Unirse a la nueva sala de ruta
      client.join(`route_${routeId}`);

      // Actualizar información del cliente
      if (clientInfo) {
        clientInfo.routeId = routeId;
        this.connectedClients.set(client.id, clientInfo);
      }

      // Obtener ubicaciones recientes de la ruta
      const recentLocations = await this.trackingService.getLocationsByRoute(routeId, 10);

      client.emit('joinedRoute', {
        routeId,
        message: `Unido a la ruta ${routeId}`,
        recentLocations,
      });

      this.logger.log(`🛣️ Client ${client.id} joined route ${routeId}`);

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
      client.leave(`route_${routeId}`);

      // Actualizar información del cliente
      const clientInfo = this.connectedClients.get(client.id);
      if (clientInfo) {
        clientInfo.routeId = undefined;
        this.connectedClients.set(client.id, clientInfo);
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

  // Método para obtener estadísticas de conexiones
  getConnectionStats() {
    const totalConnections = this.connectedClients.size;
    const activeMicros = new Set();
    const routeConnections = new Map<string, number>();

    this.connectedClients.forEach((clientInfo) => {
      if (clientInfo.microId) {
        activeMicros.add(clientInfo.microId);
      }
      if (clientInfo.routeId) {
        const count = routeConnections.get(clientInfo.routeId) || 0;
        routeConnections.set(clientInfo.routeId, count + 1);
      }
    });

    return {
      totalConnections,
      activeMicros: activeMicros.size,
      routeConnections: Object.fromEntries(routeConnections),
    };
  }
} 