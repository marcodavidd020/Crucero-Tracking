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
  Timer? _updateThrottleTimer;  // Nuevo: Timer para throttling
  Timer? _mapUpdateTimer;  // Nuevo: Timer específico para actualizaciones de mapa
  final Map<String, Symbol> _microMarkers = {};
  final Map<String, Map<String, dynamic>> _microLocations = {};
  final Map<String, Map<String, dynamic>> _pendingUpdates = {};  // Nuevo: Para almacenar updates pendientes
  final Map<String, DateTime> _lastMarkerUpdate = {};  // Nuevo: Control de última actualización de marcadores
  Map<String, dynamic>? _lastLocationData;
  String? _selectedRouteId;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _locationUpdateSubscription;
  StreamSubscription? _routeLocationSubscription;
  StreamSubscription? _connectionSubscription;
  DateTime? _lastProcessTime;  // Nuevo: Para controlar tiempo de último procesamiento
  MapLibreMapController? _currentController;  // Nuevo: Referencia al controller del mapa
  bool _isUpdatingMarkers = false;  // Nuevo: Flag para evitar updates simultáneos
  static const Duration _updateThrottleDuration = Duration(seconds: 2);  // Nuevo: Throttle de 2 segundos
  static const Duration _markerUpdateThrottle = Duration(milliseconds: 500);  // Nuevo: Throttle específico para marcadores

  ClientTrackingService(this.ref);

  void dispose() {
    _mounted = false;
    _connectionCheckTimer?.cancel();
    _updateThrottleTimer?.cancel();  // Nuevo: Cancelar timer de throttling
    _mapUpdateTimer?.cancel();  // Nuevo: Cancelar timer de mapa
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
    
    // Cancelar listeners existentes para evitar duplicados
    _locationSubscription?.cancel();
    _locationUpdateSubscription?.cancel();
    _routeLocationSubscription?.cancel();
    _connectionSubscription?.cancel();
    
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
    
    // 2. Escuchar actualizaciones de ubicación en tiempo real (UNIFICADO)
    _locationUpdateSubscription = trackingService!
        .on<Map<String, dynamic>>(TrackingEventType.locationUpdate)
        .listen(
          (data) {
            // Log mínimo para evitar spam
            _handleLocationUpdate(data);
          },
          onError: (error) {
            print('❌ Error en actualizaciones de ubicación: $error');
          },
        );
    
    // 3. Escuchar actualizaciones específicas de ruta
    _routeLocationSubscription = trackingService!
        .on<Map<String, dynamic>>(TrackingEventType.routeLocationUpdate)
        .listen(
          (data) {
            // Log mínimo para evitar spam
            _handleRouteLocationUpdate(data);
          },
          onError: (error) {
            print('❌ Error en stream de ubicaciones de ruta: $error');
          },
          onDone: () {
            print('⚠️ Stream de ubicaciones de ruta cerrado');
          },
        );

    // 4. Escuchar cambios de estado de conexión
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
    // Solo log minimal para evitar spam
    final microId = data['id_micro']?.toString();
    print('📍 Update recibido: $microId');
    _queueLocationUpdate(data);
  }

  void _handleRouteLocationUpdate(Map<String, dynamic> data) {
    // Solo log minimal para evitar spam
    final microId = data['id_micro']?.toString();
    print('🛣️ Route update recibido: $microId');
    _queueLocationUpdate(data);
  }

  // Nuevo método para encolar updates y procesarlos con throttling
  void _queueLocationUpdate(Map<String, dynamic> data) {
    if (!_mounted) return;
    
    final microId = data['id_micro']?.toString();
    if (microId == null) return;
    
    // Almacenar el update más reciente para cada micro
    _pendingUpdates[microId] = data;
    
    // Iniciar o reiniciar el timer de throttling
    _updateThrottleTimer?.cancel();
    _updateThrottleTimer = Timer(_updateThrottleDuration, () {
      _processPendingUpdates();
    });
  }

  // Nuevo método para procesar updates acumulados
  void _processPendingUpdates() {
    if (!_mounted || _pendingUpdates.isEmpty) return;
    
    final now = DateTime.now();
    
    // Solo procesar si han pasado al menos 2 segundos desde el último procesamiento
    if (_lastProcessTime != null && 
        now.difference(_lastProcessTime!) < _updateThrottleDuration) {
      return;
    }
    
    print('🔄 Procesando ${_pendingUpdates.length} updates acumulados...');
    
    // Procesar todos los updates pendientes
    for (final entry in _pendingUpdates.entries) {
      _processTrackingLocationThrottled(entry.value);
    }
    
    // Limpiar updates pendientes y actualizar timestamp
    _pendingUpdates.clear();
    _lastProcessTime = now;
    
    print('✅ Updates procesados');
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

  // Versión optimizada para throttling (menos logs)
  void _processTrackingLocationThrottled(Map<String, dynamic> trackingData) {
    try {
      final microId = trackingData['id_micro']?.toString() ?? 
                      trackingData['idMicro']?.toString() ?? 
                      trackingData['microId']?.toString();
      
      final lat = trackingData['latitud']?.toDouble();
      final lng = trackingData['longitud']?.toDouble();
      final micro = trackingData['micro'];
      
      if (microId == null || lat == null || lng == null) {
        print('⚠️ Datos incompletos para $microId');
        return;
      }
      
      final placa = micro?['placa'] ?? microId;
      final color = micro?['color'] ?? '#FF0000';
      
      // Log mínimo - solo lo esencial
      print('📍 Procesando $placa: ($lat, $lng)');
      
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
      
      _notifyLocationUpdateThrottled(processedData);
      
    } catch (e) {
      print('❌ Error en throttled update: $e');
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

  // Versión optimizada para throttling (menos logs, más eficiente)
  void _notifyLocationUpdateThrottled(Map<String, dynamic> processedData) {
    final microId = processedData['microId'];
    final lat = processedData['latitud'];
    final lng = processedData['longitud'];
    
    // Verificar si hay cambio real en las coordenadas (sin logs verbosos)
    final previousData = _microLocations[microId];
    if (previousData != null) {
      final prevLat = previousData['latitud'];
      final prevLng = previousData['longitud'];
      
      // Solo actualizar si las coordenadas cambiaron significativamente
      final latDiff = (prevLat - lat).abs();
      final lngDiff = (prevLng - lng).abs();
      
      if (latDiff > 0.0001 || lngDiff > 0.0001) {  // Filtro de cambio mínimo
        _microLocations[microId] = processedData;
        print('📍 ${processedData['placa']}: Actualizado');
      }
    } else {
      _microLocations[microId] = processedData;
      print('📍 ${processedData['placa']}: Primera ubicación');
    }
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

  // ========== ACTUALIZACIÓN DE MARCADORES OPTIMIZADA ==========
  
  void setMapController(MapLibreMapController controller) {
    _currentController = controller;
  }
  
  Future<void> updateMicroLocationOnMap(
    MapLibreMapController? controller, 
    Map<String, dynamic> locationData
  ) async {
    if (!_mounted || _isUpdatingMarkers) return;
    
    final microId = locationData['microId']?.toString();
    if (microId == null) return;
    
    // Throttling específico para cada marcador
    final now = DateTime.now();
    final lastUpdate = _lastMarkerUpdate[microId];
    if (lastUpdate != null && now.difference(lastUpdate) < _markerUpdateThrottle) {
      return; // Skip si es muy reciente
    }
    
    _lastMarkerUpdate[microId] = now;
    
    // Agrupar updates para procesar en batch
    _queueMarkerUpdate(microId, locationData);
  }
  
  void _queueMarkerUpdate(String microId, Map<String, dynamic> locationData) {
    // Almacenar el update más reciente para cada micro
    _pendingUpdates[microId] = locationData;
    
    // Procesar updates en batch cada 500ms
    _mapUpdateTimer?.cancel();
    _mapUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      _processPendingMarkerUpdates();
    });
  }
  
  Future<void> _processPendingMarkerUpdates() async {
    if (!_mounted || _isUpdatingMarkers || _currentController == null || _pendingUpdates.isEmpty) {
      return;
    }
    
    _isUpdatingMarkers = true;
    
    try {
      // Procesar todos los updates pendientes en un solo batch
      final updates = Map<String, Map<String, dynamic>>.from(_pendingUpdates);
      _pendingUpdates.clear();
      
      for (final entry in updates.entries) {
        await _updateSingleMarker(entry.key, entry.value);
      }
      
      // Log mínimal
      if (updates.length > 1) {
        print('📍 Batch actualizado: ${updates.length} marcadores');
      }
      
    } catch (e) {
      print('❌ Error en batch de marcadores: $e');
    } finally {
      _isUpdatingMarkers = false;
    }
  }
  
  Future<void> _updateSingleMarker(String microId, Map<String, dynamic> locationData) async {
    try {
      final location = locationData['location'];
      if (location == null) return;
      
      final lat = location['latitud']?.toDouble();
      final lng = location['longitud']?.toDouble();
      
      if (lat == null || lng == null) return;
      
      final placa = locationData['placa']?.toString() ?? 'Micro';
      
      // Si el marcador ya existe, solo actualizar posición
      if (_microMarkers.containsKey(microId)) {
        try {
          await _currentController!.updateSymbol(
            _microMarkers[microId]!,
            SymbolOptions(
              geometry: LatLng(lat, lng),
              textField: placa,
            ),
          );
          return;
        } catch (e) {
          // Si falla la actualización, recrear el marcador
          print('⚠️ Fallo actualizando marcador $microId, recreando...');
        }
      }
      
      // Crear nuevo marcador solo si no existe o falló la actualización
      await _createNewMarker(microId, lat, lng, placa);
      
    } catch (e) {
      print('❌ Error actualizando marcador $microId: $e');
    }
  }
  
  Future<void> _createNewMarker(String microId, double lat, double lng, String placa) async {
    try {
      // Remover marcador anterior si existe
      if (_microMarkers.containsKey(microId)) {
        try {
          await _currentController!.removeSymbol(_microMarkers[microId]!);
        } catch (e) {
          // Ignorar errores de remoción
        }
      }
      
      // Crear nuevo marcador
      final microSymbol = Symbol(
        microId,
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: 'bus-marker',
          iconSize: 0.8,
          textField: placa,
          textSize: 12,
          textColor: '#000000',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
          textOffset: const Offset(0, 2),
        ),
      );
      
      final addedSymbol = await _currentController!.addSymbol(microSymbol.options);
      _microMarkers[microId] = addedSymbol;
      
    } catch (e) {
      print('❌ Error creando marcador $microId: $e');
    }
  }
  
  Future<void> clearAllMarkers(MapLibreMapController? controller) async {
    try {
      final mapController = controller ?? _currentController;
      if (mapController == null) return;
      
      for (final symbol in _microMarkers.values) {
        try {
          await mapController.removeSymbol(symbol);
        } catch (e) {
          // Ignorar errores individuales de remoción
        }
      }
      _microMarkers.clear();
      _lastMarkerUpdate.clear();
      print('🧹 Todos los marcadores de micros removidos');
    } catch (e) {
      print('❌ Error limpiando marcadores: $e');
    }
  }
} 