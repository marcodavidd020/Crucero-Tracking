import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
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
        // 'http://54.82.231.172:3001',
        baseUrlSocket,
        user!.microId!,
        'token-auth-${user.id}',
        enableLocationTracking: true  // CRÍTICO: Empleado DEBE enviar ubicación
      );
      print('🔌 Socket de tracking inicializado');
    } catch (e) {
      print('❌ Error al inicializar socket: $e');
    }
  }

  Future<void> sendLocationUpdate(Position position) async {
    if (!_mounted) return;
    
    final user = ref.read(userProvider);
    if (user?.esMicrero != true || _trackingService == null) return;

    // CORREGIDO: Obtener ID de ruta activa desde SharedPreferences (ruta seleccionada en dashboard)
    String rutaId = 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d'; // Default: Ruta B de los logs
    try {
      final prefs = await SharedPreferences.getInstance();
      final rutaActivaId = prefs.getString('ruta_activa_id');
      if (rutaActivaId != null && rutaActivaId.isNotEmpty) {
        rutaId = rutaActivaId; // Usar ID exacto de la ruta seleccionada
        print('🛣️ Ruta activa encontrada en SharedPreferences: $rutaId');
      } else {
        print('⚠️ No hay ruta activa guardada, usando fallback: $rutaId');
      }
    } catch (e) {
      print('⚠️ Error obteniendo ruta activa: $e');
    }

    final locationData = {
      'id_micro': user!.microId!,
      'latitud': position.latitude,
      'longitud': position.longitude,
      'altura': position.altitude,
      'precision': position.accuracy,
      'bateria': 100.0,
      'imei': 'flutter-device-${user.id}',
      'fuente': 'app_flutter_employee',
      'id_ruta': rutaId, // CRÍTICO: Usar el ID exacto de la ruta
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_trackingService!.isConnected) {
      _trackingService!.sendLocationUpdate(locationData);
      print('✅ Ubicación enviada vía socket - Ruta: $rutaId');
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