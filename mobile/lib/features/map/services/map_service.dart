import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../providers/map_state_provider.dart';
import 'location_service.dart';
import 'enhanced_marker_service.dart';
import 'route_service.dart';
import 'socket_service.dart';
import '../../../services/location_background_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';

class MapService {
  final WidgetRef ref;
  
  // Servicios modulares
  late final LocationService _locationService;
  late final EnhancedMarkerService _markerService;
  late final RouteService _routeService;
  late final SocketService _socketService;
  
  bool _mounted = true;

  MapService(this.ref) {
    _locationService = LocationService(ref);
    _markerService = EnhancedMarkerService(ref);
    _routeService = RouteService(ref);
    _socketService = SocketService(ref);
  }

  void dispose() {
    _mounted = false;
    _locationService.dispose();
    _markerService.dispose();
    _routeService.dispose();
    _socketService.dispose();
  }

  // ========== TRACKING LIFECYCLE ==========
  
  Future<void> startTracking() async {
    if (!_mounted) return;
    
    try {
      print('🚀 Iniciando servicio de tracking...');
      
      final mapStateNotifier = ref.read(mapStateProvider.notifier);
      mapStateNotifier.setServiceActive(true);
      
      // Verificar permisos
      if (!await _locationService.checkLocationPermissions()) {
        throw Exception('Permisos de ubicación denegados');
      }
      
      final user = ref.read(userProvider);
      final isOnline = ref.read(isOnlineProvider);
      
      // CORREGIDO: Diferentes comportamientos para cliente vs chofer
      if (user?.esMicrero == true && user?.microId != null) {
        // CHOFERES: Requieren conexión para funcionar correctamente
        if (!isOnline) {
          print('⚠️ CHOFER SIN CONEXIÓN: El tracking no funcionará correctamente offline');
          print('🌐 Los choferes necesitan conexión para enviar ubicación a los clientes');
          throw Exception('Los choferes requieren conexión a internet para el tracking');
        }
        
        // Inicializar background service solo si hay conexión
        try {
          print('🔄 Iniciando background service para empleado (${user?.nombre})...');
          print('🚌 MicroID: ${user?.microId}');
          final success = await LocationBackgroundService.initializeSafely();
          if (success) {
            print('✅ Background service inicializado correctamente');
          } else {
            print('⚠️ Background service no pudo inicializarse');
            throw Exception('Error inicializando servicio de tracking para chofer');
          }
        } catch (e) {
          print('❌ Error inicializando background service: $e');
          throw Exception('Error inicializando tracking para chofer: $e');
        }
      } else {
        // CLIENTES: Pueden funcionar offline perfectamente
        print('👤 Usuario cliente - modo offline-first habilitado');
        if (isOnline) {
          print('🟢 Cliente online - recibirá ubicaciones en tiempo real');
        } else {
          print('🔴 Cliente offline - usando datos locales (rutas disponibles)');
        }
      }
      
      // Inicializar servicios (diferentes comportamientos)
      if (user?.esMicrero == true) {
        // Solo choferes con conexión inicializan socket
        await _socketService.initializeSocket();
      }
      
      await _locationService.startLocationTracking();
      
      print('✅ Servicio de tracking iniciado correctamente');
      
    } catch (e) {
      print('❌ Error al inicializar tracking: $e');
      if (_mounted) {
        ref.read(mapStateProvider.notifier).setServiceActive(false);
      }
      rethrow; // Re-lanzar para que la UI pueda mostrar el error
    }
  }

  Future<void> stopTracking(MapLibreMapController? controller) async {
    print('🛑 Deteniendo servicio de tracking...');
    
    final mapStateNotifier = ref.read(mapStateProvider.notifier);
    mapStateNotifier.setServiceActive(false);
    
    _locationService.stopLocationTracking();
    _socketService.disconnectSocket();
    
    // Limpiar marcador
    await _markerService.clearMarker(controller);
    
    print('✅ Servicio de tracking detenido');
  }

  // ========== LOCATION UPDATE ==========
  
  Future<void> handleLocationUpdate(MapLibreMapController controller, Position position) async {
    if (!_mounted) return;
    
    // Enviar ubicación por socket
    await _socketService.sendLocationUpdate(position);
    
    // Actualizar marcador en mapa
    await _markerService.updateMarkerPosition(controller, position);
    await _markerService.updateCameraIfFollowing(controller, position);
  }

  // ========== MAP INITIALIZATION ==========
  
  Future<void> initializeMap(MapLibreMapController controller) async {
    if (!_mounted) return;
    
    try {
      // Marcar mapa como listo
      ref.read(mapStateProvider.notifier).setMapReady(true);
      
      // Cargar ruta del usuario
      await _routeService.loadMyRoute(controller);
      
      // Inicializar health check del marcador
      _markerService.initializeMarkerHealthCheck(controller);
      
      // Si ya hay una posición, crear marcador inicial
      final currentPosition = ref.read(mapStateProvider).currentPosition;
      if (currentPosition != null) {
        await _markerService.updateMarkerPosition(controller, currentPosition);
      }
      
      print('✅ Mapa inicializado correctamente');
      
    } catch (e) {
      print('❌ Error inicializando mapa: $e');
    }
  }

  // ========== PUBLIC API ==========
  
  Future<void> centerOnMicro(MapLibreMapController controller) async {
    await _markerService.centerOnMarker(controller);
  }

  Future<void> toggleFollowMode() async {
    final currentFollow = ref.read(mapStateProvider).followMicro;
    ref.read(mapStateProvider.notifier).setFollowMicro(!currentFollow);
  }

  Future<void> loadRoute(MapLibreMapController controller) async {
    await _routeService.loadMyRoute(controller);
  }

  // Método para actualizar marcador desde el widget (cuando el controller esté disponible)
  Future<void> updateMarkerFromWidget(MapLibreMapController controller, Position position) async {
    await _markerService.updateMarkerPosition(controller, position);
    await _markerService.updateCameraIfFollowing(controller, position);
  }

  // ========== GETTERS ==========
  
  bool get isServiceActive => ref.read(mapStateProvider).isServiceActive;
  bool get isFollowingMicro => ref.read(mapStateProvider).followMicro;
  bool get isSocketConnected => _socketService.isConnected;
  Position? get currentPosition => ref.read(mapStateProvider).currentPosition;
} 