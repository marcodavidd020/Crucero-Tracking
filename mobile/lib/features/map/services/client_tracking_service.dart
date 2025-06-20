import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../config/constants.dart';
import '../../../services/tracking_socket_service.dart';
import '../../auth/providers/auth_provider.dart';

class ClientTrackingService {
  final WidgetRef ref;
  TrackingSocketService? trackingService;
  bool _mounted = true;
  Timer? _connectionCheckTimer;
  final Map<String, Symbol> _microMarkers = {};
  String? _selectedRouteId;

  ClientTrackingService(this.ref);

  void dispose() {
    _mounted = false;
    _connectionCheckTimer?.cancel();
    trackingService?.dispose();
  }

  // ========== INICIALIZACIÓN ==========
  
  Future<void> initializeTracking() async {
    if (!_mounted) return;
    
    try {
      trackingService = TrackingSocketService();
      
      // Generar un ID único para el cliente
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final clientId = 'client-$timestamp';
      
      await trackingService!.initSocket(
        // 'http://54.82.231.172:3001',
        baseUrlSocket,
        clientId,
        'client-token-$timestamp',
        enableLocationTracking: false // Clientes NO envían ubicación
      );
      
      print('🔌 Inicializando socket para tracking...');
      print('📍 URL: http://54.82.231.172:3001');
      print('🚌 MicroId: $clientId');
      print('📡 Tracking activo: false (SOLO ESCUCHA)');
      
      // Monitorear conexión cada 30 segundos
      _startConnectionMonitoring();
      
    } catch (e) {
      print('❌ Error inicializando tracking: $e');
    }
  }

  void _startConnectionMonitoring() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_mounted) {
        timer.cancel();
        return;
      }
      
      if (trackingService?.isConnected != true) {
        print('🔄 Reconectando servicio de tracking...');
        _reconnectService();
      }
    });
  }

  Future<void> _reconnectService() async {
    if (!_mounted) return;
    
    try {
      await trackingService?.dispose();
      await initializeTracking();
    } catch (e) {
      print('❌ Error en reconexión: $e');
    }
  }

  // ========== GESTIÓN DE RUTAS ==========
  
  void joinRouteTracking(String routeId, BuildContext context) {
    if (!_mounted) return;
    
    if (trackingService?.isConnected == true) {
      trackingService!.joinRouteTracking(routeId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛣️ Siguiendo ruta en tiempo real'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('❌ No se puede unir a la ruta - socket no conectado');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Sin conexión al servidor'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void leaveRouteTracking(String routeId) {
    if (trackingService?.isConnected == true) {
      trackingService!.leaveRouteTracking(routeId);
      print('🚪 Dejó de seguir la ruta: $routeId');
    }
  }

  // ========== ACTUALIZACIÓN DE MARCADORES ==========
  
  Future<void> updateMicroLocationOnMap(
    MapLibreMapController controller, 
    Map<String, dynamic> locationData
  ) async {
    if (!_mounted) return;
    
    try {
      final microId = locationData['id_micro'];
      final lat = locationData['latitud']?.toDouble();
      final lng = locationData['longitud']?.toDouble();
      
      if (lat == null || lng == null) {
        print('⚠️ Datos de ubicación inválidos: $locationData');
        return;
      }
      
      print('🚌 Actualizando ubicación del micro $microId: $lat, $lng');
      
      // Remover marcador anterior si existe
      await _removePreviousMarker(controller, microId);
      
      // Agregar nuevo marcador
      await controller.addSymbol(SymbolOptions(
        geometry: LatLng(lat, lng),
        iconImage: 'bus-marker',
        iconSize: 0.8,
        textField: '🚌',
        textSize: 20,
        textColor: '#FFFFFF',
        textHaloColor: '#FF0000',
        textHaloWidth: 2,
        textOffset: const Offset(0, -2),
      ));
      
      print('✅ Marcador actualizado en el mapa');
      
    } catch (e) {
      print('❌ Error actualizando marcador: $e');
    }
  }

  Future<void> _removePreviousMarker(
    MapLibreMapController controller, 
    String microId
  ) async {
    try {
      // Obtener todos los símbolos y remover los del micro específico
      final symbols = await controller.symbols;
      for (final symbol in symbols) {
        if (symbol.options.textField?.contains('🚌') == true) {
          await controller.removeSymbol(symbol);
        }
      }
    } catch (e) {
      print('⚠️ Error removiendo marcador anterior: $e');
    }
  }

  // ========== GETTERS ==========
  
  bool get isConnected => trackingService?.isConnected ?? false;
  
  Stream<Map<String, dynamic>>? get locationUpdates => 
      trackingService?.on<Map<String, dynamic>>(TrackingEventType.routeLocationUpdate);
      
  Stream<bool>? get connectionStatus => 
      trackingService?.on<bool>(TrackingEventType.connectionStatusChanged);
} 