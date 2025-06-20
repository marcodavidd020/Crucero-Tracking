import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../providers/map_state_provider.dart';

class MarkerService {
  final WidgetRef ref;
  Timer? _markerHealthTimer;
  bool _mounted = true;
  
  // Control de marcador mejorado
  Symbol? _currentMarker;
  Line? _markerCircle;
  DateTime? _lastMarkerUpdate;
  static const Duration _markerUpdateThrottle = Duration(seconds: 1);

  MarkerService(this.ref);

  void dispose() {
    _mounted = false;
    _markerHealthTimer?.cancel();
  }

  // ========== MARKER MANAGEMENT ==========
  
  Future<void> updateMarkerPosition(MapLibreMapController controller, Position position) async {
    if (!_mounted) return;

    // Control de throttling
    final now = DateTime.now();
    if (_lastMarkerUpdate != null && 
        now.difference(_lastMarkerUpdate!) < _markerUpdateThrottle) {
      return;
    }
    _lastMarkerUpdate = now;

    await _updateMarkerLocation(controller, position);
  }

  Future<void> _updateMarkerLocation(MapLibreMapController controller, Position position) async {
    final location = LatLng(position.latitude, position.longitude);
    
    try {
      // Si no hay marcador, crear uno nuevo con estrategia múltiple
      if (_currentMarker == null) {
        await _createMarkerWithFallbacks(controller, location);
        return;
      }

      // Actualizar marcador existente
      await controller.updateSymbol(_currentMarker!, SymbolOptions(
        geometry: location,
      ));

      // Actualizar círculo si existe
      if (_markerCircle != null) {
        await _updateMarkerCircle(controller, location);
      }

      print('🎯 Marcador actualizado: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}');

    } catch (e) {
      print('❌ Error actualizando marcador: $e');
      // Si falla, recrear con estrategia completa
      await _recreateMarkerWithFallbacks(controller, location);
    }
  }

  Future<void> _createMarkerWithFallbacks(MapLibreMapController controller, LatLng location) async {
    // Nivel 1: Emoji con fondo
    if (await _createEmojiMarker(controller, location)) return;
    
    // Nivel 2: Texto con halo
    if (await _createTextMarker(controller, location)) return;
    
    // Nivel 3: Círculo geométrico (garantizado)
    await _createGeometricMarker(controller, location);
  }

  Future<bool> _createEmojiMarker(MapLibreMapController controller, LatLng location) async {
    try {
      _currentMarker = await controller.addSymbol(SymbolOptions(
        geometry: location,
        textField: '🚌',
        textColor: '#FFFFFF',
        textSize: 28.0,
        textHaloColor: '#FF0000',
        textHaloWidth: 6.0,
        textOffset: const Offset(0, 0),
        textAnchor: 'center',
      ));

      ref.read(mapStateProvider.notifier).setCurrentLocationSymbol(_currentMarker);
      print('✅ Marcador emoji creado');
      return true;

    } catch (e) {
      print('⚠️ Fallo marcador emoji: $e');
      return false;
    }
  }

  Future<bool> _createTextMarker(MapLibreMapController controller, LatLng location) async {
    try {
      _currentMarker = await controller.addSymbol(SymbolOptions(
        geometry: location,
        textField: 'MICRO',
        textColor: '#FFFFFF',
        textSize: 18.0,
        textHaloColor: '#FF0000',
        textHaloWidth: 4.0,
        textOffset: const Offset(0, 0),
        textAnchor: 'center',
      ));

      ref.read(mapStateProvider.notifier).setCurrentLocationSymbol(_currentMarker);
      print('✅ Marcador texto creado');
      return true;

    } catch (e) {
      print('⚠️ Fallo marcador texto: $e');
      return false;
    }
  }

  Future<void> _createGeometricMarker(MapLibreMapController controller, LatLng location) async {
    try {
      // Crear círculo rojo como marcador geométrico
      final circlePoints = _generateCirclePoints(location, 0.0001); // ~10 metros de radio
      
      _markerCircle = await controller.addLine(LineOptions(
        geometry: circlePoints,
        lineColor: "#FF0000",
        lineWidth: 8.0,
        lineOpacity: 1.0,
      ));

      // Agregar texto en el centro
      _currentMarker = await controller.addSymbol(SymbolOptions(
        geometry: location,
        textField: 'MICRO',
        textColor: '#FFFFFF',
        textSize: 14.0,
        textHaloColor: '#000000',
        textHaloWidth: 2.0,
        textOffset: const Offset(0, 0),
        textAnchor: 'center',
      ));

      ref.read(mapStateProvider.notifier).setCurrentLocationSymbol(_currentMarker);
      print('✅ Marcador geométrico creado (círculo + texto)');

    } catch (e) {
      print('❌ Error crítico creando marcador geométrico: $e');
    }
  }

  List<LatLng> _generateCirclePoints(LatLng center, double radius) {
    final points = <LatLng>[];
    const int numPoints = 20;
    
    for (int i = 0; i <= numPoints; i++) {
      final angle = (i * 2 * pi) / numPoints;
      final lat = center.latitude + radius * cos(angle);
      final lng = center.longitude + radius * sin(angle);
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  Future<void> _updateMarkerCircle(MapLibreMapController controller, LatLng location) async {
    if (_markerCircle == null) return;
    
    try {
      final circlePoints = _generateCirclePoints(location, 0.0001);
      await controller.updateLine(_markerCircle!, LineOptions(
        geometry: circlePoints,
      ));
    } catch (e) {
      print('⚠️ Error actualizando círculo: $e');
    }
  }

  Future<void> _recreateMarkerWithFallbacks(MapLibreMapController controller, LatLng location) async {
    await clearMarker(controller);
    await _createMarkerWithFallbacks(controller, location);
  }

  Future<void> clearMarker(MapLibreMapController? controller) async {
    if (controller == null) return;
    
    // Limpiar marcador de texto/emoji
    if (_currentMarker != null) {
      try {
        await controller.removeSymbol(_currentMarker!);
        print('🗑️ Marcador removido');
      } catch (e) {
        print('⚠️ Error removiendo marcador: $e');
      }
    }
    
    // Limpiar círculo geométrico
    if (_markerCircle != null) {
      try {
        await controller.removeLine(_markerCircle!);
        print('🗑️ Círculo marcador removido');
      } catch (e) {
        print('⚠️ Error removiendo círculo: $e');
      }
    }
    
    _currentMarker = null;
    _markerCircle = null;
    ref.read(mapStateProvider.notifier).resetMarkerState();
  }

  // ========== MARKER HEALTH CHECK ==========
  
  void initializeMarkerHealthCheck(MapLibreMapController controller) {
    if (!_mounted) return;
    
    _markerHealthTimer?.cancel();
    _markerHealthTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_mounted || !ref.read(mapStateProvider).isServiceActive) {
        timer.cancel();
        return;
      }
      
      await _checkMarkerHealth(controller);
    });
  }

  Future<void> _checkMarkerHealth(MapLibreMapController controller) async {
    final currentPosition = ref.read(mapStateProvider).currentPosition;
    if (currentPosition == null) return;

    // Si no hay marcador pero debería haberlo, recrearlo
    if (_currentMarker == null) {
      print('🔧 Health check: Recreando marcador faltante');
      final location = LatLng(currentPosition.latitude, currentPosition.longitude);
      await _createMarkerWithFallbacks(controller, location);
    }
  }

  // ========== CAMERA CONTROLS ==========
  
  Future<void> centerOnMarker(MapLibreMapController controller) async {
    final currentPosition = ref.read(mapStateProvider).currentPosition;
    if (currentPosition == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(currentPosition.latitude, currentPosition.longitude), 
        16.0
      ),
      duration: const Duration(milliseconds: 800),
    );
    
    ref.read(mapStateProvider.notifier).setFollowMicro(true);
  }

  Future<void> updateCameraIfFollowing(MapLibreMapController controller, Position position) async {
    final mapState = ref.read(mapStateProvider);
    if (!mapState.followMicro) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      print('⚠️ Error moviendo cámara: $e');
    }
  }
} 