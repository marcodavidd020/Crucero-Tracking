import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/app_drawer.dart';
import '../../providers/ruta_provider.dart';
import '../services/client_map_controller.dart';
import '../services/client_route_manager.dart';
import '../widgets/client_search_bar.dart';
import '../widgets/client_debug_buttons.dart';
import '../widgets/client_route_info.dart';
import '../widgets/client_map_widget.dart';

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
  late ClientMapController _mapController;
  late ClientRouteManager _routeManager;

  @override
  void initState() {
    super.initState();
    _mapController = ClientMapController(ref);
    _routeManager = ClientRouteManager(ref, _mapController);
    print('🗺️ Mapa cliente inicializado - Socket NO iniciado aún');
  }

  @override
  void dispose() {
    print('🧹 Iniciando limpieza del ClientMapPage');
    
    _routeManager.dispose();
    _mapController.dispose();
    
    super.dispose();
    print('✅ ClientMapPage dispose completado');
  }

  // ========== BUILD ==========
  
  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en la ruta seleccionada
    ref.listen<AsyncValue<List<dynamic>>>(searchRutasProvider, (previous, next) {
      _routeManager.handleRouteChange(next, context);
    });

    // El tracking se inicia automáticamente en ClientRouteManager

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Cliente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Mapa principal
          ClientMapWidget(
            mapController: _mapController,
            onSearchTap: () => _routeManager.onSearchTap(context),
            onRouteCleared: _routeManager.onRouteCleared,
          ),
          
          // Barra de búsqueda
          ClientSearchBar(onSearchTap: () => _routeManager.onSearchTap(context)),
          
          // Botones de debug
          ClientDebugButtons(onRouteCleared: _routeManager.onRouteCleared),
          
          // Información de ruta
          const ClientRouteInfo(),
        ],
      ),
    );
  }
} 