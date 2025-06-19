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
    });
  }

  static void emitLocation(Position position){
    SocketManager.initialize(baseUrlSocket, "microId", "token");

    final trackingData = {
      'id_micro': "_microId",
      'latitud': position.latitude,
      'longitud': position.longitude,
      'altura': position.altitude,
      'precision': position.accuracy,
      'bateria': "100",
      'imei': 'dispositivo-flutter',
      'fuente': 'app_flutter',
    };

    print("intentando enviar ubicaicon background: latitud: ${position.latitude} longitud ${position.longitude} ");
    SocketManager.emit('updateLocation', trackingData);
  }
}
