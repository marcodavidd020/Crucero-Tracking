import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

enum SocketEventType {
  message,
  userJoined,
  userLeft,
  messageResponse
}

class SocketService {

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;

  final _eventControllers = <SocketEventType, StreamController<dynamic>>{};

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void initSocket(String url, {Map<String, dynamic>? auth}) {
    socket = IO.io(url, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .enableForceNew()
      .setAuth(auth ?? {})
      .build());

    socket.onConnect((_) {
      print('Connected to socket');
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      print('Disconnected from socket');
      _isConnected = false;
    });

    socket.onError((error){
      print('Error: $error');
    });

    socket.onConnectError((error){
      print('Error connect: $error');
    });

    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Registrar Listeners para cada tipo de evento
    socket.on('message', (data)=> _emitEvent(SocketEventType.message, data));
    socket.on('userJoined', (data)=> _emitEvent(SocketEventType.userJoined, data));
    socket.on('userLeft', (data)=> _emitEvent(SocketEventType.userLeft, data));
    socket.on('messageResponse', (data)=> _emitEvent(SocketEventType.messageResponse, data));
  }

  Stream<dynamic> on(SocketEventType event) {
    if(!_eventControllers.containsKey(event)){
      _eventControllers[event] = StreamController<dynamic>.broadcast();
    }
    return _eventControllers[event]!.stream;
  }

  void _emitEvent(SocketEventType event, dynamic data) {
    if(_eventControllers.containsKey(event) && !_eventControllers[event]!.isClosed){
      _eventControllers[event]!.add(data);
    } else {
      print('No hay stream para el evento $event o el stream está cerrado');
    }
  }

  void sendMessage(String message) {
    if(isConnected){
      socket.emit('message', {'message': message});
    }
  }

  void joinRoom(String room){
    if(isConnected){
      socket.emit('joinRoom', room);
    }
  }

  void leaveRoom(String room){
    if(isConnected){
      socket.emit('leaveRoom', room);
    }
  }

  void emit(String event, dynamic data) {
    if(isConnected){
      socket.emit(event, data);
    }
  }

  void dispose(){
    socket.disconnect();

    _eventControllers.forEach((_, controller){
      controller.close();
    });

    _eventControllers.clear();
  }
}
