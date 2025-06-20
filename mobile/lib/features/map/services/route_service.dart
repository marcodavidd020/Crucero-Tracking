import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
import '../../../services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/map_state_provider.dart';

class RouteService {
  final WidgetRef ref;
  bool _mounted = true;

  RouteService(this.ref);

  void dispose() {
    _mounted = false;
  }

  // ========== ROUTE MANAGEMENT ==========
  
  Future<void> loadMyRoute(MapLibreMapController controller) async {
    final mapState = ref.read(mapStateProvider);
    if (!mapState.mapReady) {
      print('⚠️ Mapa no está listo para cargar ruta');
      return;
    }
    
    final user = ref.read(userProvider);
    if (user?.esMicrero != true) return;

    try {
      // Verificar ruta específica seleccionada
      final prefs = await SharedPreferences.getInstance();
      final rutaActivaId = prefs.getString('ruta_activa_id');
      
      if (rutaActivaId != null && user?.entidadId != null) {
        final rutaData = await _fetchSpecificRoute(user!.entidadId!, rutaActivaId);
        if (rutaData != null) {
          await _drawRouteOnMap(controller, rutaData);
          _updateUserWithRoute(rutaData);
          return;
        }
      }
      
      // Fallback: cargar primera ruta disponible
      await _loadFirstAvailableRoute(controller, user!);
      
    } catch (e) {
      print('❌ Error cargando ruta: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchSpecificRoute(String entidadId, String rutaId) async {
    try {
      final response = await ApiService(baseUrl: baseUrl).get('ruta/$entidadId');
      
      if (response['data']?['rutas'] != null) {
        final List<dynamic> rutas = response['data']['rutas'];
        return rutas.firstWhere(
          (ruta) => ruta['id'] == rutaId,
          orElse: () => null,
        );
      }
    } catch (e) {
      print('❌ Error obteniendo ruta específica: $e');
    }
    return null;
  }

  Future<void> _loadFirstAvailableRoute(MapLibreMapController controller, dynamic user) async {
    if (user?.entidadId == null) return;
    
    try {
      final response = await ApiService(baseUrl: baseUrl).get('ruta/${user.entidadId}');
      
      if (response['data']?['rutas'] != null) {
        final List<dynamic> rutas = response['data']['rutas'];
        if (rutas.isNotEmpty) {
          await _drawRouteOnMap(controller, rutas.first);
          _updateUserWithRoute(rutas.first);
        }
      }
    } catch (e) {
      print('❌ Error cargando primera ruta: $e');
    }
  }

  void _updateUserWithRoute(Map<String, dynamic> ruta) {
    final user = ref.read(userProvider);
    if (user != null) {
      final updatedUser = user.copyWith(rutaAsignada: ruta['nombre']);
      ref.read(userProvider.notifier).state = updatedUser;
    }
  }

  Future<void> _drawRouteOnMap(MapLibreMapController controller, Map<String, dynamic> ruta) async {
    try {
      final vertices = parseVertices(ruta['vertices']);
      if (vertices.isEmpty) return;

      // Remover ruta anterior
      final currentRoute = ref.read(mapStateProvider).routeLine;
      if (currentRoute != null) {
        await controller.removeLine(currentRoute);
      }

      // Dibujar nueva ruta
      final routeLine = await controller.addLine(LineOptions(
        geometry: vertices,
        lineColor: "#FF3333",
        lineWidth: 8.0,
        lineOpacity: 1.0,
      ));

      ref.read(mapStateProvider.notifier).setRouteLine(routeLine);
      
      await _addRouteMarkers(controller, vertices);
      await _centerMapOnRoute(controller, vertices);
      
      print('✅ Ruta dibujada: ${ruta['nombre']}');
      
    } catch (e) {
      print('❌ Error dibujando ruta: $e');
    }
  }

  Future<void> _addRouteMarkers(MapLibreMapController controller, List<LatLng> vertices) async {
    if (vertices.length < 2) return;
    
    try {
      await controller.addSymbol(SymbolOptions(
        geometry: vertices.first,
        textField: "🏁 INICIO",
        textSize: 14,
        textColor: "#FFFFFF",
        textHaloColor: "#00C851",
        textHaloWidth: 3,
        textOffset: const Offset(0, -1),
        textAnchor: "center",
      ));
      
      await controller.addSymbol(SymbolOptions(
        geometry: vertices.last,
        textField: "🏁 FIN",
        textSize: 14,
        textColor: "#FFFFFF",
        textHaloColor: "#FF4444",
        textHaloWidth: 3,
        textOffset: const Offset(0, -1),
        textAnchor: "center",
      ));
      
    } catch (e) {
      print('❌ Error agregando marcadores de ruta: $e');
    }
  }

  Future<void> _centerMapOnRoute(MapLibreMapController controller, List<LatLng> vertices) async {
    if (vertices.isEmpty) return;
    
    double minLat = vertices.map((v) => v.latitude).reduce(min);
    double maxLat = vertices.map((v) => v.latitude).reduce(max);
    double minLng = vertices.map((v) => v.longitude).reduce(min);
    double maxLng = vertices.map((v) => v.longitude).reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, left: 80, top: 80, right: 80, bottom: 120)
      );
    } catch (e) {
      print('⚠️ Error centrando mapa en ruta: $e');
    }
  }

  // ========== UTILITIES ==========
  
  List<LatLng> parseVertices(String verticesJson) {
    try {
      final List<dynamic> data = json.decode(verticesJson);
      final List<LatLng> vertices = [];
      
      for (final vertex in data) {
        if (vertex is Map<String, dynamic>) {
          if (vertex.containsKey('lat') && vertex.containsKey('lng')) {
            vertices.add(LatLng(
              (vertex['lat'] as num).toDouble(),
              (vertex['lng'] as num).toDouble(),
            ));
          } else if (vertex.containsKey('latitude') && vertex.containsKey('longitude')) {
            vertices.add(LatLng(
              (vertex['latitude'] as num).toDouble(),
              (vertex['longitude'] as num).toDouble(),
            ));
          }
        } else if (vertex is List && vertex.length >= 2) {
          vertices.add(LatLng(
            (vertex[0] as num).toDouble(),
            (vertex[1] as num).toDouble(),
          ));
        }
      }
      
      return vertices;
    } catch (e) {
      print('❌ Error parseando vertices: $e');
      return [];
    }
  }
} 