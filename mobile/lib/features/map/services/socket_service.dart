import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
import '../../../services/tracking_socket_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/background/socket_service.dart';

class SocketService {
  final WidgetRef ref;
  TrackingSocketService? _trackingService;
  bool _mounted = true;

  SocketService(this.ref);

  void dispose() {
    _mounted = false;
    _trackingService?.dispose();
  }

  // ========== SOCKET MANAGEMENT ==========
  
  Future<void> initializeSocket() async {
    final user = ref.read(userProvider);
    if (user?.esMicrero != true) return;
    
    _trackingService?.dispose();
    _trackingService = TrackingSocketService();
    
    try {
      await _trackingService!.initSocket(
        // 'http://54.82.231.172:3001',
        baseUrlSocket,
        user!.microId!,
        'token-auth-${user.id}',
        enableLocationTracking: true  // CRÍTICO: Empleado DEBE enviar ubicación
      );
      
      // NUEVO: También inicializar el socket para el background service
      SocketManager.initialize(baseUrlSocket, user.microId!, 'token-auth-${user.id}');
      
      print('🔌 Socket de tracking inicializado');
      print('🔌 Socket background también inicializado');
    } catch (e) {
      print('❌ Error al inicializar socket: $e');
    }
  }

  Future<void> sendLocationUpdate(Position position) async {
    if (!_mounted) return;
    
    final user = ref.read(userProvider);
    if (user?.esMicrero != true || _trackingService == null) return;

    // Crear datos según estructura del backend
    final locationData = {
      'id_micro': user!.microId!,
      'latitud': position.latitude,
      'longitud': position.longitude,
      'altura': position.altitude,
      'precision': position.accuracy,
      'bateria': 100.0,
      'imei': 'flutter-device-${user.id}',
      'fuente': 'app_flutter_employee',
    };

    if (_trackingService!.isConnected) {
      _trackingService!.sendLocationUpdate(locationData);
      print('✅ Ubicación enviada vía socket');
      print('📍 Coordenadas: ${position.latitude}, ${position.longitude}');
    } else {
      print('⚠️ Socket desconectado');
    }
  }

  bool get isConnected => _trackingService?.isConnected ?? false;

  void disconnectSocket() {
    _trackingService?.dispose();
    _trackingService = null;
    print('🔌 Socket desconectado');
  }
} 