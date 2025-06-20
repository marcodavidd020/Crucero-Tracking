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
      print('🔄 Socket ya inicializado, uniéndose a nueva ruta...');
      _trackingService?.joinRouteTracking(routeId, context);
      
      // También reiniciar el tracking para la nueva ruta
      startTrackingUpdates();
      return;
    }

    print('🚀 Inicializando socket para seguir ruta: $routeId');
    
    try {
      _trackingService = ClientTrackingService(ref);
      
      // Configurar listener de reconexión ANTES de inicializar
      _setupReconnectionHandler(context);
      
      await _trackingService!.initializeTracking();
      
      // Esperar un momento para que la conexión se establezca
      await Future.delayed(const Duration(seconds: 2));
      
      if (_trackingService!.isConnected) {
        await _joinRouteAndStartTracking(routeId, context);
      } else {
        print('⚠️ Socket no pudo conectarse, reintentando...');
        // El handler de reconexión se encargará de reintentar
      }
    } catch (e) {
      print('❌ Error inicializando tracking: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupReconnectionHandler(BuildContext context) {
    _trackingService?.connectionStatus?.listen((isConnected) async {
      if (isConnected && _currentRouteId != null && !_socketInitialized) {
        print('🔄 Socket reconectado, intentando unirse a ruta: $_currentRouteId');
        
        // Esperar un momento para que la conexión se estabilice
        await Future.delayed(const Duration(seconds: 1));
        
        if (_trackingService!.isConnected) {
          await _joinRouteAndStartTracking(_currentRouteId!, context);
        }
      }
    });
  }

  Future<void> _joinRouteAndStartTracking(String routeId, BuildContext context) async {
    try {
      _trackingService!.joinRouteTracking(routeId, context);
      _socketInitialized = true;
      
      // Inicializar escucha de actualizaciones después de conectar
      startTrackingUpdates();
      
      print('✅ Socket inicializado y unido a ruta: $routeId');
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
          print('🚀 Iniciando socket para tracking de esta ruta...');
          
          // Inicializar socket solo cuando se selecciona ruta
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
      print('🎧 Iniciando escucha de actualizaciones de tracking...');
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
          print('📍 RECIBIDA actualización de ubicación desde servidor: $data');
          
          try {
            // Usar el método del mapController en lugar del trackingService
            await mapController.updateMicroLocationOnMap(data);
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
      
      print('✅ Listener de ubicaciones configurado correctamente');
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

  Future<void> onRouteCleared() async {
    _shouldShowRoute = false;
    await mapController.clearRoute();
  }

  // ========== CLEANUP ==========
  
  void dispose() {
    print('🧹 Iniciando limpieza del ClientRouteManager');
    
    try {
      _trackingService?.dispose();
      print('✅ TrackingService limpiado');
    } catch (e) {
      print('⚠️ Error limpiando TrackingService: $e');
    }
    
    print('✅ ClientRouteManager dispose completado');
  }

  // ========== GETTERS ==========
  
  bool get shouldShowRoute => _shouldShowRoute;
  bool get socketInitialized => _socketInitialized;
  ClientTrackingService? get trackingService => _trackingService;
} 