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

  // Cliente socket
  late IO.Socket socket;

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

  // Duración entre actualizaciones de ubicación (en segundos)
  int _updateInterval = 3; // Reducir a 3 segundos para mejor tiempo real
  set updateInterval(int seconds) {
    _updateInterval = seconds;
    _restartLocationTracking();
  }

  Future<void> initSocket(String url, String microId, String token, {bool enableLocationTracking = false}) async {
    _microId = microId;
    _authToken = token;
    _shouldTrackLocation = enableLocationTracking; // Configurar si debe trackear

    print('🔌 Inicializando socket para tracking...');
    print('📍 URL: $url/tracking');
    print('🚌 MicroId: $microId');
    print('📡 Tracking activo: $_shouldTrackLocation');

    socket = IO.io('$url/tracking', IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableForceNew()
        .setAuth({
          'microId': microId,
          'token': token
        })
        .build()
    );

    socket.onConnect((_){
      print('✅ Conexión establecida con el servidor de tracking');
      _isConnected = true;
      _emitEvent(TrackingEventType.connectionStatusChanged, true);

      // Enviar ubicaciones pendientes
      _sendPendingLocations();

      // SOLO iniciar tracking si está habilitado
      if (_shouldTrackLocation) {
        print('🚀 Iniciando tracking de ubicación automático');
        _startLocationTracking();
      } else {
        print('👂 Modo escucha activado - NO enviará ubicación propia');
      }
    });

    socket.onDisconnect((_) {
      print('❌ Desconectado del socket de tracking');
      _isConnected = false;
      _emitEvent(TrackingEventType.connectionStatusChanged, false);
    });

    socket.onError((error){
      print('❌ Error en socket de tracking: $error');
    });

    socket.onConnectError((error){
      print('❌ Error de conexión al socket de tracking: $error');
    });

    _setupEventListeners();

    _setupConnectivityMonitoring();

    await _loadPendingLocations();
  }

  void _setupEventListeners() {
    socket.on('locationUpdate', (data) => _emitEvent(TrackingEventType.locationUpdate, data));
    socket.on('initialTrackingData', (data) => _emitEvent(TrackingEventType.initialTrackingData, data));
    socket.on('routeLocationUpdate', (data) => _emitEvent(TrackingEventType.routeLocationUpdate, data));
  }

  void _setupConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    if (result != ConnectivityResult.none) {
      // Reconectar socket si hay conexión disponible
      if (!_isConnected) {
        socket.connect();
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
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(seconds: _updateInterval), (_) {
      _getCurrentLocation();
    });
  }

  void _restartLocationTracking() {
    _locationTimer?.cancel();
    _startLocationTracking();
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
  }

  Future<void> _getCurrentLocation() async {
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

      // Obtener ubicación actual con mejor precisión
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Evitar bloqueos largos
      );
      
      print('📍 Ubicación obtenida: ${position.latitude}, ${position.longitude} (precisión: ${position.accuracy}m)');

      // Obtener nivel de batería (esto es un ejemplo, necesitarás un plugin adicional)
      double batteryLevel = 100.0; // Por defecto 100%

      // Crear objeto de tracking optimizado
      final trackingData = {
        'id_micro': _microId,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'altura': position.altitude,
        'precision': position.accuracy,
        'bateria': batteryLevel,
        'imei': 'dispositivo-flutter', // Reemplazar con el IMEI real
        'fuente': 'app_flutter',
        'velocidad': position.speed, // Agregar velocidad
        'rumbo': position.heading, // Agregar rumbo/dirección
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Enviar la ubicación
      sendLocationUpdate(trackingData);

    } catch (e) {
      debugPrint('❌ Error al obtener ubicación: $e');
    }
  }

  void sendLocationUpdate(Map<String, dynamic> locationData) {
    if (_isConnected) {
      socket.emit('updateLocation', locationData);
      debugPrint('✅ Ubicación enviada vía socket: ${locationData['latitud']}, ${locationData['longitud']}');
    } else {
      // Almacenar para enviar más tarde
      _pendingLocations.add({
        ...locationData,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _savePendingLocations();
      debugPrint('📦 Ubicación almacenada para envío posterior (sin conexión)');
    }
  }

  void _sendPendingLocations() {
    if (_pendingLocations.isEmpty) return;

    // Enviar ubicaciones pendientes en orden cronológico
    final pendingCopy = List<Map<String, dynamic>>.from(_pendingLocations);
    _pendingLocations.clear();

    for (var location in pendingCopy) {
      // Quitar el timestamp que agregamos
      location.remove('timestamp');
      socket.emit('updateLocation', location);
    }

    _savePendingLocations();
  }

  // Unirse a una sala de ruta específica
  void joinRoute(String routeId) {
    if (_isConnected) {
      socket.emit('joinRoute', routeId);
    }
  }

  // Abandonar una sala de ruta
  void leaveRoute(String routeId) {
    if (_isConnected) {
      socket.emit('leaveRoute', routeId);
    }
  }

  // Obtener un stream para un tipo de evento específico
  Stream<dynamic> on(TrackingEventType event) {
    if (!_eventControllers.containsKey(event)) {
      _eventControllers[event] = StreamController<dynamic>.broadcast();
    }
    return _eventControllers[event]!.stream;
  }

  // Emitir un evento a través del controlador de eventos correspondiente
  void _emitEvent(TrackingEventType event, dynamic data) {
    if (_eventControllers.containsKey(event) && !_eventControllers[event]!.isClosed) {
      _eventControllers[event]!.add(data);
    }
  }

  // Cerrar la conexión y liberar recursos
  void dispose() {
    stopLocationTracking();
    socket.disconnect();

    _eventControllers.forEach((_, controller) {
      controller.close();
    });
    _eventControllers.clear();
  }
}