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
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionSubscription;

  ClientTrackingService(this.ref);

  void dispose() {
    _mounted = false;
    _connectionCheckTimer?.cancel();
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
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
      
      print('🔌 Cliente inicializando socket...');
      print('📍 URL: $baseUrlSocket');
      print('🚌 ClientId: $clientId');
      print('📡 Modo: SOLO ESCUCHA (cliente)');
      
      // CRÍTICO: Usar el mismo socket que los choferes, pero sin tracking de ubicación
      await trackingService!.initSocket(
        baseUrlSocket,
        clientId,
        'client-token-$timestamp',
        enableLocationTracking: false // Clientes NO envían ubicación
      );
      
      // Configurar listeners después de la inicialización
      _setupSocketListeners();
      
      // Monitorear conexión cada 30 segundos
      _startConnectionMonitoring();
      
      print('✅ Socket cliente inicializado correctamente');
      
    } catch (e) {
      print('❌ Error inicializando tracking cliente: $e');
    }
  }

  void _setupSocketListeners() {
    if (trackingService == null) return;
    
    // Escuchar actualizaciones de ubicación de rutas específicas
    _locationSubscription = trackingService!
        .on<Map<String, dynamic>>(TrackingEventType.routeLocationUpdate)
        .listen(
          (data) {
            print('📍 CLIENTE recibió actualización de ruta: $data');
            _handleRouteLocationUpdate(data);
          },
          onError: (error) {
            print('❌ Error en stream de ubicaciones de ruta: $error');
          },
          onDone: () {
            print('⚠️ Stream de ubicaciones de ruta cerrado');
          },
        );

    // Escuchar cambios de estado de conexión
    _connectionSubscription = trackingService!
        .on<bool>(TrackingEventType.connectionStatusChanged)
        .listen(
          (isConnected) {
            print('🔌 Estado de conexión cambió: $isConnected');
            if (isConnected && _selectedRouteId != null) {
              // Reconectar a la ruta si estábamos escuchando una
              Future.delayed(const Duration(seconds: 1), () {
                if (_mounted && trackingService?.isConnected == true) {
                  trackingService!.joinRouteTracking(_selectedRouteId!);
                  print('🔄 Reconectado a la ruta: $_selectedRouteId');
                }
              });
            }
          },
        );
  }

  void _handleRouteLocationUpdate(Map<String, dynamic> data) {
    // Procesar la actualización de ubicación aquí
    // Este método será llamado por el ClientRouteManager
    print('📍 Procesando actualización de ubicación para el mapa...');
    print('   🚌 Micro: ${data['microId']}');
    print('   🛣️ Ruta: ${data['routeId']}');
    print('   📍 Ubicación: ${data['location']}');
  }

  void _startConnectionMonitoring() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_mounted) {
        timer.cancel();
        return;
      }
      
      if (trackingService?.isConnected != true) {
        print('🔄 Reconectando servicio de tracking cliente...');
        _reconnectService();
      }
    });
  }

  Future<void> _reconnectService() async {
    if (!_mounted) return;
    
    try {
      // No dispose completo, solo reconectar
      await initializeTracking();
      
      // Reunirse a la ruta si teníamos una seleccionada
      if (_selectedRouteId != null) {
        await Future.delayed(const Duration(seconds: 2));
        if (trackingService?.isConnected == true) {
          trackingService!.joinRouteTracking(_selectedRouteId!);
        }
      }
    } catch (e) {
      print('❌ Error en reconexión cliente: $e');
    }
  }

  // ========== GESTIÓN DE RUTAS ==========
  
  void joinRouteTracking(String routeId, BuildContext context) {
    if (!_mounted) return;
    
    _selectedRouteId = routeId;
    
    if (trackingService?.isConnected == true) {
      print('🛣️ Cliente uniéndose a ruta: $routeId');
      trackingService!.joinRouteTracking(routeId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛣️ Siguiendo micros de la ruta en tiempo real'),
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
            content: Text('⚠️ Sin conexión al servidor de tracking'),
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
      print('🚪 Cliente dejó de seguir la ruta: $routeId');
    }
    _selectedRouteId = null;
  }

  // ========== GETTERS ==========
  
  bool get isConnected => trackingService?.isConnected ?? false;
  
  Stream<Map<String, dynamic>>? get locationUpdates {
    return trackingService?.on<Map<String, dynamic>>(TrackingEventType.routeLocationUpdate);
  }
  
  Stream<bool>? get connectionStatus {
    return trackingService?.on<bool>(TrackingEventType.connectionStatusChanged);
  }

  // ========== ACTUALIZACIÓN DE MARCADORES ==========
  
  Future<void> updateMicroLocationOnMap(
    MapLibreMapController controller, 
    Map<String, dynamic> locationData
  ) async {
    try {
      if (!_mounted) return;
      
      final microId = locationData['microId']?.toString();
      final location = locationData['location'];
      
      if (microId == null || location == null) {
        print('⚠️ Datos de ubicación incompletos: microId=$microId, location=$location');
        return;
      }
      
      final lat = location['latitud']?.toDouble();
      final lng = location['longitud']?.toDouble();
      
      if (lat == null || lng == null) {
        print('⚠️ Coordenadas inválidas: lat=$lat, lng=$lng');
        return;
      }
      
      print('📍 Actualizando marcador en mapa: $microId -> ($lat, $lng)');
      
      // Crear el marcador del micro
      final microSymbol = Symbol(
        microId,
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: 'bus-marker',
          iconSize: 0.8,
          textField: 'Micro $microId',
          textSize: 12,
          textColor: '#000000',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
          textOffset: const Offset(0, 2),
        ),
      );
      
      // Remover marcador anterior si existe
      if (_microMarkers.containsKey(microId)) {
        await controller.removeSymbol(_microMarkers[microId]!);
      }
      
      // Agregar nuevo marcador
      final addedSymbol = await controller.addSymbol(microSymbol.options);
      _microMarkers[microId] = addedSymbol;
      
      print('✅ Marcador actualizado en mapa para micro $microId');
      
    } catch (e) {
      print('❌ Error actualizando marcador: $e');
    }
  }
  
  Future<void> clearAllMarkers(MapLibreMapController controller) async {
    try {
      for (final symbol in _microMarkers.values) {
        await controller.removeSymbol(symbol);
      }
      _microMarkers.clear();
      print('🧹 Todos los marcadores de micros removidos');
    } catch (e) {
      print('❌ Error limpiando marcadores: $e');
    }
  }
} 