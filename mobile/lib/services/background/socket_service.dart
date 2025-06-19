import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  static IO.Socket? _socket;

  SocketManager._internal();

  /// Inicializa el socket si aún no está conectado
  static void initialize(String url,String microId, String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
        '$url/tracking', IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableForceNew()
        .setAuth({
          'microId': microId,
          'token': token,
        }).build(),
    );

    _socket!.onConnect((_) {
      print('[SOCKET] Conectado');
    });

    _socket!.onDisconnect((_) {
      print('[SOCKET] Desconectado');
    });

    _socket!.onConnectError((data) {
      print('[SOCKET] Error de conexión: $data');
    });

    _socket!.onError((data) {
      print('[SOCKET] Error: $data');
    });
  }

  /// Emite un evento con datos
  static void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      print('[SOCKET] No conectado. No se puede emitir: $event');
    }
  }

  /// Escucha un evento del servidor
  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Desconecta el socket (si deseas apagarlo manualmente)
  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  /// Verifica si está conectado
  static bool isConnected() {
    return _socket?.connected ?? false;
  }
}
