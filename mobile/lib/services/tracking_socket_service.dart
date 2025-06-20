import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'; // Para ubicación
import 'package:connectivity_plus/connectivity_plus.dart'; // Para verificar conectividad
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Para almacenamiento local

enum TrackingEventType{
  locationUpdate,
  initialTrackingData,
  routeLocationUpdate,
  connectionStatusChanged
}

class TrackingSocketService{
  static final TrackingSocketService _instance = TrackingSocketService._internal();
  factory TrackingSocketService() => _instance;
  TrackingSocketService._internal();

  // Cliente socket - ARREGLO: Cambiar de late a nullable
  IO.Socket? socket;

  // Stream controllers para diferentes eventos
  final _eventControllers = <TrackingEventType, StreamController<dynamic>>{};

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _microId = '';
  String _authToken = '';
  bool _shouldTrackLocation = false; // Nuevo: controlar si debe trackear ubicación

  // Cola de ubicaciones pendientes cuando no hay conexión
  final List<Map<String, dynamic>> _pendingLocations = [];

  // Timer para enviar ubicación periódicamente
  Timer? _locationTimer;
  Timer? _reconnectTimer;

  // Duración entre actualizaciones de ubicación (en segundos)
  int _updateInterval = 5; // Aumentar a 5 segundos para evitar spam
  set updateInterval(int seconds) {
    _updateInterval = seconds;
    _restartLocationTracking();
  }

  Future<void> initSocket(String url, String microId, String token, {bool enableLocationTracking = false}) async {
    try {
      _microId = microId;
      _authToken = token;
      _shouldTrackLocation = enableLocationTracking; // Configurar si debe trackear

      print('🔌 Inicializando socket para tracking...');
      print('📍 URL: $url');
      print('🚌 MicroId: $microId');
      print('📡 Tracking activo: $_shouldTrackLocation${enableLocationTracking ? "" : " (SOLO ESCUCHA)"}');

      // ARREGLO: Limpiar socket anterior si existe
      if (socket != null) {
        socket?.disconnect();
        socket = null;
      }

      // Para clientes, usar configuración más simple y estable
      socket = IO.io(url, IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Permitir fallback a polling
          .enableAutoConnect()
          .setTimeout(10000) // Timeout de 10 segundos
          .setAuth({
            'microId': microId,
            'token': token,
            'type': enableLocationTracking ? 'driver' : 'client'
          })
          .build()
      );

      // ARREGLO: Verificar que el socket se creó correctamente
      if (socket == null) {
        throw Exception('No se pudo crear el socket');
      }

      socket?.onConnect((_){
        print('✅ Conexión establecida con el servidor de tracking');
        _isConnected = true;
        _emitEvent(TrackingEventType.connectionStatusChanged, true);
        
        // Cancelar timer de reconexión si existe
        _reconnectTimer?.cancel();

        // Enviar ubicaciones pendientes solo si es driver
        if (_shouldTrackLocation) {
          _sendPendingLocations();
          print('🚀 Iniciando tracking de ubicación automático');
          _startLocationTracking();
        } else {
          print('👂 Modo escucha activado - NO enviará ubicación propia');
        }
      });

      socket?.onDisconnect((reason) {
        print('❌ Desconectado del socket de tracking: $reason');
        _isConnected = false;
        _emitEvent(TrackingEventType.connectionStatusChanged, false);
        
        // Solo reintentar para clientes si la desconexión no fue intencional
        if (!_shouldTrackLocation && reason != 'io client disconnect') {
          _scheduleReconnect();
        }
      });

      socket?.onError((error){
        print('❌ Error en socket de tracking: $error');
      });

      socket?.onConnectError((error){
        print('❌ Error de conexión al socket de tracking: $error');
      });

      _setupEventListeners();
      
      // Solo para drivers
      if (_shouldTrackLocation) {
        _setupConnectivityMonitoring();
        await _loadPendingLocations();
      }

      print('✅ Socket de tracking inicializado correctamente');
      
    } catch (e) {
      print('❌ Error al inicializar socket de tracking: $e');
      socket = null;
      _isConnected = false;
      rethrow; // Re-lanzar el error para que el llamador lo maneje
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && socket != null) {
        print('🔄 Reintentando conexión automáticamente...');
        socket?.connect();
      }
    });
  }

  void _setupEventListeners() {
    socket?.on('locationUpdate', (data) => _emitEvent(TrackingEventType.locationUpdate, data));
    socket?.on('initialTrackingData', (data) => _emitEvent(TrackingEventType.initialTrackingData, data));
    socket?.on('routeLocationUpdate', (data) => _emitEvent(TrackingEventType.routeLocationUpdate, data));
  }

  void _setupConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    // Solo reconectar si es necesario y no estamos conectados
    if (result.isNotEmpty && result.first != ConnectivityResult.none) {
      if (!_isConnected && socket != null) {
        await Future.delayed(const Duration(seconds: 2));
        socket?.connect();
      }
    }
  }

  Future<void> _loadPendingLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingLocationsJson = prefs.getString('pendingLocations');

      if (pendingLocationsJson != null) {
        final List<dynamic> decoded = json.decode(pendingLocationsJson);
        _pendingLocations.addAll(decoded.cast<Map<String, dynamic>>());
        debugPrint('Cargadas ${_pendingLocations.length} ubicaciones pendientes');
      }
    } catch (e) {
      debugPrint('Error al cargar ubicaciones pendientes: $e');
    }
  }

  Future<void> _savePendingLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingLocations', json.encode(_pendingLocations));
    } catch (e) {
      debugPrint('Error al guardar ubicaciones pendientes: $e');
    }
  }

  void _startLocationTracking() {
    if (!_shouldTrackLocation) return;
    
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(seconds: _updateInterval), (_) {
      _getCurrentLocation();
    });
  }

  void _restartLocationTracking() {
    if (!_shouldTrackLocation) return;
    
    _locationTimer?.cancel();
    _startLocationTracking();
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
  }

  Future<void> _getCurrentLocation() async {
    if (!_shouldTrackLocation || !_isConnected) return;
    
    try {
      // Verificar permisos de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Crear datos de ubicación
      final locationData = {
        'id_micro': _microId,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'altura': position.altitude,
        'precision': position.accuracy,
        'bateria': 100.0, // Placeholder
        'imei': 'flutter-device-$_microId',
        'fuente': 'app_flutter_driver',
        'timestamp': DateTime.now().toIso8601String(),
      };

      sendLocationUpdate(locationData);

    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  void sendLocationUpdate(Map<String, dynamic> locationData) {
    if (!_shouldTrackLocation) return;
    
    if (_isConnected && socket != null) {
      socket?.emit('locationUpdate', locationData);
      debugPrint('✅ Ubicación enviada: ${locationData['latitud']}, ${locationData['longitud']}');
    } else {
      // Guardar en cola si no hay conexión
      _pendingLocations.add(locationData);
      _savePendingLocations();
      debugPrint('📦 Ubicación guardada en cola (sin conexión)');
    }
  }

  void _sendPendingLocations() {
    if (!_shouldTrackLocation || _pendingLocations.isEmpty) return;
    
    for (final location in _pendingLocations) {
      socket?.emit('locationUpdate', location);
    }
    debugPrint('📤 Enviadas ${_pendingLocations.length} ubicaciones pendientes');
    _pendingLocations.clear();
    _savePendingLocations();
  }

  // Método para que clientes se unan al tracking de una ruta específica
  void joinRouteTracking(String routeId) {
    if (socket != null && _isConnected) {
      socket?.emit('joinRoute', {'routeId': routeId});
      print('🛣️ Cliente unido al tracking de ruta: $routeId');
    } else {
      print('❌ No se puede unir a la ruta - socket no conectado');
    }
  }

  void leaveRouteTracking(String routeId) {
    if (socket != null && _isConnected) {
      socket?.emit('leaveRoute', {'routeId': routeId});
      print('🚪 Cliente salió del tracking de ruta: $routeId');
    }
  }

  // Stream getters para escuchar eventos
  Stream<T> on<T>(TrackingEventType eventType) {
    if (!_eventControllers.containsKey(eventType)) {
      _eventControllers[eventType] = StreamController<T>.broadcast();
    }
    return _eventControllers[eventType]!.stream.cast<T>();
  }

  void _emitEvent(TrackingEventType eventType, dynamic data) {
    if (_eventControllers.containsKey(eventType)) {
      _eventControllers[eventType]!.add(data);
    }
  }

  // Método dispose mejorado
  Future<void> dispose() async {
    print('🔄 Limpiando TrackingSocketService...');
    
    // Cancelar timers
    _locationTimer?.cancel();
    _reconnectTimer?.cancel();
    
    // Cerrar streams
    for (final controller in _eventControllers.values) {
      await controller.close();
    }
    _eventControllers.clear();
    
    // Desconectar socket
    if (socket != null) {
      socket?.disconnect();
      socket = null;
    }
    
    _isConnected = false;
    print('✅ TrackingSocketService limpiado');
  }
}