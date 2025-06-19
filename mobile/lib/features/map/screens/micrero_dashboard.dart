import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../config/constants.dart';

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

class MicreroDashboard extends ConsumerWidget {
  const MicreroDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Micrero'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange,
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con información del micrero
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.drive_eta,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.nombre ?? 'Micrero',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Información del micro y ruta
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Micro Asignado',
                            user?.microId ?? 'No asignado',
                            Icons.directions_bus,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Ruta',
                            user?.rutaAsignada ?? 'No asignada',
                            Icons.route,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sección de rutas disponibles
              Container(
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
                    
                    // Lista de rutas de la entidad
                    Consumer(
                      builder: (context, ref, child) {
                        final rutasAsync = ref.watch(rutasEntidadProvider);
                        final rutaSeleccionada = ref.watch(rutaSeleccionadaProvider);
                        
                        return rutasAsync.when(
                          data: (rutas) {
                            if (rutas.isEmpty) {
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
                            
                            return Column(
                              children: [
                                ...rutas.map((ruta) => Container(
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
                                            color: rutaSeleccionada?['id'] == ruta['id'] 
                                                ? Colors.orange 
                                                : Colors.grey.shade300,
                                            width: rutaSeleccionada?['id'] == ruta['id'] ? 2 : 1,
                                          ),
                                          color: rutaSeleccionada?['id'] == ruta['id'] 
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: rutaSeleccionada?['id'] == ruta['id']
                                                    ? Colors.orange
                                                    : Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
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
                                                      color: rutaSeleccionada?['id'] == ruta['id']
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
                                              rutaSeleccionada?['id'] == ruta['id']
                                                  ? Icons.check_circle
                                                  : Icons.arrow_forward_ios,
                                              color: rutaSeleccionada?['id'] == ruta['id']
                                                  ? Colors.orange
                                                  : Colors.grey.shade400,
                                              size: rutaSeleccionada?['id'] == ruta['id'] ? 24 : 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )).toList(),
                                
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
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => Container(
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Opciones principales
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildOptionCard(
                        context,
                        'Ver Mi Ruta',
                        'Visualizar ruta asignada en el mapa',
                        Icons.map,
                        Colors.green,
                        () => context.go('/employee-map'),
                      ),
                      _buildOptionCard(
                        context,
                        'Iniciar Tracking',
                        'Comenzar a compartir ubicación',
                        Icons.gps_fixed,
                        Colors.orange,
                        () => context.go('/employee-map'),
                      ),
                      _buildOptionCard(
                        context,
                        'Historial',
                        'Ver viajes realizados',
                        Icons.history,
                        Colors.blue,
                        () => _showComingSoon(context),
                      ),
                      _buildOptionCard(
                        context,
                        'Configuración',
                        'Ajustes de la aplicación',
                        Icons.settings,
                        Colors.grey,
                        () => _showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón de logout
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Guardar referencia al notifier antes del diálogo
                      final authNotifier = ref.read(authStateProvider.notifier);
                      
                      // Mostrar diálogo de confirmación
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cerrar Sesión'),
                          content: const Text('¿Estás seguro que quieres cerrar sesión?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldLogout == true && context.mounted) {
                        try {
                          // Realizar el logout usando la referencia guardada
                          await authNotifier.logout();
                          
                          // Navegar a la pantalla principal
                          if (context.mounted) {
                            context.go('/');
                          }
                        } catch (e) {
                          print('Error durante logout: $e');
                          // Mostrar mensaje de error si es necesario
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al cerrar sesión'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función próximamente disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _mostrarOpcionesRuta(BuildContext context, WidgetRef ref, Map<String, dynamic> ruta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                _buildOpcionBottomSheet(
                  'Ver Ruta en el Mapa',
                  'Visualizar la ruta completa',
                  Icons.map,
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    _verRutaEnMapa(context, ref, ruta);
                  },
                ),
                const SizedBox(height: 12),
                _buildOpcionBottomSheet(
                  'Iniciar Viaje',
                  'Comenzar tracking en esta ruta',
                  Icons.play_arrow,
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    _iniciarViaje(context, ref, ruta);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionBottomSheet(
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

  void _verRutaEnMapa(BuildContext context, WidgetRef ref, Map<String, dynamic> ruta) {
    // Actualizar el usuario con la ruta seleccionada
    final user = ref.read(userProvider);
    if (user != null) {
      final usuarioConRuta = user.copyWith(rutaAsignada: ruta['nombre']);
      ref.read(userProvider.notifier).state = usuarioConRuta;
    }
    
    // Navegar al mapa del empleado
    context.go('/employee-map');
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