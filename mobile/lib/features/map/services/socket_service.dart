import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/tracking_socket_service.dart';
import '../../auth/providers/auth_provider.dart';

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
        'http://54.82.231.172:3001',
        user!.microId!,
        'token-auth-${user.id}',
        enableLocationTracking: true
      );
      print('🔌 Socket de tracking inicializado');
    } catch (e) {
      print('❌ Error al inicializar socket: $e');
    }
  }

  Future<void> sendLocationUpdate(Position position) async {
    final user = ref.read(userProvider);
    if (user?.esMicrero != true || _trackingService == null) return;

    final locationData = {
      'id_micro': user!.microId!,
      'latitud': position.latitude,
      'longitud': position.longitude,
      'altura': position.altitude,
      'precision': position.accuracy,
      'bateria': 100.0,
      'imei': 'flutter-device-${user.id}',
      'fuente': 'app_flutter_employee',
      'id_ruta': _getRutaId(user.rutaAsignada),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_trackingService!.isConnected) {
      _trackingService!.sendLocationUpdate(locationData);
      print('✅ Ubicación enviada vía socket');
    } else {
      print('⚠️ Socket desconectado');
    }
  }

  String _getRutaId(String? rutaAsignada) {
    switch (rutaAsignada) {
      case 'Centro - Plan 3000': return 'RUT001';
      case 'Centro - Equipetrol': return 'RUT003';
      case 'Ruta B': return 'RUT_B';
      default: return 'RUT001';
    }
  }

  bool get isConnected => _trackingService?.isConnected ?? false;

  void disconnectSocket() {
    _trackingService?.dispose();
    _trackingService = null;
    print('🔌 Socket desconectado');
  }
} 