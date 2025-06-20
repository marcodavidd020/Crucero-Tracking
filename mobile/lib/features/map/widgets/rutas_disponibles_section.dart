import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../../config/constants.dart';
import '../../auth/providers/auth_provider.dart';

// Provider para las rutas de la entidad
final rutasEntidadProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(userProvider);
  if (user?.entidadId == null) return [];
  
  try {
    print('🌐 Obteniendo rutas de la entidad: ${user?.entidadId}');
    final response = await ApiService(baseUrl: baseUrl).get('ruta/${user?.entidadId}');
    
    if (response['data'] != null && response['data']['rutas'] != null) {
      final List<dynamic> rutasData = response['data']['rutas'];
      return rutasData.cast<Map<String, dynamic>>();
    }
    return [];
  } catch (e) {
    print('❌ Error obteniendo rutas de la entidad: $e');
    return [];
  }
});

// Provider para la ruta seleccionada por el micrero
final rutaSeleccionadaProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class RutasDisponiblesSection extends ConsumerWidget {
  const RutasDisponiblesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutasAsync = ref.watch(rutasEntidadProvider);
    final rutaSeleccionada = ref.watch(rutaSeleccionadaProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Rutas Disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Lista de rutas
          rutasAsync.when(
            data: (rutas) => _buildRutasList(context, ref, rutas, rutaSeleccionada),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorWidget(error),
          ),
        ],
      ),
    );
  }

  Widget _buildRutasList(
    BuildContext context, 
    WidgetRef ref, 
    List<Map<String, dynamic>> rutas, 
    Map<String, dynamic>? rutaSeleccionada
  ) {
    if (rutas.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        ...rutas.map((ruta) => _buildRutaItem(context, ref, ruta, rutaSeleccionada)),
        
        // Botón para iniciar viaje si hay una ruta seleccionada
        if (rutaSeleccionada != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _iniciarViaje(context, ref, rutaSeleccionada),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'Iniciar Viaje',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRutaItem(
    BuildContext context, 
    WidgetRef ref, 
    Map<String, dynamic> ruta, 
    Map<String, dynamic>? rutaSeleccionada
  ) {
    final isSelected = rutaSeleccionada?['id'] == ruta['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(rutaSeleccionadaProvider.notifier).state = ruta;
            _mostrarOpcionesRuta(context, ref, ruta);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta['nombre'] ?? 'Ruta sin nombre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.orange.shade700
                              : Colors.black87,
                        ),
                      ),
                      if (ruta['descripcion'] != null)
                        Text(
                          ruta['descripcion'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.arrow_forward_ios,
                  color: isSelected
                      ? Colors.orange
                      : Colors.grey.shade400,
                  size: isSelected ? 24 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            'No hay rutas disponibles para tu entidad',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Error al cargar rutas: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesRuta(BuildContext context, WidgetRef ref, Map<String, dynamic> ruta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteOptionsBottomSheet(ruta: ruta),
    );
  }

  void _iniciarViaje(BuildContext context, WidgetRef ref, Map<String, dynamic> ruta) async {
    try {
      // Guardar la ruta seleccionada en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ruta_activa_id', ruta['id']);
      await prefs.setString('ruta_activa_nombre', ruta['nombre']);
      
      // Actualizar el usuario con la ruta seleccionada
      final user = ref.read(userProvider);
      if (user != null) {
        final usuarioConRuta = user.copyWith(rutaAsignada: ruta['nombre']);
        ref.read(userProvider.notifier).state = usuarioConRuta;
      }
      
      // Mostrar confirmación
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚌 Viaje iniciado en: ${ruta['nombre']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navegar al mapa del empleado con tracking activo
        context.go('/employee-map');
      }
      
    } catch (e) {
      print('❌ Error iniciando viaje: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar el viaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RouteOptionsBottomSheet extends ConsumerWidget {
  final Map<String, dynamic> ruta;

  const RouteOptionsBottomSheet({
    super.key,
    required this.ruta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Información de la ruta
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.route, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta['nombre'] ?? 'Ruta sin nombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (ruta['descripcion'] != null)
                      Text(
                        ruta['descripcion'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Opciones disponibles
          Column(
            children: [
              _buildOptionButton(
                'Ver Ruta en el Mapa',
                'Visualizar la ruta completa',
                Icons.map,
                Colors.blue,
                () {
                  Navigator.pop(context);
                  _verRutaEnMapa(context, ref);
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                'Iniciar Viaje',
                'Comenzar tracking en esta ruta',
                Icons.play_arrow,
                Colors.green,
                () {
                  Navigator.pop(context);
                  _iniciarViaje(context, ref);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    String titulo,
    String subtitulo,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _verRutaEnMapa(BuildContext context, WidgetRef ref) {
    // Actualizar el usuario con la ruta seleccionada
    final user = ref.read(userProvider);
    if (user != null) {
      final usuarioConRuta = user.copyWith(rutaAsignada: ruta['nombre']);
      ref.read(userProvider.notifier).state = usuarioConRuta;
    }
    
    // Navegar al mapa del empleado
    context.go('/employee-map');
  }

  void _iniciarViaje(BuildContext context, WidgetRef ref) async {
    try {
      // Guardar la ruta seleccionada en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ruta_activa_id', ruta['id']);
      await prefs.setString('ruta_activa_nombre', ruta['nombre']);
      
      // Actualizar el usuario con la ruta seleccionada
      final user = ref.read(userProvider);
      if (user != null) {
        final usuarioConRuta = user.copyWith(rutaAsignada: ruta['nombre']);
        ref.read(userProvider.notifier).state = usuarioConRuta;
      }
      
      // Mostrar confirmación
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚌 Viaje iniciado en: ${ruta['nombre']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navegar al mapa del empleado con tracking activo
        context.go('/employee-map');
      }
      
    } catch (e) {
      print('❌ Error iniciando viaje: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar el viaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 