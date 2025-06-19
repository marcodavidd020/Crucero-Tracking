import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../../../common/utils.dart';
import '../../../common/widgets/app_drawer.dart';
import '../../../config/constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/providers/ruta_provider.dart';
import '../../../services/location_background_service.dart';
import '../../../services/api_service.dart';
import '../../../services/tracking_socket_service.dart';

class EmployeeMapPage extends ConsumerStatefulWidget {
  const EmployeeMapPage({super.key});

  @override
  ConsumerState<EmployeeMapPage> createState() => _EmployeeMapPageState();
}

class _EmployeeMapPageState extends ConsumerState<EmployeeMapPage> {
  MapLibreMapController? _controller;
  final Completer<MapLibreMapController> mapController = Completer();
  bool canInteractWithMap = false;
  Symbol? currentLocationSymbol;
  Line? _routeLine;
  
  // Estado del servicio
  bool _isServiceActive = false;
  Position? _currentPosition;
  Timer? _locationTimer;
  
  // Tracking service
  TrackingSocketService? _trackingService;
  
  // ARREGLO: Control para evitar múltiples creaciones del marcador
  bool _isCreatingMarker = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _initializeTrackingService();
    
    // NO cargar ruta en initState - esperar a que el mapa esté listo
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _trackingService?.dispose();
    
    // ARREGLO: Limpiar estado del marcador
    _isCreatingMarker = false;
    currentLocationSymbol = null;
    
    super.dispose();
  }

  Future<void> _initializeTrackingService() async {
    try {
      _trackingService = TrackingSocketService();
      print('🔌 Servicio de tracking inicializado');
    } catch (e) {
      print('❌ Error inicializando servicio de tracking: $e');
    }
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Los servicios de ubicación están deshabilitados');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Permisos de ubicación denegados');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Permisos de ubicación denegados permanentemente');
      return;
    }
  }

  Future<void> _loadMyRoute() async {
    // Verificar que el mapa esté listo antes de cargar la ruta
    if (!mapController.isCompleted || !canInteractWithMap) {
      print('⚠️ Mapa no está listo para cargar ruta');
      return;
    }
    
    // Obtener información del micrero autenticado
    final user = ref.read(userProvider);
    if (user?.esMicrero == true) {
      try {
        print('🌐 Obteniendo ruta desde API para empleado...');
        
        // Obtener el empleado desde la base de usuarios
        final empleadoResponse = await ApiService(baseUrl: baseUrl).get('auth/empleado/${user?.empleadoId}/ruta');
        
        if (empleadoResponse['ruta'] != null) {
          final rutaData = empleadoResponse['ruta'];
          
          // Crear un objeto ruta temporal
          final ruta = {
            'nombre': rutaData['nombre'],
            'vertices': rutaData['vertices'],
            'origenLat': rutaData['origen_lat'],
            'origenLong': rutaData['origen_long'],
            'destinoLat': rutaData['destino_lat'],
            'destinoLong': rutaData['destino_long'],
          };
          
          print('🚌 Cargando ruta desde API: ${ruta['nombre']}');
          print('🗺️ Vertices desde API: ${ruta['vertices']}');
          await _drawRouteOnMap(ruta);
        } else {
          print('❌ No se encontró ruta para el empleado');
          // Fallback al provider local
          final ruta = ref.read(rutaByNombreProvider(user!.rutaAsignada!));
          if (ruta != null) {
            print('🚌 Fallback - Cargando ruta local: ${ruta.value?.nombre}');
            await _drawRouteOnMap(ruta);
          }
        }
      } catch (e) {
        print('❌ Error obteniendo ruta desde API: $e');
        
        // Fallback al provider local
        if (user?.rutaAsignada != null) {
          final ruta = ref.read(rutaByNombreProvider(user!.rutaAsignada!));
          if (ruta != null) {
            print('🚌 Fallback - Cargando ruta local: ${ruta.value?.nombre}');
            await _drawRouteOnMap(ruta);
          } else {
            print('❌ No se encontró la ruta: ${user.rutaAsignada}');
          }
        }
      }
    }
  }

  Future<void> _drawRouteOnMap(dynamic ruta) async {
    if (!mapController.isCompleted) return;
    
    try {
      final controller = await mapController.future;
      
      // Obtener vertices dependiendo del tipo de objeto
      String verticesJson;
      if (ruta is Map<String, dynamic>) {
        verticesJson = ruta['vertices'] as String;
      } else {
        verticesJson = ruta.vertices as String;
      }
      
      // Parsear vertices de la ruta
      final vertices = parseVertices(verticesJson);
      if (vertices.isEmpty) {
        print('❌ No se encontraron vertices válidos');
        return;
      }

      print('✅ Se encontraron ${vertices.length} vertices para dibujar');

      // Remover línea anterior si existe
      if (_routeLine != null) {
        await controller.removeLine(_routeLine!);
      }

      // Dibujar la ruta en el mapa con mejor estilo y mayor visibilidad
      _routeLine = await controller.addLine(LineOptions(
        geometry: vertices,
        lineColor: "#FF3333", // Rojo vibrante más visible
        lineWidth: 8.0, // Línea más gruesa
        lineOpacity: 1.0, // Opacidad completa
      ));

      // Agregar marcadores de inicio y fin
      await _addRouteMarkers(controller, vertices, ruta);

      // Calcular los bounds correctamente basado en todos los vertices
      double minLat = vertices.map((v) => v.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = vertices.map((v) => v.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = vertices.map((v) => v.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = vertices.map((v) => v.longitude).reduce((a, b) => a > b ? a : b);

      // Centrar el mapa en la ruta con padding
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 
        left: 80, top: 80, right: 80, bottom: 120));

      // Obtener nombre de la ruta
      String nombreRuta;
      if (ruta is Map<String, dynamic>) {
        nombreRuta = ruta['nombre'] as String;
      } else {
        nombreRuta = ruta.nombre as String;
      }

      print('✅ Ruta dibujada en el mapa: $nombreRuta');
      print('🗺️ Bounds: SW(${minLat}, ${minLng}) - NE(${maxLat}, ${maxLng})');
      
      _showSuccess('Ruta cargada: $nombreRuta');

    } catch (e) {
      print('❌ Error dibujando ruta: $e');
      _showError('Error al cargar la ruta: $e');
    }
  }

  Future<void> _addRouteMarkers(MapLibreMapController controller, List<LatLng> vertices, dynamic ruta) async {
    if (vertices.length < 2) return;
    
    try {
      final startPoint = vertices.first;
      final endPoint = vertices.last;
      
      // IMPORTANTE: Estos son marcadores FIJOS de la ruta, NO del empleado
      // Marcador de inicio (verde) más grande y visible
      await controller.addSymbol(SymbolOptions(
        geometry: startPoint,
        textField: "🏁 INICIO",
        textSize: 14,
        textColor: "#FFFFFF",
        textHaloColor: "#00C851",
        textHaloWidth: 3,
        textOffset: const Offset(0, -1),
        textAnchor: "center",
      ));
      
      // Marcador de fin (rojo) más grande y visible
      await controller.addSymbol(SymbolOptions(
        geometry: endPoint,
        textField: "🏁 FIN",
        textSize: 14,
        textColor: "#FFFFFF",
        textHaloColor: "#FF4444",
        textHaloWidth: 3,
        textOffset: const Offset(0, -1),
        textAnchor: "center",
      ));
      
      // ARREGLO: Reducir marcadores intermedios para evitar saturación
      if (vertices.length > 6) {
        final step = (vertices.length / 2).round(); // Solo 2 marcadores intermedios
        for (int i = step; i < vertices.length - 1; i += step) {
          if (i + step < vertices.length - 1) { // Evitar poner marcador muy cerca del final
            await controller.addSymbol(SymbolOptions(
              geometry: vertices[i],
              textField: "⭕", // Marcador más simple
              textSize: 12,
              textOffset: const Offset(0, -1),
            ));
          }
        }
      }
      
      print('✅ Marcadores de ruta agregados: INICIO y FIN${vertices.length > 6 ? ' con puntos intermedios' : ''}');
      
    } catch (e) {
      print('❌ Error agregando marcadores de ruta: $e');
    }
  }

  Future<void> _toggleTrackingService() async {
    if (_isServiceActive) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    try {
      print('🚀 Iniciando servicio de tracking...');
      
      final user = ref.read(userProvider);
      if (user?.esMicrero != true) {
        _showError('Solo los micreros pueden iniciar el tracking');
        return;
      }

      // Verificar permisos de ubicación
      await _checkLocationPermissions();
      
      // Obtener ubicación actual
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Inicializar el servicio de tracking con sockets
      if (_trackingService != null) {
        await _trackingService!.initSocket(
          'http://192.168.0.202:3001', // URL directa para socket
          user?.microId ?? 'MCR001', // Usar el microId del usuario
          'jwt-token-placeholder', // TODO: Usar token real
          enableLocationTracking: true, // EMPLEADO: SÍ envía ubicación
        );
        
        // ARREGLO: Configurar actualización cada 10 segundos para reducir parpadeo
        _trackingService!.updateInterval = 10;
        
        print('✅ Socket de tracking conectado');
      }

      // ARREGLO: Frecuencia optimizada - 5 segundos es un buen balance
      _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _sendLocationUpdate();
      });

      setState(() {
        _isServiceActive = true;
      });

      _showSuccess('Servicio de tracking iniciado - Los clientes pueden ver tu ubicación en tiempo real');
      
      // Centrar mapa en ubicación actual
      if (_currentPosition != null) {
        await _updateMapLocation(_currentPosition!);
      }

      // Enviar ubicación inicial inmediatamente
      await _sendLocationUpdate();

    } catch (e) {
      print('❌ Error al iniciar tracking: $e');
      _showError('Error al iniciar el servicio: $e');
    }
  }

  Future<void> _stopTracking() async {
    print('🛑 Deteniendo servicio de tracking...');
    
    _locationTimer?.cancel();
    
    // Detener el servicio de tracking con sockets
    _trackingService?.stopLocationTracking();
    
    // ARREGLO: Limpiar marcador del micro al detener el servicio
    if (currentLocationSymbol != null && mapController.isCompleted) {
      try {
        final controller = await mapController.future;
        await controller.removeSymbol(currentLocationSymbol!);
        currentLocationSymbol = null;
        print('✅ Marcador del micro removido al detener servicio');
      } catch (e) {
        print('⚠️ Error removiendo marcador al detener: $e');
        currentLocationSymbol = null; // Forzar reset
      }
    }
    
    setState(() {
      _isServiceActive = false;
    });

    _showInfo('Servicio de tracking detenido - Los clientes ya no verán tu ubicación');
  }

  Future<void> _sendLocationUpdate() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final user = ref.read(userProvider);
      if (user?.esMicrero == true && _currentPosition != null) {
        
        // ARREGLO: Obtener el ID de ruta real del usuario
        String rutaId = 'RUT001'; // Valor por defecto
        if (user?.rutaAsignada != null) {
          // Mapear nombre de ruta a ID de ruta
          switch (user!.rutaAsignada) {
            case 'Centro - Plan 3000':
              rutaId = 'RUT001';
              break;
            case 'Centro - Equipetrol':
              rutaId = 'RUT003';
              break;
            default:
              rutaId = 'RUT001';
          }
        }
        
        // Datos de ubicación para WebSocket
        final locationData = {
          'id_micro': user?.microId ?? 'MCR001',
          'latitud': _currentPosition!.latitude,
          'longitud': _currentPosition!.longitude,
          'altura': _currentPosition!.altitude,
          'precision': _currentPosition!.accuracy,
          'bateria': 100.0, // TODO: Implementar lectura real de batería
          'imei': 'flutter-device-${user?.id}',
          'fuente': 'app_flutter_employee',
          'id_ruta': rutaId, // ARREGLO: Usar ID real de ruta
          'timestamp': DateTime.now().toIso8601String(),
        };

        print('📍 Enviando ubicación en tiempo real: lat=${_currentPosition!.latitude}, lng=${_currentPosition!.longitude}, ruta=$rutaId');
        
        // Enviar SOLO vía socket (el backend no tiene endpoint REST)
        if (_trackingService != null && _trackingService!.isConnected) {
          _trackingService!.sendLocationUpdate(locationData);
          print('✅ Ubicación enviada vía WebSocket con ruta $rutaId');
        } else {
          print('❌ Socket no conectado - ubicación no enviada');
        }
        
        // ARREGLO: Actualizar marcador en el mapa local SOLO si el servicio está activo
        if (_isServiceActive) {
          await _updateMapLocation(_currentPosition!);
        }
      }

    } catch (e) {
      print('❌ Error al enviar ubicación: $e');
    }
  }

  Future<void> _updateMapLocation(Position position) async {
    if (!mapController.isCompleted) return;
    
    try {
      final controller = await mapController.future;
      final location = LatLng(position.latitude, position.longitude);

      // ARREGLO: Estrategia simple pero eficiente
      if (currentLocationSymbol == null && !_isCreatingMarker) {
        // Primera vez: crear el marcador
        _isCreatingMarker = true;
        try {
          currentLocationSymbol = await controller.addSymbol(SymbolOptions(
            geometry: location,
            iconImage: "bus-marker",
            iconSize: 2.0,
            iconOffset: const Offset(0, -30),
            textField: '🚌 MI MICRO',
            textSize: 12,
            textColor: '#FFFFFF',
            textHaloColor: '#FF4444',
            textHaloWidth: 2,
            textOffset: const Offset(0, 2),
          ));
          _isCreatingMarker = false;
          print('✅ Marcador del micro creado inicialmente');
        } catch (e) {
          _isCreatingMarker = false;
          print('❌ Error creando marcador inicial: $e');
          // Fallback: usar texto simple
          currentLocationSymbol = await controller.addSymbol(SymbolOptions(
            geometry: location,
            textField: '🚌 MI MICRO',
            textSize: 14,
            textColor: '#FFFFFF',
            textHaloColor: '#FF4444',
            textHaloWidth: 3,
          ));
        }
      } else if (currentLocationSymbol != null && !_isCreatingMarker) {
        // Actualizaciones: usar updateSymbol para mover suavemente
        try {
          await controller.updateSymbol(currentLocationSymbol!, SymbolOptions(
            geometry: location,
            iconImage: "bus-marker",
            iconSize: 2.0,
            iconOffset: const Offset(0, -30),
            textField: '🚌 MI MICRO',
            textSize: 12,
            textColor: '#FFFFFF',
            textHaloColor: '#FF4444',
            textHaloWidth: 2,
            textOffset: const Offset(0, 2),
          ));
          print('✅ Marcador movido suavemente a: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          print('⚠️ Error actualizando marcador, recreando...');
          // Si falla la actualización, recrear
          try {
            await controller.removeSymbol(currentLocationSymbol!);
          } catch (_) {}
          currentLocationSymbol = null;
          // Recursión controlada para recrear
          await _updateMapLocation(position);
          return;
        }
      }

      // Centrar cámara suavemente
      await controller.animateCamera(CameraUpdate.newLatLng(location));

    } catch (e) {
      print('❌ Error actualizando mapa: $e');
    }
  }

  Future<void> _loadImages(MapLibreMapController controller) async {
    try {
      // Cargar imagen del micro desde assets
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Micrero'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isServiceActive ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleTrackingService,
            tooltip: _isServiceActive ? 'Detener Tracking' : 'Iniciar Tracking',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Mapa
          MapLibreMap(
            onMapCreated: (controller) {
              mapController.complete(controller);
              _loadImages(controller);
            },
            styleString: "$styleUrl?key=$apiKey",
            initialCameraPosition: const CameraPosition(
              zoom: 15.0,
              target: LatLng(-17.78314, -63.18084), // Santa Cruz
            ),
            trackCameraPosition: true,
            minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
            onStyleLoadedCallback: () {
              setState(() => canInteractWithMap = true);
              // ARREGLO: Cargar ruta DESPUÉS de que el mapa esté completamente listo
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMyRoute();
              });
            },
          ),

          // Panel de información del micrero
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.drive_eta,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Micrero: ${user?.nombre ?? "Sin nombre"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isServiceActive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isServiceActive ? 'ACTIVO' : 'INACTIVO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (user?.microId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Micro: ${user?.placaMicro ?? user?.microId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (user?.rutaAsignada != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ruta: ${user?.rutaAsignada}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Botón de acción principal
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _toggleTrackingService,
              icon: Icon(
                _isServiceActive ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              label: Text(
                _isServiceActive ? 'Detener Servicio' : 'Iniciar Servicio',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isServiceActive ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Información de ubicación actual
          if (_currentPosition != null)
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
                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                  'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}\n'
                  'Precisión: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
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
    );
  }
}
