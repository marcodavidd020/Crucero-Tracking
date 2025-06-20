import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/map_state_provider.dart';

class LocationService {
  final WidgetRef ref;
  Timer? _locationTimer;
  bool _mounted = true;

  LocationService(this.ref);

  void dispose() {
    _mounted = false;
    _locationTimer?.cancel();
  }

  // ========== PERMISSIONS ==========
  
  Future<bool> checkLocationPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied && 
           permission != LocationPermission.deniedForever;
  }

  // ========== LOCATION TRACKING ==========
  
  Future<void> startLocationTracking() async {
    // Obtener ubicación inicial
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_mounted) {
        ref.read(mapStateProvider.notifier).setCurrentPosition(position);
      }
    } catch (e) {
      print('❌ Error obteniendo ubicación inicial: $e');
    }
    
    // Iniciar timer de ubicación
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_mounted || !ref.read(mapStateProvider).isServiceActive) {
        timer.cancel();
        return;
      }
      _updateLocation();
    });
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!_mounted) return;

      print('📍 Ubicación: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)} (±${position.accuracy.toStringAsFixed(1)}m)');

      // Actualizar estado
      ref.read(mapStateProvider.notifier).setCurrentPosition(position);

    } catch (e) {
      print('❌ Error actualizando ubicación: $e');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Error obteniendo posición actual: $e');
      return null;
    }
  }
} 