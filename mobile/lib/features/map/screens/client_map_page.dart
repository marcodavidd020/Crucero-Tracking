import 'dart:async';
import 'package:app_map_tracking/features/auth/providers/auth_provider.dart';
import 'package:app_map_tracking/features/providers/entidad_id_provider.dart';
import 'package:app_map_tracking/features/providers/entidad_provider.dart';
import 'package:app_map_tracking/features/tracking/providers/tracking_provider.dart';
import 'package:app_map_tracking/features/providers/ruta_provider.dart';
import 'package:app_map_tracking/services/tracking_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';

import '../../../common/utils.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../config/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:app_map_tracking/common/shared_preference_helper.dart';
import 'package:app_map_tracking/data/datasource/local/providers/entidad_local_datasource_provider.dart';
import 'package:app_map_tracking/data/datasource/local/providers/ruta_local_datasource_provider.dart';
import 'package:app_map_tracking/data/datasource/local/providers/isar_provider.dart';
import '../../../data/models/ruta_model.dart';
import '../../../data/repositories_impl/ruta_repository_impl.dart';
import '../../../domain/entities/entidad.dart';
import '../../../domain/entities/ruta.dart';
import '../../../domain/usecases/ruta_use_case.dart';
import '../../../data/repositories_impl/entidad_repository_impl.dart';
import '../../../data/repositories_impl/ruta_repository_impl.dart';
import '../../../domain/repositories/providers/entidad_repository_provider.dart';
import '../../../domain/repositories/providers/ruta_repository_provider.dart';

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
  MapLibreMapController? _controller;
  final Future<String> styles = initStyle();
  final Completer<MapLibreMapController> mapController = Completer();
  bool canInteractWithMap = false;
  Symbol? currentLocationSymbol;
  StreamSubscription? _locationSubscription;
  Line? _routeLine;
  bool _shouldShowRoute = true; // Variable para controlar si mostrar ruta automáticamente

  // Tracking en tiempo real
  TrackingSocketService? _trackingService;
  final Map<String, Symbol> _microMarkers = {}; // Mapa de marcadores de micros
  String? _selectedRouteId; // ID de la ruta seleccionada para tracking

  // ID de ejemplo, reemplazar por el id real de la ruta a mostrar
  VoidCallback? _routeListener;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
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
      // Retorna una imagen vacía para evitar errores
      return Uint8List(0);
    }
  }

  Future<void> _initializeTracking() async {
    try {
      _trackingService = TrackingSocketService();

      await _trackingService!.initSocket(
        'http://192.168.0.202:3001', // URL directa para socket
        'client-${DateTime.now().millisecondsSinceEpoch}', // ID único para cliente
        'jwt-token-placeholder', // TODO: Usar token real
        enableLocationTracking: false, // CLIENTE: NO envía ubicación, solo escucha
      );

      // IMPORTANTE: El cliente NO debe iniciar tracking automático
      // Solo debe escuchar las ubicaciones de los micros

      // Escuchar actualizaciones de ubicación de todos los micros
      _locationSubscription = _trackingService!
          .on(TrackingEventType.locationUpdate)
          .listen((data) {
        print('📍 Cliente recibió actualización general de ubicación: $data');
        _updateMicroLocationOnMap(data);
      });

      // Escuchar actualizaciones específicas de ruta (IMPORTANTE para ver choferes de la ruta)
      _trackingService!
          .on(TrackingEventType.routeLocationUpdate)
          .listen((data) {
        print('🛣️ Cliente recibió actualización de ruta específica: $data');
        _updateMicroLocationOnMap(data);
      });

      // ARREGLO: Escuchar también eventos de datos iniciales
      _trackingService!
          .on(TrackingEventType.initialTrackingData)
          .listen((data) {
        print('🎯 Cliente recibió datos iniciales de tracking: $data');
        _updateMicroLocationOnMap(data);
      });

      print('✅ Cliente conectado para recibir tracking en tiempo real (SOLO ESCUCHA)');

    } catch (e) {
      print("❌ Error inicializando tracking para cliente: $e");
    }
  }

  Future<void> _updateMicroLocationOnMap(dynamic data) async {
    try {
      if (!mapController.isCompleted) return;
      
      final controller = await mapController.future;
      
      // Extraer datos de ubicación con mejor manejo
      final microId = data['microId'] ?? data['id_micro'] ?? data['micro_id'] ?? 'unknown';
      final locationData = data['location'] ?? data;
      
      print('📍 Cliente procesando datos: microId=$microId, data=$data');
      
      // ARREGLO: Solo filtrar IDs que claramente son de clientes, no rechazar empleados
      if (microId.toString().toLowerCase().contains('client') || 
          microId.toString().toLowerCase().contains('cliente')) {
        print('⚠️ Ignorando ubicación de cliente: $microId');
        return;
      }
      
      // Extraer coordenadas con mejor manejo de tipos
      dynamic lat = locationData['latitud'] ?? locationData['lat'] ?? locationData['latitude'];
      dynamic lng = locationData['longitud'] ?? locationData['lng'] ?? locationData['longitude'];
      
      // Convertir a double de manera segura
      double? latDouble = lat is double ? lat : double.tryParse(lat.toString());
      double? lngDouble = lng is double ? lng : double.tryParse(lng.toString());
      
      if (latDouble == null || lngDouble == null || latDouble == 0.0 || lngDouble == 0.0) {
        print('⚠️ Coordenadas inválidas recibidas: lat=$lat, lng=$lng');
        return;
      }
      
      final location = LatLng(latDouble, lngDouble);
      print('✅ Coordenadas válidas procesadas: $latDouble, $lngDouble para micro $microId');
      
      // Remover marcador anterior si existe con mejor manejo de errores
      if (_microMarkers.containsKey(microId)) {
        try {
          await controller.removeSymbol(_microMarkers[microId]!);
          print('✅ Marcador anterior removido para $microId');
        } catch (e) {
          print('⚠️ Error removiendo marcador anterior para $microId: $e');
        }
        _microMarkers.remove(microId); // Limpiar referencia
      }

      // Verificar que la imagen está cargada antes de agregar el marcador
      try {
        // Agregar nuevo marcador
        final newMarker = await controller.addSymbol(SymbolOptions(
          geometry: location,
          iconImage: "bus-marker",
          iconSize: 2.5, // Marcador más grande para mejor visibilidad en cliente
          iconOffset: const Offset(0, -35),
          textField: '🚌 $microId',
          textSize: 14,
          textColor: '#FFFFFF',
          textHaloColor: '#007AFF',
          textHaloWidth: 2,
          textOffset: const Offset(0, 3),
        ));
        
        _microMarkers[microId] = newMarker;
        
        // CLIENTE: NO seguir automáticamente a los micros
        // Solo centrar si es el primer micro Y no hay una ruta visible
        if (_microMarkers.length == 1 && _routeLine == null) {
          print('📷 Centrando solo en primer micro (sin ruta visible): $microId');
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15.0),
          );
        } else {
          print('📍 Marcador actualizado sin mover cámara (Cliente): $microId');
        }
        
        print('✅ Marcador de micro $microId actualizado en: $latDouble, $lngDouble');

      } catch (e) {
        print('❌ Error creando marcador - intentando recargar imagen: $e');
        // Recargar imagen del bus y reintentar UNA SOLA VEZ
        try {
          await _loadImages(controller);
          
          // Reintentar crear el marcador
          final newMarker = await controller.addSymbol(SymbolOptions(
            geometry: location,
            iconImage: "bus-marker",
            iconSize: 2.5,
            iconOffset: const Offset(0, -35),
            textField: '🚌 $microId',
            textSize: 14,
            textColor: '#FFFFFF',
            textHaloColor: '#007AFF',
            textHaloWidth: 2,
            textOffset: const Offset(0, 3),
          ));
          
          _microMarkers[microId] = newMarker;
          print('✅ Marcador creado después de recargar imagen para $microId');
        } catch (retryError) {
          print('❌ Error en segundo intento para $microId: $retryError');
          // Fallback a marcador de texto simple
          final newMarker = await controller.addSymbol(SymbolOptions(
            geometry: location,
            textField: '🚌 $microId',
            textSize: 16,
            textColor: '#FFFFFF',
            textHaloColor: '#007AFF',
            textHaloWidth: 3,
          ));
          _microMarkers[microId] = newMarker;
        }
      }

    } catch (e) {
      print('❌ Error actualizando ubicación de micro en mapa: $e');
    }
  }

  Future<void> _joinRouteTracking(String routeId) async {
    try {
      if (_trackingService != null && _trackingService!.isConnected) {
        // Salir de la ruta anterior si había una
        if (_selectedRouteId != null) {
          _trackingService!.leaveRoute(_selectedRouteId!);
          print('🚪 Cliente salió de la ruta anterior: $_selectedRouteId');
        }
        
        // Unirse a la nueva ruta
        _trackingService!.joinRoute(routeId);
        _selectedRouteId = routeId;
        
        print('🛣️ Cliente unido a tracking de ruta: $routeId - Ahora recibirá ubicaciones de choferes');
        
        // ARREGLO: Configurar listener una sola vez (evitar múltiples listeners)
        _trackingService!.socket.off('joinedRoute'); // Remover listener anterior si existe
        _trackingService!.socket.on('joinedRoute', (data) {
          print('✅ Confirmación de unión a ruta: $data');
          
          // Mostrar feedback al usuario
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🛣️ Conectado a ruta: $routeId'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          
          // Si hay ubicaciones recientes, mostrarlas
          if (data['recentLocations'] != null && data['recentLocations'] is List) {
            print('📍 Procesando ${data['recentLocations'].length} ubicaciones recientes...');
            for (var location in data['recentLocations']) {
              _updateMicroLocationOnMap({
                'microId': location['id_micro'] ?? location['microId'],
                'location': location,
              });
            }
          }
        });
        
        // ARREGLO: También escuchar si hay errores al unirse
        _trackingService!.socket.off('error');
        _trackingService!.socket.on('error', (data) {
          print('❌ Error del socket: $data');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error de conexión: ${data['message'] ?? 'Desconocido'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
        
      } else {
        print('❌ No se puede unir a la ruta - socket no conectado');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No conectado al servidor de tracking'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error uniéndose al tracking de ruta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _drawRouteOnMap(List<LatLng> points) async {
    print('🗺️ === INICIANDO DIBUJO DE RUTA ===');
    print('📍 Número de puntos recibidos: ${points.length}');
    
    if (points.isEmpty) {
      print('⚠️ No hay puntos para dibujar');
      return;
    }

    if (!mapController.isCompleted) {
      print('⚠️ Controlador del mapa no está listo');
      return;
    }

    try {
      final controller = await mapController.future;
      print('✅ Controlador del mapa obtenido');

      // Elimina la línea anterior si existe
      if (_routeLine != null) {
        print('🗑️ Eliminando ruta anterior');
        await controller.removeLine(_routeLine!);
        _routeLine = null;
      }

      print('🎨 Dibujando nueva ruta con ${points.length} puntos');
      print('🚩 Punto inicial: ${points.first}');
      print('🏁 Punto final: ${points.last}');

      _routeLine = await controller.addLine(LineOptions(
        geometry: points,
        lineColor: "#007AFF", // Azul
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ));

      print('✅ Ruta dibujada exitosamente');

      // Ajustar la cámara para mostrar toda la ruta
      if (points.length >= 2) {
        final bounds = _calculateBounds(points);
        await controller.animateCamera(CameraUpdate.newLatLngBounds(
          bounds,
          left: 50,
          right: 50,
          top: 100,
          bottom: 50,
        ));
        print('📷 Cámara ajustada para mostrar toda la ruta');
      }

    } catch (e) {
      print('❌ Error dibujando ruta en el mapa: $e');
    }
    
    print('🗺️ === FIN DIBUJO DE RUTA ===');
  }

  // 📏 Función auxiliar para calcular los límites de la ruta
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

  // 📍 Función para agregar marcadores en los puntos de la ruta
  Future<void> _addRouteMarkers(List<LatLng> points, String rutaNombre) async {
    print('🗺️ === AGREGANDO MARCADORES DE RUTA ===');
    print('📍 Número de puntos: ${points.length}');
    print('🛣️ Ruta: $rutaNombre');
    
    if (points.isEmpty || !mapController.isCompleted) {
      print('⚠️ No hay puntos o el mapa no está listo');
      return;
    }

    try {
      final controller = await mapController.future;
      
      // Marcador de inicio 🟢
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
        print('✅ Marcador de inicio agregado');
      }
      
      // Marcador de fin 🔴
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
        print('✅ Marcador de fin agregado');
      }
      
      // Marcadores intermedios 🟡 (solo algunos para no saturar)
      if (points.length > 4) {
        final step = (points.length / 3).round();
        for (int i = step; i < points.length - 1; i += step) {
          await controller.addSymbol(SymbolOptions(
            geometry: points[i],
            textField: '🟡',
            textSize: 10,
            textOffset: const Offset(0, 1),
          ));
        }
        print('✅ Marcadores intermedios agregados');
      }
      
      print('🗺️ === MARCADORES AGREGADOS EXITOSAMENTE ===');
      
    } catch (e) {
      print('❌ Error agregando marcadores: $e');
    }
  }

  @override
  void dispose() {
    // Cancela la suscripción
    _locationSubscription?.cancel();
    
    // Salir del tracking de ruta si estaba unido
    if (_selectedRouteId != null && _trackingService != null) {
      _trackingService!.leaveRoute(_selectedRouteId!);
    }
    
    // Dispone el servicio de tracking
    _trackingService?.dispose();
    
    // Dispone el controlador del mapa
    if (mapController.isCompleted) {
      mapController.future.then((controller) {
        controller.dispose();
      });
    }
    
    super.dispose();
  }

  static Future<String> initStyle() async {
    try {
      // iniciarSeguimiento();
      final file = await copyAssetToFile('assets/maplibre/santa_cruz.mbtiles');
      String styleFile = await leerArchivoAssets('assets/maplibre/style.json');
      styleFile = styleFile.replaceAll('___FILE_URI___', 'mbtiles:///${file.path}');
      return styleFile;
    } catch (e) {
      print("Error initializing style: $e");
      return "";
    }
  }

  // Future<void> _addPolyline() async {
  //   final line = {
  //     "type": "FeatureCollection",
  //     "features": [
  //       {
  //         "type": "Feature",
  //         "properties": {},
  //         "geometry": {
  //           "type": "LineString",
  //           "coordinates": [
  //             [-63.1836952, -17.783915211],
  //             [-63.1838899, -17.781858371],
  //           ]
  //         }
  //       }
  //     ]
  //   };

  //   _controller.addGeoJsonSource("line-source", line);

  //   _controller?.addLine(const LineOptions(
  //       geometry: [
  //         LatLng(-17.783915211, -63.1836952),
  //         LatLng(-17.781858371, -63.1838899),
  //       ],
  //       lineColor: "#ff0000",
  //       lineWidth: 3.0,
  //       lineOpacity: 0.5,
  //       draggable: true),);
  // }
  @override
  Widget build(BuildContext context) {
    // 🎯 Escuchar cambios en la ruta seleccionada para dibujarla en el mapa
    ref.listen<Ruta?>(selectedRutaProvider, (previous, next) {
      if (next != null && _shouldShowRoute) {
        print('🎯 === RUTA SELECCIONADA CAMBIÓ ===');
        print('🛣️ Nueva ruta: ${next.nombre}');
        
        // Unirse al tracking de esta ruta
        _joinRouteTracking(next.id);
        
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final points = parseVertices(next.vertices);
            if (points.isNotEmpty) {
              print('📍 Dibujando ${points.length} puntos en el mapa');
              await _drawRouteOnMap(points);
              await _addRouteMarkers(points, next.nombre);
            } else {
              print('❌ No se pudieron decodificar los puntos de la ruta seleccionada');
            }
          } catch (e) {
            print('❌ Error dibujando ruta seleccionada: $e');
          }
        });
      }
    });

    // 🔍 También escuchar cambios en las rutas disponibles para mostrar la primera si no hay seleccionada
    ref.listen<AsyncValue<List<Ruta>>>(searchRutasProvider, (previous, next) {
      if (!_shouldShowRoute) {
        print('⏸️ Carga automática de ruta desactivada');
        return;
      }
      
      final selectedRuta = ref.read(selectedRutaProvider);
      if (selectedRuta != null) {
        print('🎯 Ya hay una ruta seleccionada, no cargando por defecto');
        return;
      }
      
      next.when(
        data: (rutas) {
          if (rutas.isNotEmpty) {
            print('🛣️ Cargando ruta por defecto: ${rutas.first.nombre}');
            
            // ARREGLO: Unirse automáticamente al tracking de la primera ruta disponible
            _joinRouteTracking(rutas.first.id);
            
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final points = parseVertices(rutas.first.vertices);
                if (points.isNotEmpty) {
                  await _drawRouteOnMap(points);
                  await _addRouteMarkers(points, rutas.first.nombre);
                }
              } catch (e) {
                print('❌ Error dibujando ruta por defecto: $e');
              }
            });
          }
        },
        loading: () => print('⏳ Cargando rutas...'),
        error: (error, stack) => print('❌ Error cargando rutas: $error'),
      );
    });

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
              return Stack(children: [
                  MapLibreMap(
                        onMapCreated: (controller) {
                      mapController.complete(controller);
                      _loadImages(controller);
                    },
                  // styleString: "$styleUrl?key=$apiKey",
                  styleString: snapshot.data!,
                  initialCameraPosition: const CameraPosition(
                  zoom: 13.0, target: LatLng(-17.78314, -63.18084)), // Coordenadas de Santa Cruz de la Sierra
                  trackCameraPosition: true,
                  minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
                  onStyleLoadedCallback: () =>
                  setState(() => canInteractWithMap = true),
                  ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar linea...',
                        suffixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onTap: () async {
                        print('🔍 Abriendo búsqueda de rutas...');
                        
                        // Reactivar carga de rutas cuando el usuario busca
                        setState(() {
                          _shouldShowRoute = true;
                        });
                        
                        final result = await context.push("/search-route");
                        print('🔄 Resultado de búsqueda: $result');
                        if(result == true){
                          print('✅ Invalidando providers para recargar ruta...');
                          ref.invalidate(entidadIdProvider);
                          ref.invalidate(searchRutasProvider);
                        }

                      } ,
                    ),
                  ),
                ),
                Positioned(
                  top: 70, // Debajo del campo de búsqueda
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: "debug_btn",
                    backgroundColor: Colors.orange,
                    onPressed: () async {
                      // Debug: Imprimir datos locales y poblar si es necesario
                      print('🔍 === INICIANDO DEBUG MODO SOLO LOCAL ===');
                      
                      try {
                        // Obtener datasources locales
                        final entidadLocal = await ref.read(entidadLocalDataSourceProvider.future);
                        final rutaLocal = await ref.read(rutaLocalDataSourceProvider.future);
                        
                        // Obtener repositorios para poblar datos de prueba
                        final entidadRepo = await ref.read(entidadRepositoryProvider.future);
                        final rutaRepo = await ref.read(rutaRepositoryProvider.future);
                        
                        print('📱 === VERIFICANDO DATOS LOCALES ===');
                        
                        // 1. Verificar entidades locales
                        if (entidadLocal != null) {
                          final entidadesExistentes = await entidadLocal.getAll();
                          if (entidadesExistentes.isEmpty) {
                            print('🌱 No hay entidades locales, poblando datos de prueba...');
                            await (entidadRepo as EntidadRepositoryImpl).poblarDatosPrueba();
                          }
                          await entidadLocal.debugPrintAll();
                        }
                        
                        // 2. Verificar rutas locales
                        if (rutaLocal != null) {
                          final rutasExistentes = await rutaLocal.getAll();
                          if (rutasExistentes.isEmpty) {
                            print('🌱 No hay rutas locales, poblando datos de prueba...');
                            await (rutaRepo as RutaRepositoryImpl).poblarRutasPrueba();
                          }
                          await rutaLocal.debugPrintAll();
                        }
                        
                        print('✅ === DATOS LOCALES LISTOS PARA USO ===');
                        
                        // 3. Refrescar providers para mostrar datos actualizados
                        ref.invalidate(entidadProvider);
                        ref.invalidate(searchRutasProvider);
                        
                        // Mostrar snackbar de confirmación
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔍 Datos locales verificados y actualizados. Revisa la consola para detalles.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        
                      } catch (e) {
                        print('❌ Error en debug: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.bug_report, color: Colors.white),
                  ),
                ),
                // Botón adicional para inicializar datos offline
                Positioned(
                  top: 120, // Debajo del botón de debug
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: "init_offline_btn",
                    backgroundColor: Colors.blue,
                    onPressed: () async {
                      print('🌱 === INICIALIZANDO DATOS OFFLINE ===');
                      
                      try {
                        // Obtener repositorios
                        final entidadRepo = await ref.read(entidadRepositoryProvider.future);
                        final rutaRepo = await ref.read(rutaRepositoryProvider.future);
                        
                        print('🏢 Poblando entidades de prueba...');
                        await (entidadRepo as EntidadRepositoryImpl).poblarDatosPrueba();
                        
                        print('🛣️  Poblando rutas de prueba...');
                        await (rutaRepo as RutaRepositoryImpl).poblarRutasPrueba();
                        
                        // Refrescar providers
                        ref.invalidate(entidadProvider);
                        ref.invalidate(searchRutasProvider);
                        
                        print('✅ Datos offline inicializados correctamente');
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🌱 Datos offline inicializados. ¡Ya puedes buscar líneas!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        
                      } catch (e) {
                        print('❌ Error al inicializar datos offline: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error al inicializar: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.download_for_offline, color: Colors.white),
                  ),
                ),
                // Botón adicional para limpiar rutas y testing
                Positioned(
                  top: 170, // Debajo del botón offline
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: "clear_route_btn",
                    backgroundColor: Colors.red,
                    onPressed: () async {
                      print('🗑️ === LIMPIANDO RUTA ===');
                      
                      try {
                        // Desactivar carga automática de rutas
                        setState(() {
                          _shouldShowRoute = false;
                        });
                        
                        if (!mapController.isCompleted) {
                          print('⚠️ Controlador del mapa no está listo');
                          return;
                        }

                        final controller = await mapController.future;
                        
                        // Eliminar ruta actual
                        if (_routeLine != null) {
                          await controller.removeLine(_routeLine!);
                          _routeLine = null;
                          print('✅ Ruta eliminada del mapa');
                        } else {
                          print('⚠️ No hay ruta para eliminar');
                        }

                        // Limpiar selección de entidad
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(SharedPreferenceHelper.SELECTED_ENTIDAD_ID);
                        print('🧹 Selección de entidad limpiada');

                        // Invalidar providers (sin que se recargue automáticamente)
                        ref.invalidate(entidadIdProvider);
                        ref.invalidate(searchRutasProvider);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🗑️ Ruta limpiada del mapa'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                      } catch (e) {
                        print('❌ Error al limpiar ruta: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error al limpiar: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.clear, color: Colors.white),
                  ),
                ),
                // Botón específico para actualizar a Santa Cruz
                Positioned(
                  top: 220, // Debajo del botón de limpiar
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: "santa_cruz_btn",
                    backgroundColor: Colors.green,
                    onPressed: () async {
                      print('🌟 === ACTUALIZANDO A SANTA CRUZ ===');
                      
                      try {
                        // Obtener repositorios
                        final entidadRepo = await ref.read(entidadRepositoryProvider.future);
                        final rutaRepo = await ref.read(rutaRepositoryProvider.future);
                        
                        // Limpiar datos anteriores
                        final entidadLocal = await ref.read(entidadLocalDataSourceProvider.future);
                        final rutaLocal = await ref.read(rutaLocalDataSourceProvider.future);
                        
                        if (entidadLocal != null) {
                          await entidadLocal.clearAll();
                          print('🧹 Datos de entidades limpiados');
                        }
                        
                        if (rutaLocal != null) {
                          await rutaLocal.clearAll();
                          print('🧹 Datos de rutas limpiados');
                        }
                        
                        // Poblar con datos de Santa Cruz
                        print('🏙️ Poblando entidades de Santa Cruz...');
                        await (entidadRepo as EntidadRepositoryImpl).poblarDatosPrueba();
                        
                        print('🛣️ Poblando rutas de Santa Cruz...');
                        await (rutaRepo as RutaRepositoryImpl).poblarRutasPrueba();
                        
                        // Limpiar selección actual
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(SharedPreferenceHelper.SELECTED_ENTIDAD_ID);
                        
                        // Refrescar providers
                        ref.invalidate(entidadProvider);
                        ref.invalidate(entidadIdProvider);
                        ref.invalidate(searchRutasProvider);
                        
                        print('✅ Actualización a Santa Cruz completada');
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🌟 ¡Actualizado a rutas de Santa Cruz de la Sierra!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        
                      } catch (e) {
                        print('❌ Error al actualizar a Santa Cruz: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.location_city, color: Colors.white),
                  ),
                ),
                // Botón para mostrar ubicación de la BD
                Positioned(
                  top: 270, // Debajo del botón de Santa Cruz
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: "db_location_btn",
                    backgroundColor: Colors.purple,
                    onPressed: () async {
                      print('📂 === UBICACIÓN DE BASE DE DATOS ===');
                      
                      try {
                        // Obtener el provider de Isar
                        final isar = await ref.read(isarProvider.future);
                        
                        if (isar != null) {
                          // Mostrar información de la instancia de Isar
                          print('📂 Directorio de Isar: ${isar.directory}');
                          print('📂 Nombre de la BD: default.isar');
                          print('📂 Ruta completa: ${isar.directory}/default.isar');
                          print('📂 Isar está abierto: ${isar.isOpen}');
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('📂 Ubicación de la Base de Datos:'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${isar.directory}/default.isar',
                                    style: const TextStyle(fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.purple,
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'OK',
                                textColor: Colors.white,
                                onPressed: () {
                                  print('🔄 Información mostrada');
                                },
                              ),
                            ),
                          );
                        } else {
                          print('❌ Isar no está inicializado');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Isar no está inicializado'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        
                      } catch (e) {
                        print('❌ Error al obtener ubicación de BD: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.folder, color: Colors.white),
                  ),
                ),
                // Botón para centrar cámara en micros
                Positioned(
                  top: 270, // Debajo de otros botones
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: "center_camera_btn",
                    backgroundColor: Colors.blue,
                    onPressed: () async {
                      print('📷 === CENTRANDO CÁMARA EN MICROS ===');
                      
                      if (_microMarkers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📍 No hay micros activos para mostrar'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      
                      try {
                        if (!mapController.isCompleted) return;
                        final controller = await mapController.future;
                        
                        if (_microMarkers.length == 1) {
                          // Si hay solo un micro, centrar en él
                          final microId = _microMarkers.keys.first;
                          
                          // Buscar la última ubicación conocida del micro
                          print('📍 Centrando en micro: $microId');
                          
                          // Centrar en coordenadas de Santa Cruz por defecto
                          await controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              const LatLng(-17.78314, -63.18084), 
                              14.0,
                            ),
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Centrando en micro $microId'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          // Si hay múltiples micros, centrar en Santa Cruz
                          await controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              const LatLng(-17.78314, -63.18084), 
                              13.0,
                            ),
                          );
                          
                          print('📍 Centrando vista general para ${_microMarkers.length} micros');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Vista general - ${_microMarkers.length} micros activos'),
                              backgroundColor: Colors.blue,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                        
                      } catch (e) {
                        print('❌ Error centrando cámara: $e');
                      }
                    },
                    child: const Icon(Icons.center_focus_strong, color: Colors.white),
                  ),
                ),
                // Widget de información de ruta seleccionada
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final selectedRuta = ref.watch(selectedRutaProvider);
                      final rutaAsync = ref.watch(searchRutasProvider);
                      
                      return rutaAsync.when(
                        data: (rutas) {
                          // Si hay una ruta seleccionada, mostrarla, sino mostrar la primera disponible
                          final rutaAMostrar = selectedRuta ?? (rutas.isNotEmpty ? rutas.first : null);
                          
                          if (rutaAMostrar == null) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No hay rutas disponibles. Toca el botón de búsqueda para buscar rutas.',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.route, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        rutaAMostrar.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (selectedRuta != null)
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rutaAMostrar.descripcion,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${rutaAMostrar.distancia}km'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${rutaAMostrar.tiempo.toInt()}min'),
                                  ],
                                ),
                                if (rutas.length > 1) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rutas disponibles: ${rutas.length} (Toca buscar para cambiar)',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                        loading: () => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Cargando rutas...'),
                            ],
                          ),
                        ),
                        error: (error, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error cargando rutas: $error',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],);
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            return const Center(child: CircularProgressIndicator());
          }),
    );
  }
}
