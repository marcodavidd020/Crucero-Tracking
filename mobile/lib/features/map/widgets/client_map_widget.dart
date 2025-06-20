import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/client_map_controller.dart';

class ClientMapWidget extends ConsumerStatefulWidget {
  final ClientMapController mapController;
  final VoidCallback? onSearchTap;
  final VoidCallback? onRouteCleared;

  const ClientMapWidget({
    super.key,
    required this.mapController,
    this.onSearchTap,
    this.onRouteCleared,
  });

  @override
  ConsumerState<ClientMapWidget> createState() => _ClientMapWidgetState();
}

class _ClientMapWidgetState extends ConsumerState<ClientMapWidget> {
  late Future<String> styles;

  @override
  void initState() {
    super.initState();
    styles = ClientMapController.initStyle();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: styles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MapLibreMap(
            onMapCreated: widget.mapController.onMapCreated,
            styleString: snapshot.data!,
            initialCameraPosition: const CameraPosition(
              zoom: 13.0,
              target: LatLng(-17.78314, -63.18084),
            ),
            trackCameraPosition: true,
            minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
            onStyleLoadedCallback: widget.mapController.onStyleLoaded,
          );
        }
        
        if (snapshot.hasError) {
          print("❌ Error cargando estilo del mapa: ${snapshot.error}");
          return _buildErrorWidget();
        }
        
        return _buildLoadingWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Error cargando el mapa",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            "Verifique su conexión a internet",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                styles = ClientMapController.initStyle();
              });
            },
            child: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Cargando mapa..."),
        ],
      ),
    );
  }
} 