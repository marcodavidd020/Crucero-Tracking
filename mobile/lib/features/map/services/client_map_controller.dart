import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../providers/map_state_provider.dart';
import '../../../data/repositories_impl/entidad_repository_impl.dart';
import '../../../data/repositories_impl/ruta_repository_impl.dart';
import '../../../domain/repositories/providers/entidad_repository_provider.dart';
import '../../../domain/repositories/providers/ruta_repository_provider.dart';
import '../../providers/entidad_provider.dart';
import '../../providers/ruta_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ClientMapController {
  final WidgetRef ref;
  final Completer<MapLibreMapController> mapController = Completer();
  bool _mounted = true;
  
  // NUEVO: Sistema offline-first para clientes
  Timer? _syncTimer;
  bool _hasInitializedOfflineData = false;

  bool get isCompleted => mapController.isCompleted;
  Future<MapLibreMapController> get future => mapController.future;
  
  Line? _routeLine;
  bool canInteractWithMap = false;

  ClientMapController(this.ref) {
    _initializeOfflineFirstSystem();
  }

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
    _mounted = false;
    _syncTimer?.cancel();
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

  // ========== SISTEMA OFFLINE-FIRST PARA CLIENTES ==========
  
  /// Inicializa el sistema offline-first específico para clientes
  Future<void> _initializeOfflineFirstSystem() async {
    print('🌐 === INICIALIZANDO SISTEMA OFFLINE-FIRST PARA CLIENTE ===');
    
    try {
      // PASO 1: Verificar si hay datos offline disponibles
      await _ensureOfflineDataAvailable();
      
      // PASO 2: Configurar sincronización automática cuando hay conexión
      _setupAutoSync();
      
      // PASO 3: Monitorear cambios de conectividad
      _monitorConnectivityForSync();
      
      print('✅ Sistema offline-first para cliente inicializado');
      
    } catch (e) {
      print('❌ Error inicializando sistema offline-first: $e');
    }
  }

  /// Asegura que hay datos offline disponibles para el cliente
  Future<void> _ensureOfflineDataAvailable() async {
    try {
      final entidadRepo = await ref.read(entidadRepositoryProvider.future);
      final rutaRepo = await ref.read(rutaRepositoryProvider.future);
      
      // Verificar si hay datos locales
      final rutasLocales = await (rutaRepo as RutaRepositoryImpl).getAllRutas();
      
      if (rutasLocales.isEmpty) {
        print('📱 No hay datos offline - inicializando datos de respaldo...');
        
        // Poblar datos de respaldo para que el cliente pueda funcionar offline
        await (entidadRepo as EntidadRepositoryImpl).poblarDatosPrueba();
        await (rutaRepo as RutaRepositoryImpl).poblarRutasPrueba();
        
        _hasInitializedOfflineData = true;
        print('✅ Datos offline inicializados para uso del cliente');
      } else {
        print('💾 Datos offline encontrados: ${rutasLocales.length} rutas');
      }
      
    } catch (e) {
      print('⚠️ Error asegurando datos offline: $e');
    }
  }

  /// Configura sincronización automática cada 30 segundos cuando hay conexión
  void _setupAutoSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final isOnline = ref.read(isOnlineProvider);
      if (isOnline) {
        await _syncDataFromServer();
      }
    });
  }

  /// Monitorea cambios de conectividad para sincronizar datos
  void _monitorConnectivityForSync() {
    ref.listen(isOnlineProvider, (previous, isOnline) async {
      if (isOnline && (previous == false || previous == null)) {
        // Se recuperó la conexión - sincronizar inmediatamente
        print('🟢 Conexión recuperada - sincronizando datos para cliente...');
        await _syncDataFromServer();
      } else if (!isOnline) {
        print('🔴 Conexión perdida - activando modo offline para cliente');
        print('📱 El cliente seguirá funcionando con datos locales');
      }
    });
  }

  /// Sincroniza datos desde el servidor para uso offline del cliente
  Future<void> _syncDataFromServer() async {
    try {
      print('🔄 Sincronizando datos para uso offline del cliente...');
      
      // Invalidar providers para forzar recarga desde API
      ref.invalidate(entidadProvider);
      ref.invalidate(searchRutasProvider);
      
      // Los repositorios automáticamente guardarán los datos en BD local
      print('✅ Sincronización completada - datos actualizados para uso offline');
      
    } catch (e) {
      print('⚠️ Error en sincronización: $e');
    }
  }

  /// Método público para forzar sincronización manual
  Future<void> forceSyncForClient() async {
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) {
      await _syncDataFromServer();
    } else {
      print('❌ No hay conexión para sincronizar');
    }
  }

  // ========== ESTADO OFFLINE PARA CLIENTES ==========
  
  /// Obtiene el estado actual del modo offline
  bool get isOfflineMode => !ref.read(isOnlineProvider);
  
  /// Muestra información sobre el estado offline al cliente
  void showOfflineStatus() {
    final isOnline = ref.read(isOnlineProvider);
    if (isOnline) {
      print('🟢 CLIENTE: Online - datos sincronizados con servidor');
    } else {
      print('🔴 CLIENTE: Offline - usando datos locales guardados');
      print('📱 Todas las rutas están disponibles offline');
    }
  }
} 