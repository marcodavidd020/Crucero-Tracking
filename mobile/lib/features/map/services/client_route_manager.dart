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
      
      // Salir de la ruta anterior si estaba conectado
      if (_trackingService?.isConnected == true) {
        // Dejar la ruta anterior
        final previousRoute = _currentRouteId;
        if (previousRoute != null && previousRoute != routeId) {
          _trackingService!.leaveRouteTracking(previousRoute);
        }
        
        // Unirse a la nueva ruta
        _trackingService!.joinRouteTracking(routeId, context);
        
        // Reiniciar el tracking para la nueva ruta
        startTrackingUpdates();
      }
      return;
    }

    print('🚀 Inicializando socket cliente para seguir ruta: $routeId');
    
    try {
      _trackingService = ClientTrackingService(ref);
      
      await _trackingService!.initializeTracking();
      
      // Esperar un momento para que la conexión se establezca
      await Future.delayed(const Duration(seconds: 2));
      
      if (_trackingService!.isConnected) {
        await _joinRouteAndStartTracking(routeId, context);
      } else {
        print('⚠️ Socket cliente no pudo conectarse, reintentando...');
        // Reintentar una vez más
        await Future.delayed(const Duration(seconds: 3));
        if (_trackingService!.isConnected) {
          await _joinRouteAndStartTracking(routeId, context);
        } else {
          print('❌ No se pudo establecer conexión con el servidor');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ No se pudo conectar al servidor de tracking'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
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

  Future<void> _joinRouteAndStartTracking(String routeId, BuildContext context) async {
    try {
      _trackingService!.joinRouteTracking(routeId, context);
      _socketInitialized = true;
      
      // Inicializar escucha de actualizaciones después de conectar
      startTrackingUpdates();
      
      print('✅ Cliente conectado y unido a ruta: $routeId');
    } catch (e) {
      print('❌ Error uniéndose a la ruta: $e');
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
      
      // Verificar si el stream está disponible
      final locationStream = _trackingService!.locationUpdates;
      if (locationStream == null) {
        print('❌ Stream de ubicaciones es null');
        return;
      }
      
      print('✅ Stream de ubicaciones disponible, configurando listener...');
      
      locationStream.listen(
        (data) async {
          print('📍 CLIENTE recibió actualización de micro desde servidor: $data');
          
          try {
            // Usar el método actualizado del ClientTrackingService
            final controller = await mapController.mapController.future;
            await _trackingService!.updateMicroLocationOnMap(controller, data);
          } catch (e) {
            print('❌ Error procesando actualización de ubicación: $e');
          }
        },
        onError: (error) {
          print('❌ Error en stream de ubicaciones: $error');
        },
        onDone: () {
          print('⚠️ Stream de ubicaciones cerrado');
        },
      );
      
      print('✅ Listener de ubicaciones de micros configurado correctamente');
    } else {
      print('⚠️ No se puede iniciar tracking - servicio no disponible o desconectado');
      print('🔌 Estado del servicio: $_trackingService');
      print('🔌 Estado de conexión: ${_trackingService?.isConnected}');
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