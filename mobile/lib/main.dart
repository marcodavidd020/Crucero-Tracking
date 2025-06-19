import 'package:app_map_tracking/common/app_cycle_observer.dart';
import 'package:app_map_tracking/services/location_background_service.dart';
import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final AppLifecycleObserver lifecycleObserver = AppLifecycleObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  lifecycleObserver.start();

  // await LocationBackgroundService().initialize(); // Comentado temporalmente - usando TrackingSocketService

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    const ProviderScope(
      child: MainApp()
    )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Map Tracking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.green,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
