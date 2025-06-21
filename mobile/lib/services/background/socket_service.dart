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
    
    // CRÍTICO: Usar namespace /tracking según el backend desplegado
    final trackingUrl = url.endsWith('/') ? '${url}tracking' : '$url/tracking';
    print('[SOCKET_BG] ⭐ Conectando al namespace /tracking: $trackingUrl');
    print('[SOCKET_BG] ⭐ Auth: microId=$microId, token presente=${token.isNotEmpty}');

    _socket?.disconnect();
    
    _socket = IO.io(trackingUrl, IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .setTimeout(10000)
        .setAuth({
          'microId': microId,  // REQUERIDO por el backend
          'token': token,      // REQUERIDO por el backend
        })
        .build()
    );

    _socket?.onConnect((_) {
      print('[SOCKET_BG] ✅ Socket background conectado');
      print('[SOCKET_BG] ID: ${_socket?.id}');
    });

    _socket?.onDisconnect((reason) {
      print('[SOCKET_BG] ❌ Socket background desconectado: $reason');
    });

    _socket?.onError((error) {
      print('[SOCKET_BG] ❌ Error: $error');
    });
  }

  /// Envía datos de ubicación
  static void emitLocationUpdate(Map<String, dynamic> locationData) {
    if (_socket == null || !_socket!.connected) {
      print('[SOCKET_BG] ⚠️ Socket no conectado');
      return;
    }

    try {
      // Usar evento 'updateLocation' según el backend
      _socket!.emit('updateLocation', locationData);
      print('[SOCKET_BG] ✅ Evento enviado: updateLocation');
      print('[SOCKET_BG] Datos: ${locationData['latitud']}, ${locationData['longitud']}');
    } catch (e) {
      print('[SOCKET_BG] ❌ Error enviando ubicación: $e');
    }
  }

  /// Cierra la conexión del socket
  static void disconnect() {
    print('[SOCKET_BG] 🔌 Desconectando socket background...');
    _socket?.disconnect();
    _socket = null;
    _currentMicroId = null;
    _currentToken = null;
  }

  /// Getter para verificar el estado de conexión
  static bool get isConnected => _socket?.connected ?? false;

  /// Getter para obtener el microId actual
  static String? get currentMicroId => _currentMicroId;
}
