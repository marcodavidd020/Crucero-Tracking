import 'package:app_map_tracking/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(userProvider); // Usar directamente el userProvider

    print("AppDrawer - Estado de autenticación: $authState");
    print("AppDrawer - Usuario actual: ${currentUser?.nombre ?? 'null'}");

    final isAuthenticated = authState == AuthState.authenticated;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Map Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),                if (isAuthenticated && currentUser != null) ...[
                  Text(
                    currentUser.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentUser.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Tipo: ${currentUser.tipo}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ] else
                  const Text(
                    'No has iniciado sesión',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),          // Divisor después del encabezado
          const Divider(),
          
          if (!isAuthenticated)
            ListTile(
              leading: const Icon(Icons.login, color: Colors.blue),
              title: const Text('Iniciar Sesión'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
                context.go('/');
              },
            )
          else
            Column(
              children: [
                // Opción de mapa según tipo de usuario
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: Text(currentUser?.tipo == 'cliente' 
                      ? 'Ver Mapa Cliente' 
                      : currentUser?.tipo == 'debugger'
                        ? 'Ver Todas las Rutas'
                        : 'Ver Mi Ruta'),
                  subtitle: Text(currentUser?.tipo == 'cliente'
                      ? 'Ver ubicación de micros'
                      : currentUser?.tipo == 'debugger'
                        ? 'Modo debug - Ver todo'
                        : 'Ver mi ruta asignada'),
                  onTap: () {
                    Navigator.pop(context);
                    if (currentUser?.tipo == 'cliente') {
                      context.go('/client-map');
                    } else if (currentUser?.tipo == 'debugger') {
                      context.go('/client-map'); // El debugger puede ver todo como cliente
                    } else {
                      context.go('/micrero-dashboard');
                    }
                  },
                ),
                
                const Divider(),
                
                // Sección de perfil
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'Mi cuenta',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text('Mi Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar navegación a perfil
                    // context.go('/profile');
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar navegación a configuración
                    // context.go('/settings');
                  },
                ),
                  const Divider(),
                
                // PARA DESARROLLO: Permite cambiar entre los modos
                if (currentUser != null && currentUser.tipo == 'debugger')
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.directions_bus, color: Colors.orange),
                        title: const Text('Modo Micrero'),
                        subtitle: const Text('Ver como conductor'),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/micrero-dashboard');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: const Text('Modo Cliente'),
                        subtitle: const Text('Ver como pasajero'),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/client-map');
                        },
                      ),
                    ],
                  ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión', 
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    // Guardar referencia al notifier antes del diálogo
                    final authNotifier = ref.read(authStateProvider.notifier);
                    
                    // Cerrar el drawer primero
                    Navigator.pop(context);
                    
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
                        
                        // Navegar a la pantalla de inicio de sesión
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
                ),
              ],
            ),
        ],
      ),
    );
  }
}
