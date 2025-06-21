import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart'; // Para ubicación
import 'package:connectivity_plus/connectivity_plus.dart'; // Para verificar conectividad
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Para almacenamiento local
import 'package:http/http.dart' as http;

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
  IO.Socket? socket;

  // Stream controllers para diferentes eventos
  final _eventControllers = <TrackingEventType, StreamController<dynamic>>{};

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _microId = '';
  String _authToken = '';
  String _baseUrl = '';
  bool _shouldTrackLocation = false; // Nuevo: controlar si debe trackear ubicación

  // Cola de ubicaciones pendientes cuando no hay conexión
  final List<Map<String, dynamic>> _pendingLocations = [];

  // Timer para enviar ubicación periódicamente
  Timer? _locationTimer;
  Timer? _reconnectTimer;

  // Duración entre actualizaciones de ubicación (en segundos)
  int _updateInterval = 10; // Aumentar a 5 segundos para evitar spam
  set updateInterval(int seconds) {
    _updateInterval = seconds;
    _restartLocationTracking();
  }

  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  Future<void> initSocket(
    String baseUrl, 
    String microId, 
    String authToken,
    {bool enableLocationTracking = false}
  ) async {
    try {
      // Almacenar parámetros
      _baseUrl = baseUrl;
      _microId = microId;
      _authToken = authToken;
      _shouldTrackLocation = enableLocationTracking;

      // Construir URL del namespace tracking
      final trackingUrl = baseUrl.endsWith('/') ? '${baseUrl}tracking' : '$baseUrl/tracking';
      
      print('🔌 Inicializando socket para tracking...');
      print('📍 URL: $baseUrl');
      print('🚌 MicroId: $microId');
      print('📡 Tracking activo: $enableLocationTracking (${enableLocationTracking ? "ENVÍA UBICACIÓN" : "SOLO ESCUCHA"})');
      print('📡 ⭐ TODOS conectan al namespace /tracking: $trackingUrl');
      
      // DETERMINAR EL TIPO DE USUARIO
      final isEmployee = !microId.startsWith('client-');
      final userType = isEmployee ? "EMPLEADO" : "CLIENTE";
      print('📡 ⭐ Tipo de usuario: $userType');
      print('📡 ⭐ Autenticación: microId=$microId, token presente=${authToken.isNotEmpty}');

      // Configuración del socket según el backend desplegado
      socket = IO.io(trackingUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setTimeout(30000)  // Aumentar timeout
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setAuth({
            'microId': microId,  // REQUERIDO por el backend
            'token': authToken,  // REQUERIDO por el backend
          })
          .build()
      );

      if (socket == null) {
        throw Exception('No se pudo crear el socket');
      }

      socket?.onConnect((_) {
        print('✅ Conexión establecida con el servidor de tracking');
        print('🔗 ID del socket: ${socket?.id}');
        print('🔗 Namespace: ${socket?.nsp}');
        print('🔗 Connected: ${socket?.connected}');
        
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
        
        if (_shouldTrackLocation) {
          print('🔄 Driver desconectado, programando reconexión inmediata...');
          _scheduleReconnect();
        } else {
          if (reason != 'io client disconnect') {
            _scheduleReconnect();
          }
        }
      });

      socket?.onError((error) {
        print('❌ Error en socket de tracking: $error');
        print('❌ Tipo de error: ${error.runtimeType}');
      });

      socket?.onConnectError((error) {
        print('❌ Error de conexión al socket de tracking: $error');
        print('❌ Tipo de error de conexión: ${error.runtimeType}');
        _isConnected = false;
      });

      socket?.on('disconnect', (reason) {
        print('💥 ⭐ DISCONNECT DETALLADO: $reason');
        print('💥 ⭐ Tipo de razón: ${reason.runtimeType}');
        print('💥 ⭐ Socket ID: ${socket?.id}');
        print('💥 ⭐ Namespace: ${socket?.nsp}');
        print('💥 ⭐ Connected: ${socket?.connected}');
        
        if (reason == 'io server disconnect') {
          print('💥 ⭐ CRÍTICO: El servidor cerró la conexión deliberadamente');
          print('💥 ⭐ Posibles causas:');
          print('💥 ⭐ - Validación fallida en el backend');
          print('💥 ⭐ - MicroId no autorizado');
          print('💥 ⭐ - Token inválido');
          print('💥 ⭐ - Micro sin ruta asignada');
          print('💥 ⭐ - Múltiples conexiones con mismo microId');
          print('💥 ⭐ - Timeout del servidor');
          print('💥 ⭐ - Payload demasiado grande');
        }
      });

      _setupEventListeners();
      
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
    
    final reconnectDelay = _shouldTrackLocation 
        ? const Duration(seconds: 3)
        : const Duration(seconds: 5);
    
    print('⏱️ Programando reconexión en ${reconnectDelay.inSeconds} segundos...');
    
    _reconnectTimer = Timer(reconnectDelay, () {
      if (!_isConnected && socket != null) {
        print('🔄 Reintentando conexión automáticamente...');
        socket?.connect();
      }
    });
  }

  void _setupEventListeners() {
    if (socket == null) return;
    
    print('🎧 Configurando listeners de eventos del socket...');
    
    // CRÍTICO: Listener para datos iniciales
    socket?.on('initialTrackingData', (data) {
      print('📦 ⭐ RECIBIDO initialTrackingData: $data');
      print('📦 ⭐ Tipo de datos: ${data.runtimeType}');
      print('📦 ⭐ Timestamp del evento: ${DateTime.now().millisecondsSinceEpoch}');
      
      if (data is List) {
        print('📦 ⭐ Lista con ${data.length} elementos');
        _emitEvent(TrackingEventType.initialTrackingData, data);
      } else {
        print('📦 ⚠️ Datos no son una lista: $data');
      }
    });

    // Listener para actualizaciones de ruta específica (lo que necesita el cliente)
    socket?.on('routeLocationUpdate', (data) {
      print('📍 ⭐ CRÍTICO: RECIBIDO evento routeLocationUpdate: $data');
      print('📍 ⭐ Tipo de datos: ${data.runtimeType}');
      print('📍 ⭐ Timestamp del evento: ${DateTime.now().millisecondsSinceEpoch}');
      
      if (data is Map<String, dynamic>) {
        print('📍 ⭐ Datos válidos - emitiendo al stream');
        print('📍 ⭐ Estructura de datos: ${data.keys.toList()}');
        print('📍 ⭐ Coordenadas del evento: lat=${data['latitud']}, lng=${data['longitud']}');
        print('📍 ⭐ MicroId del evento: ${data['id_micro']}');
        _emitEvent(TrackingEventType.routeLocationUpdate, data);
      } else {
        print('📍 ⚠️ Datos inválidos recibidos: ${data.runtimeType}');
      }
    });

    // NUEVO: Listener general para TODOS los eventos (debug masivo)
    socket?.on('locationUpdate', (data) {
      print('🌍 ⚡ RECIBIDO locationUpdate GENERAL: $data');
      print('🌍 ⚡ Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
      if (data is Map<String, dynamic>) {
        print('🌍 ⚡ Coordenadas: lat=${data['latitud']}, lng=${data['longitud']}');
        print('🌍 ⚡ MicroId: ${data['idMicro'] ?? data['id_micro']}');
        
        // TEMPORAL: También emitir como routeLocationUpdate para testing
        print('🔄 ⚡ REENVIANDO locationUpdate como routeLocationUpdate para testing');
        _emitEvent(TrackingEventType.routeLocationUpdate, data);
      }
      _emitEvent(TrackingEventType.locationUpdate, data);
    });

    // Listeners para confirmación de unión/salida de rutas del socket principal
    socket?.on('joinedRouteTracking', (data) {
      print('✅ Cliente unido al tracking de ruta: $data');
    });
    
    socket?.on('leftRouteTracking', (data) {
      print('👋 Cliente salió del tracking de ruta: $data');
    });
    
    // CRÍTICO: Listeners específicos para debugging de desconexión
    socket?.on('connect_error', (data) {
      print('🔴 ⭐ CONNECT_ERROR: $data');
      print('🔴 ⭐ Tipo: ${data.runtimeType}');
      if (data is Map) {
        print('🔴 ⭐ Message: ${data['message']}');
        print('🔴 ⭐ Description: ${data['description']}');
        print('🔴 ⭐ Context: ${data['context']}');
      }
    });
    
    // Listeners adicionales para debug
    socket?.on('disconnect', (reason) {
      print('🔴 ⭐ SOCKET DISCONNECT: $reason');
    });
    
    socket?.on('reconnect', (attemptNumber) {
      print('🔄 ⭐ SOCKET RECONNECT: intento $attemptNumber');
    });
    
    socket?.on('reconnect_error', (error) {
      print('🔴 ⭐ RECONNECT_ERROR: $error');
    });
    
    // NUEVO: Listener para cualquier evento (debug)
    socket?.onAny((event, data) {
      print('🔍 ⚡ EVENTO RECIBIDO: $event');
      print('🔍 ⚡ Datos: $data');
      print('🔍 ⚡ Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
    });
    
    // NUEVO: Test de conexión manual cada 10 segundos
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (socket?.connected == true) {
        print('💓 HEARTBEAT: Socket cliente conectado - ${DateTime.now()}');
        print('💓 ID: ${socket?.id}');
        print('💓 Namespace: ${socket?.nsp}');
      } else {
        print('💔 HEARTBEAT: Socket cliente DESCONECTADO - ${DateTime.now()}');
      }
    });
    
    print('✅ Listeners configurados completamente');
  }

  void _setupConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
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

      // Crear datos de ubicación según estructura del backend
      final locationData = {
        'id_micro': _microId,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'altura': position.altitude,
        'precision': position.accuracy,
        'bateria': 100.0,
        // 'imei': 'flutter-device-$_microId',
        'imei': 'flutter-device',
        'fuente': 'app_flutter_driver',
      };

      sendLocationUpdate(locationData);

    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  void sendLocationUpdate(Map<String, dynamic> locationData) {
    if (!_shouldTrackLocation) {
      print('⚠️ No se puede enviar ubicación - tracking deshabilitado');
      return;
    }
    
    if (_isConnected && socket != null) {
      // Usar evento 'updateLocation' según el backend
      socket?.emit('updateLocation', locationData);
      print('✅ Ubicación enviada al servidor:');
      print('   📍 Lat: ${locationData['latitud']}, Lng: ${locationData['longitud']}');
      print('   🚌 Micro: ${locationData['id_micro']}');
      print('    Via evento: updateLocation');
    } else {
      // Guardar en cola si no hay conexión
      _pendingLocations.add(locationData);
      _savePendingLocations();
      print('📦 Ubicación guardada en cola (sin conexión)');
      print('   📊 Total en cola: ${_pendingLocations.length}');
    }
  }

  void _sendPendingLocations() {
    if (!_shouldTrackLocation || _pendingLocations.isEmpty) return;
    
    for (final location in _pendingLocations) {
      socket?.emit('updateLocation', location);
    }
    print('📤 Enviadas ${_pendingLocations.length} ubicaciones pendientes');
    _pendingLocations.clear();
    _savePendingLocations();
  }

  // Método para que clientes se unan al tracking de una ruta específica
  Future<void> connectToRoute(String routeId, {String? baseUrl, String? authToken}) async {
    try {
      // Usar URLs y token proporcionados o los por defecto
      if (baseUrl != null) _baseUrl = baseUrl;
      if (authToken != null) _authToken = authToken;
      
      // ESTRATEGIA MEJORADA: Obtener un micro real de la ruta específica
      final microFromRoute = await _getMicroFromRoute(routeId);
      
      if (microFromRoute == null) {
        print('❌ No se encontró micro activo para la ruta: $routeId');
        return;
      }
      
      print('🚌 Usando micro real de la ruta: $microFromRoute');
      
      await initSocket(
        _baseUrl,
        microFromRoute,  // Usar microId real de la ruta
        _authToken,
        enableLocationTracking: false  // Cliente NO envía ubicación
      );
      
      // Una vez conectado, unirse a la ruta específica
      if (socket?.connected == true) {
        print('🔗 ⭐ SOCKET CONECTADO - UNIÉNDOSE A SALAS');
        
        // CRÍTICO: Usar el evento correcto del socket desplegado
        socket?.emit('joinRoute', routeId);
        print('📡 ⭐ SOCKET DESPLEGADO: Enviado joinRoute para routeId=$routeId');
        
        // IMPORTANTE: El cliente también debe unirse a tracking:all para recibir locationUpdate
        // Esto se hace automáticamente en el backend cuando el cliente se conecta con microId
        
        // Verificar que el socket esté realmente conectado
        print('🔌 ⭐ VERIFICACIÓN DE ESTADO:');
        print('   🔗 Socket ID: ${socket?.id}');
        print('   🔗 Connected: ${socket?.connected}');
        print('   🔗 Namespace: ${socket?.nsp}');
        
        // El socket desplegado no envía confirmación de joinRoute
        
        print('🛣️ Unido a tracking de ruta: $routeId');
        print('🔔 Unido a sala general: tracking:all');
        print('📍 Cliente conectado para seguir ruta: $routeId');
        print('🚌 Usando micro: $microFromRoute');
      } else {
        print('❌ ⭐ ERROR: Socket no está conectado');
        print('🔌 Estado: ${socket?.connected}');
        print('🔌 Socket: $socket');
      }
      
    } catch (e) {
      print('❌ Error conectando a ruta $routeId: $e');
    }
  }

  // Método auxiliar para obtener un micro de la ruta
  Future<String?> _getMicroFromRoute(String routeId) async {
    try {
      // NUEVA ESTRATEGIA: Para clientes, generar un microId único
      // pero usar un micro real de la ruta para validación
      
      // Asegurar que la URL base tenga el protocolo y dominio completo
      String apiUrl = _baseUrl;
      if (!apiUrl.startsWith('http')) {
        apiUrl = 'http://54.82.231.172:3001';  // URL completa como fallback
      }
      
      // Hacer llamada real a la API para obtener micros de la ruta
      final fullUrl = '$apiUrl/api/micro/by-route/$routeId';
      print('🌐 Consultando micros en: $fullUrl');
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> micros = json.decode(response.body);
        
        if (micros.isNotEmpty) {
          // Tomar el primer micro activo de la ruta
          final firstMicro = micros.first;
          final realMicroId = firstMicro['id']?.toString();
          
          if (realMicroId != null && realMicroId.isNotEmpty) {
            print('🚌 Encontrado micro real para ruta $routeId: $realMicroId');
            
            // IMPORTANTE: Para clientes, usar el mismo microId que el chofer
            // pero el backend debe permitir múltiples conexiones con el mismo microId
            // La diferencia estará en que el cliente NO enviará updateLocation
            print('👥 Cliente usará mismo microId que chofer: $realMicroId');
            print('🔒 Diferencia: Cliente NO enviará eventos updateLocation');
            
            return realMicroId;
          }
        }
        
        print('⚠️ No se encontraron micros activos para la ruta: $routeId');
        return null;
      } else {
        print('❌ Error API obteniendo micros de ruta $routeId: ${response.statusCode}');
        
        // FALLBACK: Usar micro conocido que sabemos que funciona
        print('🔄 Usando micro fallback conocido');
        if (routeId.isNotEmpty) {
          // NUEVO: Usar micro del cliente Pedro Toledo (ABC122) como fallback
          // Esto evita conflictos con el chofer que usa el micro ABC123
          return '1c7f5325-e0a8-447e-88b7-b2b4ceaf27a4'; // Micro ABC122 (Pedro Toledo)
        }
        return null;
      }
    } catch (e) {
      print('❌ Excepción obteniendo micro de ruta $routeId: $e');
      
      // FALLBACK: Usar micro conocido en caso de error
      print('🔄 Usando micro fallback por excepción');
      if (routeId.isNotEmpty) {
        // NUEVO: Usar micro del cliente Pedro Toledo (ABC122) como fallback
        return '1c7f5325-e0a8-447e-88b7-b2b4ceaf27a4'; // Micro ABC122 (Pedro Toledo)
      }
      return null;
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

  // Métodos para unirse/salir de rutas específicas
  void joinRouteTracking(String routeId) {
    if (socket?.connected == true) {
      socket?.emit('joinRoute', routeId);
      print('🛣️ Unido a tracking de ruta: $routeId');
    } else {
      print('❌ No se puede unir a ruta - socket no conectado');
    }
  }

  void leaveRouteTracking(String routeId) {
    if (socket?.connected == true) {
      socket?.emit('leaveRoute', routeId);
      print('🚪 Salido del tracking de ruta: $routeId');
    }
  }

}