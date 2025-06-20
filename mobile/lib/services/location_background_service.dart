import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:app_map_tracking/common/app_cycle_observer.dart';
import 'package:app_map_tracking/config/constants.dart';
import 'package:app_map_tracking/services/background/socket_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationBackgroundService {
  static final ON_GPS_LOCATION_UPDATE = "on_gps_location_update";

  static const _notificationChannelId = "geo_channel";
  static const _notificationId = 849;

  final FlutterBackgroundService service = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static final LocationBackgroundService _instance = LocationBackgroundService._internal();
  factory LocationBackgroundService() => _instance;
  LocationBackgroundService._internal();
  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissions();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Location foreground service',
      description: 'canal para servicio de localizacion gps',
      importance: Importance.low,
    );

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Servicio de ubicación',
        initialNotificationContent: 'Obteniendo ubicación en segundo plano',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );

    service.startService();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ].request();
  }

  // Verificar permisos de ubicación siguiendo las mejores prácticas
  static Future<bool> _checkLocationPermissions() async {
    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("LocationBackgroundService: 📍 Servicio de ubicación deshabilitado");
        return false;
      }

      // 2. Verificar permisos actuales
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // 3. Solicitar permisos si están denegados
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("LocationBackgroundService: ❌ Permisos de ubicación denegados");
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print("LocationBackgroundService: ❌ Permisos de ubicación denegados permanentemente");
        return false;
      }

      print("LocationBackgroundService: ✅ Permisos de ubicación confirmados");
      return true;
      
    } catch (e) {
      print("LocationBackgroundService: ❌ Error verificando permisos: $e");
      return false;
    }
  }

  @pragma('vm:entry-point')
  Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Verificar permisos y servicio de ubicación antes de obtener posición
      if (!await _checkLocationPermissions()) {
        print("LocationBackgroundService: ❌ Permisos de ubicación no disponibles");
        return;
      }

      try {
        Position position = await Geolocator.getCurrentPosition();
        print("LocationBackgroundService: ubicacion obtenida del dispositivo -> latitud: ${position.latitude} longitud: ${position.longitude}");

        if (service is AndroidServiceInstance && await service.isForegroundService()) {
          print("LocationBackgroundService: Actualizando notificacion");
          flutterLocalNotificationsPlugin.show(
            _notificationId,
            'COOL SERVICE',
            'Awesome ${DateTime.now()}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _notificationChannelId,
                'MY FOREGROUND SERVICE',
                icon: 'ic_bg_service_small',
                ongoing: true,
              ),
            ),
          );

          if (!AppLifecycleObserver.isInForeground.value) {
            print("LocationBackgroundService: aplicacion en background");
            emitLocation(position);
          } else {
            print("LocationBackgroundService: aplicacion en foreground");
            emitLocation(position);
            // SocketManager.disconnect();
          }
        }
      } on LocationServiceDisabledException {
        print("LocationBackgroundService: ❌ Servicio de ubicación deshabilitado");
      } on PermissionDeniedException {
        print("LocationBackgroundService: ❌ Permisos de ubicación denegados");  
      } catch (e) {
        print("LocationBackgroundService: ❌ Error obteniendo ubicación: $e");
      }
    });
  }

  static void onLocationChanged(Position position) async {
    try {
      print("LocationBackgroundService: Ubicación actualizada");
      print("LocationBackgroundService: latitud: ${position.latitude} longitud: ${position.longitude}");

      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('setAsForeground');
      }

      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      if (service is AndroidServiceInstance) {
        final androidService = service as AndroidServiceInstance;
        if (await androidService.isForegroundService()) {
          print("LocationBackgroundService: Actualizando notificacion");
          flutterLocalNotificationsPlugin.show(
            _notificationId,
            'COOL SERVICE',
            'Awesome ${DateTime.now()}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _notificationChannelId,
                'MY FOREGROUND SERVICE',
                icon: 'ic_bg_service_small',
                ongoing: true,
              ),
            ),
          );

          if (!AppLifecycleObserver.isInForeground.value) {
            print("LocationBackgroundService: aplicacion en background");
            emitLocation(position);
          } else {
            print("LocationBackgroundService: aplicacion en foreground");
            emitLocation(position);
            // SocketManager.disconnect();
          }
        }
      }
    } catch (e) {
      print("LocationBackgroundService: ❌ Error en onLocationChanged: $e");
      // No re-lanzar el error para evitar crashes del background service
    }
  }

  static void emitLocation(Position position) async {
    try {
      // CRÍTICO: Obtener datos reales del usuario desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final microId = prefs.getString('user_micro_id') ?? 'unknown_micro';
      final userId = prefs.getString('user_id') ?? 'unknown_user';
      final rutaActivaId = prefs.getString('ruta_activa_id') ?? 'f206dc92-2a2f-4bcf-9a6e-799d6b83033d';
      
      print("LocationBackgroundService: Obteniendo datos del usuario...");
      print("  🚌 MicroId: $microId");
      print("  👤 UserId: $userId");
      print("  🛣️ Ruta activa: $rutaActivaId");
      
      // Inicializar socket con datos reales
      SocketManager.initialize(baseUrlSocket, microId, 'token-auth-$userId');

      final trackingData = {
        'id_micro': microId,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'altura': position.altitude,
        'precision': position.accuracy,
        'bateria': 100.0,
        'imei': 'flutter-device-$userId',
        'fuente': 'app_flutter_background',
        'id_ruta': rutaActivaId, // Usar ruta activa real
        'timestamp': DateTime.now().toIso8601String(),
      };

      print("LocationBackgroundService: Enviando ubicación background:");
      print("  📍 Lat: ${position.latitude}, Lng: ${position.longitude}");
      print("  🛣️ Ruta: $rutaActivaId");
      print("  🚌 Micro: $microId");
      
      await SocketManager.emit('updateLocation', trackingData);
      
    } catch (e) {
      print("LocationBackgroundService: ❌ Error enviando ubicación: $e");
      // No re-lanzar el error para evitar crashes del background service
    }
  }

  static void stopLocationService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stopService');
        print("LocationBackgroundService: Servicio detenido");
      }
    } catch (e) {
      print("LocationBackgroundService: ❌ Error deteniendo servicio: $e");
    }
  }

  // NUEVO: Verificar si el servicio de ubicación está habilitado
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print("LocationBackgroundService: ❌ Error verificando servicio de ubicación: $e");
      return false;
    }
  }

  // NUEVO: Verificar permisos de ubicación
  static Future<bool> hasLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print("LocationBackgroundService: ❌ Error verificando permisos: $e");
      return false;
    }
  }

  // NUEVO: Inicialización segura del background service
  static Future<bool> initializeSafely() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      if (!await isLocationServiceEnabled()) {
        print("LocationBackgroundService: ⚠️ Servicio de ubicación deshabilitado");
        return false;
      }

      // Verificar permisos
      if (!await hasLocationPermissions()) {
        print("LocationBackgroundService: ⚠️ Sin permisos de ubicación");
        return false;
      }

      // Inicializar normalmente si todo está OK
      final service = LocationBackgroundService();
      await service.initialize();
      print("LocationBackgroundService: ✅ Inicializado correctamente");
      return true;
      
    } catch (e) {
      print("LocationBackgroundService: ❌ Error en inicialización segura: $e");
      return false;
    }
  }
}
