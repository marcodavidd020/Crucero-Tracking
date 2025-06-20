import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ruta.dart';
import '../../providers/ruta_provider.dart';

class ClientRouteInfo extends ConsumerWidget {
  const ClientRouteInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRuta = ref.watch(selectedRutaProvider);
    final rutaAsync = ref.watch(searchRutasProvider);
    
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: rutaAsync.when(
        data: (rutas) {
          final rutaAMostrar = selectedRuta ?? (rutas.isNotEmpty ? rutas.first : null);
          
          if (rutaAMostrar == null) {
            return _buildNoRoutesCard();
          }
          
          return _buildRouteCard(rutaAMostrar, rutas, selectedRuta != null);
        },
        loading: () => _buildLoadingCard(),
        error: (error, _) => _buildErrorCard(error),
      ),
    );
  }

  Widget _buildNoRoutesCard() {
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

  Widget _buildRouteCard(Ruta ruta, List<Ruta> allRoutes, bool isSelected) {
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
                  ruta.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ruta.descripcion,
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
              Text('${ruta.distancia}km'),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${ruta.tiempo.toInt()}min'),
            ],
          ),
          if (allRoutes.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Rutas disponibles: ${allRoutes.length} (Toca buscar para cambiar)',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
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
    );
  }

  Widget _buildErrorCard(Object error) {
    return Container(
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
    );
  }
} 