import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  static IO.Socket? _socket;
  static String? _currentMicroId;
  static String? _currentToken;

  SocketManager._internal();

  /// Inicializa el socket si aún no está conectado
  static void initialize(String url, String microId, String token) {
    if (_socket != null && _socket!.connected) return;

    _currentMicroId = microId;
    _currentToken = token;

    print('[SOCKET_BG] Inicializando socket background para micro: $microId');
    print('[SOCKET_BG] URL: $url (usando namespace principal)');

    // CRÍTICO: Usar namespace principal, no /tracking
    _socket = IO.io(
        url, // Sin /tracking
        IO.OptionBuilder()
        .setTransports(['websocket', 'polling']) // Permitir fallback
        .enableAutoConnect()
        .setTimeout(30000) // Timeout más largo para background
        .setAuth({
          'microId': microId,
          'token': token,
          'type': 'driver_background'
        }).build(),
    );

    _socket!.onConnect((_) {
      print('[SOCKET_BG] ✅ Conectado en background');
    });

    _socket!.onDisconnect((reason) {
      print('[SOCKET_BG] ❌ Desconectado: $reason');
      // Reintentar conexión automáticamente en background
      _scheduleReconnect(url);
    });

    _socket!.onConnectError((data) {
      print('[SOCKET_BG] ❌ Error de conexión: $data');
      _scheduleReconnect(url);
    });

    _socket!.onError((data) {
      print('[SOCKET_BG] ❌ Error: $data');
    });
  }

  static void _scheduleReconnect(String url) {
    if (_currentMicroId == null || _currentToken == null) return;
    
    Future.delayed(const Duration(seconds: 10), () {
      if (_socket == null || !_socket!.connected) {
        print('[SOCKET_BG] 🔄 Reintentando conexión automática...');
        _socket?.disconnect();
        _socket = null;
        initialize(url, _currentMicroId!, _currentToken!);
      }
    });
  }

  /// Emite un evento con datos - MEJORADO para incluir ruta
  static Future<void> emit(String event, dynamic data) async {
    if (_socket != null && _socket!.connected) {
      // CRÍTICO: Agregar ruta activa a los datos de ubicación
      if (event == 'updateLocation' && data is Map<String, dynamic>) {
        await _addActiveRoute(data);
      }
      
      _socket!.emit(event, data);
      print('[SOCKET_BG] ✅ Evento enviado: $event');
      if (event == 'updateLocation') {
        print('[SOCKET_BG]   📍 Lat: ${data['latitud']}, Lng: ${data['longitud']}');
        print('[SOCKET_BG]   🛣️ Ruta: ${data['id_ruta']}');
      }
    } else {
      print('[SOCKET_BG] ⚠️ No conectado. No se puede emitir: $event');
    }
  }

  /// NUEVO: Agregar ruta activa a los datos de ubicación
  static Future<void> _addActiveRoute(Map<String, dynamic> locationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rutaActivaId = prefs.getString('ruta_activa_id');
      
      if (rutaActivaId != null && rutaActivaId.isNotEmpty) {
        locationData['id_ruta'] = rutaActivaId;
        print('[SOCKET_BG] 🛣️ Ruta activa encontrada: $rutaActivaId');
      } else {
        locationData['id_ruta'] = 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d'; // Fallback
        print('[SOCKET_BG] ⚠️ No hay ruta activa, usando fallback');
      }
    } catch (e) {
      locationData['id_ruta'] = 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d'; // Fallback
      print('[SOCKET_BG] ❌ Error obteniendo ruta activa: $e');
    }
  }

  /// Escucha un evento del servidor
  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Desconecta el socket (si deseas apagarlo manualmente)
  static void disconnect() {
    print('[SOCKET_BG] 🔌 Desconectando socket background...');
    _socket?.disconnect();
    _socket = null;
    _currentMicroId = null;
    _currentToken = null;
  }

  /// Verifica si está conectado
  static bool isConnected() {
    return _socket?.connected ?? false;
  }
}
