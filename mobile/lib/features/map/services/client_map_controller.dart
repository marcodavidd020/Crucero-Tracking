import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../providers/map_state_provider.dart';

class ClientMapController {
  final WidgetRef ref;
  final Completer<MapLibreMapController> mapController = Completer();
  
  bool get isCompleted => mapController.isCompleted;
  Future<MapLibreMapController> get future => mapController.future;
  
  Line? _routeLine;
  bool canInteractWithMap = false;

  ClientMapController(this.ref);

  // ========== INITIALIZATION ==========
  
  void onMapCreated(MapLibreMapController controller) {
    mapController.complete(controller);
    _loadImages(controller);
  }

  void onStyleLoaded() {
    canInteractWithMap = true;
    ref.read(mapStateProvider.notifier).setMapReady(true);
  }

  static Future<String> initStyle() async {
    try {
      // Usar estilo online de MapTiler (recomendado)
      String primaryStyle = "https://api.maptiler.com/maps/streets-v2/style.json?key=MzhKbzEOi3IDm2v3qyrm";
      print("🗺️ Cargando estilo del mapa: $primaryStyle");
      return primaryStyle;
    } catch (e) {
      print("❌ Error initializing style: $e");
      // Fallback a un estilo básico de MapLibre si falla
      String fallbackStyle = "https://demotiles.maplibre.org/style.json";
      print("🔄 Usando estilo de fallback: $fallbackStyle");
      return fallbackStyle;
    }
  }

  Future<void> _loadImages(MapLibreMapController controller) async {
    try {
      await controller.addImage(
        "bus-marker",
        await _loadImageFromAsset("assets/images/bus-marker.png"),
      );
    } catch (e) {
      print("Error loading images: $e");
    }
  }

  Future<Uint8List> _loadImageFromAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      print("Error loading asset: $e");
      return Uint8List(0);
    }
  }

  // ========== ROUTE DRAWING ==========
  
  Future<void> drawRouteOnMap(List<LatLng> points) async {
    print('🗺️ === INICIANDO DIBUJO DE RUTA ===');
    print('📍 Número de puntos recibidos: ${points.length}');
    
    if (points.isEmpty || !mapController.isCompleted) {
      print('⚠️ No hay puntos o el mapa no está listo');
      return;
    }

    try {
      final controller = await mapController.future;

      // Eliminar ruta anterior
      if (_routeLine != null) {
        await controller.removeLine(_routeLine!);
        _routeLine = null;
      }

      // Dibujar nueva ruta
      _routeLine = await controller.addLine(LineOptions(
        geometry: points,
        lineColor: "#007AFF",
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ));

      // Ajustar cámara
      if (points.length >= 2) {
        final bounds = _calculateBounds(points);
        await controller.animateCamera(CameraUpdate.newLatLngBounds(
          bounds,
          left: 50,
          right: 50,
          top: 100,
          bottom: 50,
        ));
      }

      print('✅ Ruta dibujada exitosamente');
    } catch (e) {
      print('❌ Error dibujando ruta: $e');
    }
  }

  Future<void> addRouteMarkers(List<LatLng> points, String rutaNombre) async {
    if (points.isEmpty || !mapController.isCompleted) return;

    try {
      final controller = await mapController.future;
      
      // Marcador de inicio
      if (points.isNotEmpty) {
        await controller.addSymbol(SymbolOptions(
          geometry: points.first,
          textField: '🟢 INICIO',
          textSize: 12,
          textColor: '#FFFFFF',
          textHaloColor: '#000000',
          textHaloWidth: 2,
          textOffset: const Offset(0, 2),
        ));
      }
      
      // Marcador de fin
      if (points.length > 1) {
        await controller.addSymbol(SymbolOptions(
          geometry: points.last,
          textField: '🔴 FIN',
          textSize: 12,
          textColor: '#FFFFFF',
          textHaloColor: '#000000',
          textHaloWidth: 2,
          textOffset: const Offset(0, 2),
        ));
      }
      
    } catch (e) {
      print('❌ Error agregando marcadores: $e');
    }
  }

  Future<void> clearRoute() async {
    if (!mapController.isCompleted) return;

    try {
      final controller = await mapController.future;
      
      if (_routeLine != null) {
        await controller.removeLine(_routeLine!);
        _routeLine = null;
        print('✅ Ruta eliminada del mapa');
      }
    } catch (e) {
      print('❌ Error al limpiar ruta: $e');
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // ========== CLEANUP ==========
  
  // ========== MICRO TRACKING ==========
  
  Future<void> updateMicroLocationOnMap(Map<String, dynamic> locationData) async {
    if (!mapController.isCompleted) return;
    
    try {
      final controller = await mapController.future;
      
      // El backend envía routeLocationUpdate con esta estructura:
      // {routeId: ..., microId: ..., location: {...}, timestamp: ...}
      final microId = locationData['microId'] ?? locationData['id_micro'];
      final location = locationData['location'] ?? locationData;
      
      // Extraer coordenadas del objeto location o directamente del data
      final lat = location['latitud']?.toDouble() ?? locationData['latitud']?.toDouble();
      final lng = location['longitud']?.toDouble() ?? locationData['longitud']?.toDouble();
      
      if (lat == null || lng == null) {
        print('⚠️ Datos de ubicación inválidos: $locationData');
        return;
      }
      
      print('🚌 Actualizando ubicación del micro $microId: $lat, $lng');
      
      // Remover marcador anterior si existe
      await _removePreviousMarker(controller, microId);
      
      // Agregar nuevo marcador
      await controller.addSymbol(SymbolOptions(
        geometry: LatLng(lat, lng),
        iconImage: 'bus-marker',
        iconSize: 0.8,
        textField: '🚌',
        textSize: 20,
        textColor: '#FFFFFF',
        textHaloColor: '#FF0000',
        textHaloWidth: 2,
        textOffset: const Offset(0, -2),
      ));
      
      print('✅ Marcador actualizado en el mapa');
      
    } catch (e) {
      print('❌ Error actualizando marcador: $e');
    }
  }

  Future<void> _removePreviousMarker(
    MapLibreMapController controller, 
    String microId
  ) async {
    try {
      // Obtener todos los símbolos y remover los del micro específico
      final symbols = await controller.symbols;
      for (final symbol in symbols) {
        if (symbol.options.textField?.contains('🚌') == true) {
          await controller.removeSymbol(symbol);
        }
      }
    } catch (e) {
      print('⚠️ Error removiendo marcador anterior: $e');
    }
  }

  // ========== CLEANUP ==========
  
  void dispose() {
    print('🧹 Iniciando limpieza del ClientMapController');
    
    if (mapController.isCompleted) {
      mapController.future.then((controller) {
        try {
          controller.dispose();
          print('✅ MapController limpiado');
        } catch (e) {
          print('⚠️ Error limpiando MapController: $e');
        }
      }).catchError((e) {
        print('⚠️ Error obteniendo MapController para limpiar: $e');
      });
    }
    
    print('✅ ClientMapController dispose completado');
  }
} 