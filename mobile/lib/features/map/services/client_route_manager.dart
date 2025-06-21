import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/client_tracking_service.dart';
import '../services/client_map_controller.dart';
import '../../providers/entidad_id_provider.dart';
import '../../providers/ruta_provider.dart';
import '../../../services/tracking_socket_service.dart';

// Helper function from ruta_provider.dart
List<LatLng> parseVertices(String verticesJson) {
  try {
    if (verticesJson.isEmpty) return [];
    
    final List<dynamic> vertices = json.decode(verticesJson);
    return vertices.map((vertex) {
      final lat = vertex['lat']?.toDouble() ?? vertex['latitude']?.toDouble() ?? 0.0;
      final lng = vertex['lng']?.toDouble() ?? vertex['longitude']?.toDouble() ?? 0.0;
      return LatLng(lat, lng);
    }).toList();
  } catch (e) {
    print('❌ Error parsing vertices: $e');
    return [];
  }
}

class ClientRouteManager {
  final WidgetRef ref;
  final ClientMapController mapController;
  
  ClientTrackingService? _trackingService;
  bool _shouldShowRoute = true;
  bool _socketInitialized = false;
  String? _currentRouteId; // Guardar la ruta actual para reconexiones

  ClientRouteManager(this.ref, this.mapController);

  // ========== TRACKING INITIALIZATION ==========
  
  Future<void> initializeTrackingForRoute(String routeId, BuildContext context) async {
    _currentRouteId = routeId; // Guardar para reconexiones
    
    if (_socketInitialized) {
      print('🔄 Socket ya inicializado, cambiando a nueva ruta...');
      
      // Cambiar a nueva ruta directamente
      if (_trackingService != null) {
        await _trackingService!.connectToSpecificRoute(routeId);
        startTrackingUpdates();
      }
      return;
    }

    print('🚀 Inicializando socket cliente para seguir ruta: $routeId');
    
    try {
      _trackingService = ClientTrackingService(ref);
      
      // Primero preparar el servicio
      await _trackingService!.initializeTracking();
      
      // Luego conectar a la ruta específica
      await _trackingService!.connectToSpecificRoute(routeId);
      
      // Verificar conexión
      await Future.delayed(const Duration(seconds: 2));
      
      if (_trackingService!.isConnected) {
        _socketInitialized = true;
        startTrackingUpdates();
        print('✅ Cliente conectado y siguiendo ruta: $routeId');
        
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
        print('❌ No se pudo establecer conexión con el servidor');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ No se pudo conectar al servidor'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error inicializando tracking cliente: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========== ROUTE HANDLING ==========
  
  void handleRouteChange(AsyncValue<List<dynamic>> routeData, BuildContext context) {
    if (!_shouldShowRoute) return;
    
    routeData.when(
      data: (rutas) {
        if (rutas.isNotEmpty) {
          final ruta = rutas.first;
          
          print('🛣️ Ruta seleccionada: ${ruta.nombre} (${ruta.id})');
          print('🚀 Conectando cliente al tracking de esta ruta...');
          
          // Inicializar socket para escuchar la ruta seleccionada
          initializeTrackingForRoute(ruta.id, context);
          
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              final points = parseVertices(ruta.vertices);
              if (points.isNotEmpty) {
                await mapController.drawRouteOnMap(points);
                await mapController.addRouteMarkers(points, ruta.nombre);
              }
            } catch (e) {
              print('❌ Error dibujando ruta: $e');
            }
          });
        }
      },
      loading: () => print('⏳ Cargando rutas...'),
      error: (error, stack) => print('❌ Error cargando rutas: $error'),
    );
  }

  // ========== TRACKING UPDATES ==========
  
  void startTrackingUpdates() {
    if (_trackingService != null && _trackingService!.isConnected) {
      print('🎧 Cliente iniciando escucha de actualizaciones de micros...');
      print('🔌 Estado del socket: ${_trackingService!.isConnected}');
      
      // Configurar un polling para verificar nuevos datos
      _startMapUpdatePolling();
      
      print('✅ Listener de ubicaciones de micros configurado correctamente');
    } else {
      print('⚠️ No se puede iniciar tracking - servicio no disponible o desconectado');
      print('🔌 Estado del servicio: $_trackingService');
      print('🔌 Estado de conexión: ${_trackingService?.isConnected}');
    }
  }

  void _startMapUpdatePolling() {
    // Configurar el controller del mapa en el tracking service (UNA SOLA VEZ)
    _setupMapController();
    
    // Revisar cada 3 segundos si hay nuevas ubicaciones de micros (menos frecuente para reducir carga)
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_trackingService == null || !_trackingService!.isConnected) {
        timer.cancel();
        return;
      }
      
      // Obtener ubicaciones de micros procesadas
      final microLocations = _trackingService!.microLocations;
      
      // Log minimal cada 10 ciclos (cada 30 segundos)
      if (timer.tick % 10 == 0) {
        print('🔄 Polling: ${microLocations.length} micros');
        
        if (microLocations.isNotEmpty) {
          final firstMicro = microLocations.values.first;
          final timestamp = firstMicro['timestamp'];
          final now = DateTime.now().millisecondsSinceEpoch;
          final ageInSeconds = (now - timestamp) / 1000;
          
          if (ageInSeconds > 30) {
            print('⚠️ Datos antiguos (${ageInSeconds.toStringAsFixed(0)}s)');
          }
        }
      }
      
      // Solo triggers updates - el batch processing maneja la eficiencia
      if (microLocations.isNotEmpty) {
        _batchUpdateMarkers(microLocations);
      }
    });
  }
  
  Future<void> _setupMapController() async {
    try {
      final controller = await mapController.mapController.future;
      _trackingService?.setMapController(controller);
      print('✅ Map controller configurado en tracking service');
    } catch (e) {
      print('❌ Error configurando map controller: $e');
    }
  }
  
  void _batchUpdateMarkers(Map<String, Map<String, dynamic>> microLocations) {
    // Usar el nuevo sistema optimizado que maneja batch processing
    for (final entry in microLocations.entries) {
      final microData = entry.value;
      _trackingService?.updateMicroLocationOnMap(null, microData); // controller se maneja internamente
    }
  }



  // ========== USER ACTIONS ==========
  
  Future<bool?> onSearchTap(BuildContext context) async {
    print('🔍 Abriendo búsqueda de rutas...');
    
    _shouldShowRoute = true;
    
    final result = await context.push("/search-route");
    if (result == true) {
      print('✅ Invalidando providers para recargar ruta...');
      ref.invalidate(entidadIdProvider);
      ref.invalidate(searchRutasProvider);
    }
    
    return result as bool?;
  }

  void onRouteCleared() {
    print('🧹 Limpiando ruta seleccionada...');
    
    // Dejar de escuchar la ruta actual
    if (_currentRouteId != null && _trackingService?.isConnected == true) {
      _trackingService!.leaveRouteTracking(_currentRouteId!);
    }
    
    _shouldShowRoute = false;
    _socketInitialized = false;
    _currentRouteId = null;
    
    // Limpiar marcadores de micros del mapa
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_trackingService != null) {
          final controller = await mapController.mapController.future;
          await _trackingService!.clearAllMarkers(controller);
        }
      } catch (e) {
        print('❌ Error limpiando marcadores: $e');
      }
    });
    
    mapController.clearRoute();
    
    // Invalidar providers para limpiar datos
    ref.invalidate(entidadIdProvider);
    ref.invalidate(searchRutasProvider);
    
    print('✅ Ruta y tracking limpiados');
  }

  // ========== DISPOSE ==========
  
  void dispose() {
    print('🧹 Limpiando ClientRouteManager...');
    
    // Dejar la ruta actual antes de dispose
    if (_currentRouteId != null && _trackingService?.isConnected == true) {
      _trackingService!.leaveRouteTracking(_currentRouteId!);
    }
    
    _trackingService?.dispose();
    print('✅ ClientRouteManager limpiado');
  }

  // ========== GETTERS ==========
  
  bool get shouldShowRoute => _shouldShowRoute;
  bool get socketInitialized => _socketInitialized;
  ClientTrackingService? get trackingService => _trackingService;
} 