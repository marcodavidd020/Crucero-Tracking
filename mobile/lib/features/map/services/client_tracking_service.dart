import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
import '../../../services/tracking_socket_service.dart';
import '../../auth/providers/auth_provider.dart';

class ClientTrackingService {
  final WidgetRef ref;
  TrackingSocketService? trackingService;
  bool _mounted = true;
  Timer? _connectionCheckTimer;
  final Map<String, Symbol> _microMarkers = {};
  final Map<String, Map<String, dynamic>> _microLocations = {};
  Map<String, dynamic>? _lastLocationData;
  String? _selectedRouteId;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _locationUpdateSubscription;
  StreamSubscription? _routeLocationSubscription;
  StreamSubscription? _connectionSubscription;

  ClientTrackingService(this.ref);

  void dispose() {
    _mounted = false;
    _connectionCheckTimer?.cancel();
    _locationSubscription?.cancel();
    _locationUpdateSubscription?.cancel();
    _routeLocationSubscription?.cancel();
    _connectionSubscription?.cancel();
    trackingService?.dispose();
  }

  // ========== INICIALIZACIÓN ==========
  
  Future<void> initializeTracking() async {
    if (!_mounted) return;
    
    try {
      trackingService = TrackingSocketService();
      print('🔌 Cliente inicializando socket...');
      print('📍 URL: $baseUrlSocket');
      print('📡 Modo: SOLO ESCUCHA (cliente)');
      
      // YA NO inicializamos socket aquí - lo haremos cuando tengamos una ruta específica
      print('✅ TrackingSocketService preparado - esperando ruta específica');
      
    } catch (e) {
      print('❌ Error preparando tracking cliente: $e');
    }
  }

  Future<void> connectToSpecificRoute(String routeId) async {
    if (!_mounted || trackingService == null) return;
    
    try {
      print('🛣️ Conectando cliente a ruta específica: $routeId');
      
      // Obtener token almacenado durante el login
      final authToken = await AuthStateNotifier.getAuthToken();
      
      final user = ref.read(userProvider);
      print('🔑 Usuario: ${user?.nombre ?? "NONE"}');
      print('🔑 Usando token: ${authToken.isNotEmpty ? "PRESENTE" : "AUSENTE"}');
      
      // Usar el nuevo método que obtiene un micro real de la ruta
      await trackingService!.connectToRoute(
        routeId, 
        baseUrl: baseUrlSocket, 
        authToken: authToken
      );
      
      // Configurar listeners después de la conexión
      _setupSocketListeners();
      
      // Monitorear conexión
      _startConnectionMonitoring();
      
      _selectedRouteId = routeId;
      print('✅ Cliente conectado exitosamente a ruta: $routeId');
      
    } catch (e) {
      print('❌ Error conectando a ruta $routeId: $e');
    }
  }

  void _setupSocketListeners() {
    if (trackingService == null) return;
    
    // 1. Escuchar datos iniciales de tracking
    _locationSubscription = trackingService!
        .on<List<dynamic>>(TrackingEventType.initialTrackingData)
        .listen(
          (trackingList) {
            print('📍 CLIENTE recibió datos iniciales: ${trackingList.length} micros');
            _handleInitialTrackingData(trackingList);
          },
          onError: (error) {
            print('❌ Error en datos iniciales: $error');
          },
        );
    
    // 2. Escuchar actualizaciones de ubicación en tiempo real
    _locationUpdateSubscription = trackingService!
        .on<Map<String, dynamic>>(TrackingEventType.locationUpdate)
        .listen(
          (data) {
            print('📍 CLIENTE recibió actualización: $data');
            _handleLocationUpdate(data);
          },
          onError: (error) {
            print('❌ Error en actualizaciones de ubicación: $error');
          },
        );
    
    // 3. Escuchar actualizaciones específicas de ruta (si las hay)
    _routeLocationSubscription = trackingService!
        .on<Map<String, dynamic>>(TrackingEventType.routeLocationUpdate)
        .listen(
          (data) {
            print('🎉 ⭐ CLIENTE RECIBIÓ routeLocationUpdate: $data');
            print('🎉 ⭐ Timestamp del cliente: ${DateTime.now().millisecondsSinceEpoch}');
            print('🎉 ⭐ Estructura de datos: ${data.keys.toList()}');
            print('🎉 ⭐ Coordenadas: lat=${data['latitud']}, lng=${data['longitud']}');
            print('🎉 ⭐ PROCESANDO DATOS EN TIEMPO REAL...');
            _handleRouteLocationUpdate(data);
          },
          onError: (error) {
            print('❌ Error en stream de ubicaciones de ruta: $error');
          },
          onDone: () {
            print('⚠️ Stream de ubicaciones de ruta cerrado');
          },
        );

    // 4. NUEVO: También escuchar locationUpdate general
    trackingService!
        .on<Map<String, dynamic>>(TrackingEventType.locationUpdate)
        .listen(
          (data) {
            print('🌍 ⭐ CLIENTE RECIBIÓ locationUpdate GENERAL: $data');
            print('🌍 ⭐ Timestamp del cliente: ${DateTime.now().millisecondsSinceEpoch}');
            print('🌍 ⭐ PROCESANDO COMO ACTUALIZACIÓN DE RUTA...');
            _handleLocationUpdate(data);
          },
          onError: (error) {
            print('❌ Error en stream de ubicaciones generales: $error');
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

  void _handleInitialTrackingData(List<dynamic> trackingList) {
    print('🎯 Procesando datos iniciales de tracking: ${trackingList.length} micros');
    print('⚠️ 🚨 IMPORTANTE: Estos son datos HISTÓRICOS, no en tiempo real');
    print('⚠️ 🚨 El cliente debe esperar eventos routeLocationUpdate para datos actuales');
    
    for (final trackingData in trackingList) {
      if (trackingData is Map<String, dynamic>) {
        print('📦 Datos históricos recibidos: $trackingData');
        print('⏰ Timestamp de estos datos: ${trackingData['updatedAt'] ?? trackingData['timestamp']}');
        _processTrackingLocation(trackingData);
      }
    }
    
    print('⚠️ 🚨 DATOS INICIALES PROCESADOS - AHORA ESPERANDO EVENTOS EN TIEMPO REAL');
  }

  void _handleLocationUpdate(Map<String, dynamic> data) {
    print('🎯 Procesando actualización de ubicación en tiempo real');
    _processTrackingLocation(data);
  }

  void _handleRouteLocationUpdate(Map<String, dynamic> data) {
    print('🎯 Procesando actualización de ubicación de ruta específica');
    _processTrackingLocation(data);
  }

  void _processTrackingLocation(Map<String, dynamic> trackingData) {
    try {
      // El backend puede enviar 'id_micro' o 'idMicro'
      final microId = trackingData['id_micro']?.toString() ?? 
                      trackingData['idMicro']?.toString() ?? 
                      trackingData['microId']?.toString();
      
      final lat = trackingData['latitud']?.toDouble();
      final lng = trackingData['longitud']?.toDouble();
      final micro = trackingData['micro'];
      
      print('🔍 DATOS RECIBIDOS DEL SOCKET:');
      print('   📦 Data completa: $trackingData');
      print('   🚌 MicroId extraído: $microId');
      print('   📍 Coordenadas: lat=$lat, lng=$lng');
      print('   🚗 Info micro: $micro');
      
      if (microId == null || lat == null || lng == null) {
        print('⚠️ Datos de tracking incompletos: microId=$microId, lat=$lat, lng=$lng');
        print('⚠️ Estructura de datos recibida: ${trackingData.keys.toList()}');
        return;
      }
      
      final placa = micro?['placa'] ?? microId;
      final color = micro?['color'] ?? '#FF0000';
      
      print('📍 ✅ MICRO DETECTADO Y PROCESADO:');
      print('   🚌 ID: $microId');
      print('   🚗 Placa: $placa');
      print('   🎨 Color: $color');
      print('   📍 Ubicación NUEVA: ($lat, $lng)');
      
      // Notificar a los listeners para actualizar el mapa
      final processedData = {
        'microId': microId,
        'placa': placa,
        'color': color,
        'latitud': lat,
        'longitud': lng,
        'location': {
          'latitud': lat,
          'longitud': lng,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _notifyLocationUpdate(processedData);
      
    } catch (e) {
      print('❌ Error procesando datos de tracking: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  void _notifyLocationUpdate(Map<String, dynamic> processedData) {
    // Este método será llamado desde ClientRouteManager para actualizar el mapa
    final microId = processedData['microId'];
    final lat = processedData['latitud'];
    final lng = processedData['longitud'];
    
    print('🗺️ ⚡ NOTIFICANDO ACTUALIZACIÓN PARA MAPA:');
    print('   🚌 MicroId: $microId');
    print('   📍 Coordenadas: ($lat, $lng)');
    print('   ⏰ Timestamp: ${processedData['timestamp']}');
    
    // Verificar si hay cambio real en las coordenadas
    final previousData = _microLocations[microId];
    if (previousData != null) {
      final prevLat = previousData['latitud'];
      final prevLng = previousData['longitud'];
      print('   📊 Comparación con anterior:');
      print('       📍 Anterior: ($prevLat, $prevLng)');
      print('       📍 Nueva: ($lat, $lng)');
      print('       🔄 ¿Cambió?: ${prevLat != lat || prevLng != lng}');
      
      // Si las coordenadas son diferentes, forzar actualización inmediata
      if (prevLat != lat || prevLng != lng) {
        print('🚀 ⭐ COORDENADAS CAMBIARON - FORZANDO ACTUALIZACIÓN INMEDIATA');
        
        // Actualizar inmediatamente los datos en memoria
        _microLocations[microId] = processedData;
        
        // Trigger inmediato a ClientRouteManager si está disponible
        print('🎯 ⭐ ACTUALIZANDO MAPA EN TIEMPO REAL...');
        
        // Emitir evento para que ClientRouteManager actualice el mapa AHORA
        _notifyMapUpdate(microId, lat, lng);
      }
    } else {
      print('   📍 Primera ubicación para este micro');
      _microLocations[microId] = processedData;
      _notifyMapUpdate(microId, lat, lng);
    }
    
    // Siempre actualizar los datos en memoria
    _microLocations[microId] = processedData;
    print('✅ Datos almacenados en _microLocations[$microId]');
    print('📊 Total micros en memoria: ${_microLocations.length}');
  }

  // NUEVO: Método para notificar actualizaciones inmediatas al mapa
  void _notifyMapUpdate(String microId, double lat, double lng) {
    print('🗺️ 🚀 FORZANDO ACTUALIZACIÓN INMEDIATA DEL MAPA');
    print('   🚌 Micro: $microId');
    print('   📍 Nuevas coordenadas: ($lat, $lng)');
    
    // Esta función será llamada por ClientRouteManager para actualizar el mapa
    // Por ahora solo loguear, pero en una implementación completa
    // aquí se podría usar un callback o stream para notificar cambios
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
  
  Map<String, Map<String, dynamic>> get microLocations => _microLocations;
  
  Map<String, dynamic>? get lastLocationData => _lastLocationData;
  
  Stream<Map<String, dynamic>>? get locationUpdates {
    return trackingService?.on<Map<String, dynamic>>(TrackingEventType.routeLocationUpdate);
  }
  
  Stream<bool>? get connectionStatus {
    return trackingService?.on<bool>(TrackingEventType.connectionStatusChanged);
  }

  // ========== DEBUGGING Y TESTING ==========
  
  Future<void> forceRefreshMicroLocations() async {
    if (!_mounted) return;
    
    print('🔄 ⚡ FORZANDO ACTUALIZACIÓN DE DATOS DE MICROS...');
    
    try {
      // Solicitar datos frescos al socket
      if (trackingService?.isConnected == true) {
        print('📡 Solicitando datos frescos al socket...');
        
        // El socket desplegado no tiene evento para solicitar datos frescos
        // Pero podemos reconectar para obtener initialTrackingData actualizados
        
        print('🔄 Reconectando para obtener datos frescos...');
        await _reconnectService();
        
      } else {
        print('❌ No se puede refrescar - socket no conectado');
      }
      
    } catch (e) {
      print('❌ Error forzando actualización: $e');
    }
  }
  
  void logCurrentMicroLocations() {
    print('📊 ⚡ ESTADO ACTUAL DE MICROS EN MEMORIA:');
    print('   📊 Total micros: ${_microLocations.length}');
    
    if (_microLocations.isEmpty) {
      print('   📭 No hay micros en memoria');
      return;
    }
    
    for (final entry in _microLocations.entries) {
      final microId = entry.key;
      final data = entry.value;
      final timestamp = data['timestamp'];
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageInSeconds = (now - timestamp) / 1000;
      
      print('   🚌 Micro $microId:');
      print('     📍 Coordenadas: (${data['latitud']}, ${data['longitud']})');
      print('     ⏰ Timestamp: $timestamp');
      print('     ⏰ Antigüedad: ${ageInSeconds.toStringAsFixed(1)} segundos');
      print('     🎨 Placa: ${data['placa']}');
    }
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