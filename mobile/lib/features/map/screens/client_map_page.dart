import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:go_router/go_router.dart';

import '../../../common/utils.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../providers/entidad_id_provider.dart';
import '../../providers/ruta_provider.dart';
import '../../../services/tracking_socket_service.dart';
import '../services/client_tracking_service.dart';
import '../widgets/client_search_bar.dart';
import '../widgets/client_debug_buttons.dart';
import '../widgets/client_route_info.dart';

class ClientMapPage extends StatelessWidget {
  const ClientMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClientMap();
  }
}

class ClientMap extends ConsumerStatefulWidget {
  const ClientMap({super.key});

  @override
  ConsumerState<ClientMap> createState() => _ClientMapState();
}

class _ClientMapState extends ConsumerState<ClientMap> {
  // ========== CONTROLADORES Y SERVICIOS ==========
  MapLibreMapController? _controller;
  final Completer<MapLibreMapController> mapController = Completer();
  ClientTrackingService? _trackingService;
  
  // ========== ESTADO DEL MAPA ==========
  bool canInteractWithMap = false;
  Line? _routeLine;
  bool _shouldShowRoute = true;
  bool _socketInitialized = false;
  
  // ========== CONFIGURACIÓN ==========
  final Future<String> styles = initStyle();

  @override
  void initState() {
    super.initState();
    print('🗺️ Mapa cliente inicializado - Socket NO iniciado aún');
  }

  @override
  void dispose() {
    _trackingService?.dispose();
    if (mapController.isCompleted) {
      mapController.future.then((controller) {
        controller.dispose();
      });
    }
    super.dispose();
  }

  // ========== INICIALIZACIÓN DEL SOCKET (SOLO CUANDO SE NECESITE) ==========
  
  Future<void> _initializeTrackingForRoute(String routeId) async {
    if (_socketInitialized) {
      print('🔄 Socket ya inicializado, uniéndose a nueva ruta...');
      _trackingService?.joinRouteTracking(routeId, context);
      return;
    }

    print('🚀 Inicializando socket para seguir ruta: $routeId');
    
    try {
      _trackingService = ClientTrackingService(ref);
      await _trackingService!.initializeTracking();
      
      // Esperar un momento para que la conexión se establezca
      await Future.delayed(const Duration(seconds: 2));
      
      if (_trackingService!.isConnected) {
        _trackingService!.joinRouteTracking(routeId, context);
        _socketInitialized = true;
        print('✅ Socket inicializado y unido a ruta: $routeId');
      } else {
        print('⚠️ Socket no pudo conectarse');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No se pudo conectar al servidor de tracking'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error inicializando tracking: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<String> initStyle() async {
    try {
      final file = await copyAssetToFile('assets/maplibre/santa_cruz.mbtiles');
      String styleFile = await leerArchivoAssets('assets/maplibre/style.json');
      styleFile = styleFile.replaceAll('___FILE_URI___', 'mbtiles:///${file.path}');
      return styleFile;
    } catch (e) {
      print("Error initializing style: $e");
      return "";
    }
  }

  // ========== MANEJO DEL MAPA ==========
  
  void _onMapCreated(MapLibreMapController controller) {
    mapController.complete(controller);
    _loadImages(controller);
  }

  void _onStyleLoaded() {
    setState(() => canInteractWithMap = true);
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

  // ========== GESTIÓN DE RUTAS ==========
  
  Future<void> _drawRouteOnMap(List<LatLng> points) async {
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

  Future<void> _addRouteMarkers(List<LatLng> points, String rutaNombre) async {
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

  // ========== CALLBACKS ==========
  
  void _onSearchTap() async {
    print('🔍 Abriendo búsqueda de rutas...');
    
    setState(() {
      _shouldShowRoute = true;
    });
    
    final result = await context.push("/search-route");
    if (result == true) {
      print('✅ Invalidando providers para recargar ruta...');
      ref.invalidate(entidadIdProvider);
      ref.invalidate(searchRutasProvider);
    }
  }

  void _onRouteCleared() async {
    setState(() {
      _shouldShowRoute = false;
    });
    
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

  // ========== BUILD ==========
  
  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en la ruta seleccionada
    ref.listen<AsyncValue<List<dynamic>>>(searchRutasProvider, (previous, next) {
      if (!_shouldShowRoute) return;
      
      next.when(
        data: (rutas) {
          if (rutas.isNotEmpty) {
            final ruta = rutas.first;
            
            print('🛣️ Ruta seleccionada: ${ruta.nombre} (${ruta.id})');
            print('🚀 Iniciando socket para tracking de esta ruta...');
            
            // NUEVO FLUJO: Inicializar socket solo cuando se selecciona ruta
            _initializeTrackingForRoute(ruta.id);
            
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final points = parseVertices(ruta.vertices);
                if (points.isNotEmpty) {
                  await _drawRouteOnMap(points);
                  await _addRouteMarkers(points, ruta.nombre);
                }
              } catch (e) {
                print('❌ Error dibujando ruta: $e');
              }
            });
          }
        },
        loading: () => print('⏳ Cargando rutas...'),
        error: (error, stack) => print('❌ Error cargando rutas: $error'),
      );
    });

    // Escuchar actualizaciones de tracking para marcadores (solo si está inicializado)
    if (_socketInitialized && _trackingService != null) {
      _trackingService!.trackingService?.on(TrackingEventType.locationUpdate).listen((data) async {
        if (mapController.isCompleted) {
          final controller = await mapController.future;
          await _trackingService!.updateMicroLocationOnMap(controller, data);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Cliente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<String>(
        future: styles,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Stack(
              children: [
                // Mapa principal
                MapLibreMap(
                  onMapCreated: _onMapCreated,
                  styleString: snapshot.data!,
                  initialCameraPosition: const CameraPosition(
                    zoom: 13.0,
                    target: LatLng(-17.78314, -63.18084),
                  ),
                  trackCameraPosition: true,
                  minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
                  onStyleLoadedCallback: _onStyleLoaded,
                ),
                
                // Barra de búsqueda
                ClientSearchBar(onSearchTap: _onSearchTap),
                
                // Botones de debug
                ClientDebugButtons(onRouteCleared: _onRouteCleared),
                
                // Información de ruta
                const ClientRouteInfo(),
              ],
            );
          }
          
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
} 