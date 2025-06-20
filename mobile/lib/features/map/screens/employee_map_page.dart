import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../common/widgets/app_drawer.dart';
import '../../../config/constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/map_state_provider.dart';
import '../services/map_service.dart';
import '../widgets/map_status_indicator.dart';
import '../widgets/driver_info_panel.dart';
import '../widgets/map_floating_buttons.dart';

class EmployeeMapPage extends ConsumerStatefulWidget {
  const EmployeeMapPage({super.key});

  @override
  ConsumerState<EmployeeMapPage> createState() => _EmployeeMapPageState();
}

class _EmployeeMapPageState extends ConsumerState<EmployeeMapPage> {
  final Completer<MapLibreMapController> mapController = Completer();
  MapService? _mapService;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _mounted = false;
    _mapService?.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _mapService = MapService(ref);
  }

  void _onMapCreated(MapLibreMapController controller) async {
    if (!mapController.isCompleted) {
      mapController.complete(controller);
    }
    
    // Inicializar mapa con el servicio
    if (_mapService != null) {
      await _mapService!.initializeMap(controller);
    }
  }

  void _onStyleLoaded() {
    // Cargar ruta después de que el estilo esté cargado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mapController.isCompleted && _mapService != null) {
        final controller = await mapController.future;
        await _mapService!.loadRoute(controller);
      }
    });
  }

  Future<void> _toggleTracking() async {
    final mapState = ref.read(mapStateProvider);
    
    if (mapState.isServiceActive) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    if (_mapService == null || !_mounted) return;
    
    try {
      await _mapService!.startTracking();
      
      if (_mounted) {
        _showSuccess('Servicio de tracking iniciado');
      }
      
    } catch (e) {
      if (_mounted) {
        print('❌ Error al iniciar tracking: $e');
        _showError('Error al iniciar el servicio: ${e.toString()}');
      }
    }
  }

  Future<void> _stopTracking() async {
    if (_mapService == null) return;
    
    MapLibreMapController? controller;
    if (mapController.isCompleted) {
      controller = await mapController.future;
    }
    
    await _mapService!.stopTracking(controller);
    
    if (_mounted) {
      _showSuccess('Servicio de tracking detenido');
    }
  }

  Future<void> _centerOnMicro() async {
    if (_mapService == null || !mapController.isCompleted) return;
    
    final controller = await mapController.future;
    await _mapService!.centerOnMicro(controller);
  }

  void _showError(String message) {
    if (!_mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!_mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final mapState = ref.watch(mapStateProvider);

    // Escuchar cambios de posición y actualizar marcador + socket
    ref.listen(mapStateProvider.select((state) => state.currentPosition), (previous, next) async {
      if (next == null || !_mounted || _mapService == null) return;
      
      if (mapController.isCompleted) {
        final controller = await mapController.future;
        await _mapService!.handleLocationUpdate(controller, next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Micrero'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(mapState.isServiceActive ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleTracking,
            tooltip: mapState.isServiceActive ? 'Detener Tracking' : 'Iniciar Tracking',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Mapa principal
          MapLibreMap(
            onMapCreated: _onMapCreated,
            styleString: "$styleUrl?key=$apiKey",
            initialCameraPosition: const CameraPosition(
              zoom: 15.0,
              target: LatLng(-17.78314, -63.18084), // Santa Cruz
            ),
            trackCameraPosition: true,
            minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
            onStyleLoadedCallback: _onStyleLoaded,
          ),

          // Indicador de estado
          MapStatusIndicator(
            isServiceActive: mapState.isServiceActive,
            followMicro: mapState.followMicro,
          ),

          // Panel de información del conductor
          DriverInfoPanel(
            user: user,
            isServiceActive: mapState.isServiceActive,
          ),

          // Botón de acción principal
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _toggleTracking,
              icon: Icon(
                mapState.isServiceActive ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              label: Text(
                mapState.isServiceActive ? 'Detener Servicio' : 'Iniciar Servicio',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: mapState.isServiceActive ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Información de ubicación actual
          if (mapState.currentPosition != null)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lat: ${mapState.currentPosition!.latitude.toStringAsFixed(6)}\n'
                  'Lng: ${mapState.currentPosition!.longitude.toStringAsFixed(6)}\n'
                  'Precisión: ${mapState.currentPosition!.accuracy.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: MapFloatingButtons(
        isServiceActive: mapState.isServiceActive,
        followMicro: mapState.followMicro,
        onToggleTracking: _toggleTracking,
        onCenterOnMicro: _centerOnMicro,
      ),
    );
  }
}
