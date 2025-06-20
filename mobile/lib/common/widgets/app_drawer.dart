import 'dart:async';
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
                  title: Text(currentUser?.tipo == 'CLIENTE' 
                      ? 'Ver Mapa Cliente' 
                      : currentUser?.tipo == 'debugger'
                        ? 'Ver Todas las Rutas'
                        : 'Ver Mi Ruta'),
                  subtitle: Text(currentUser?.tipo == 'CLIENTE'
                      ? 'Ver ubicación de micros'
                      : currentUser?.tipo == 'debugger'
                        ? 'Modo debug - Ver todo'
                        : 'Ver mi ruta asignada'),
                  onTap: () {
                    Navigator.pop(context);
                    if (currentUser?.tipo == 'CLIENTE') {
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
                
                // SOLO MOSTRAR OPCIONES ESPECÍFICAS PARA EMPLEADOS
                if (currentUser != null && currentUser.tipo == 'EMPLEADO')
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: Colors.orange),
                    title: const Text('Dashboard Micrero'),
                    subtitle: const Text('Panel de control'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/micrero-dashboard');
                    },
                  ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión', 
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _performSafeLogout(context, ref),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Implementación simplificada que evita pérdida de contexto
  void _performSafeLogout(BuildContext context, WidgetRef ref) async {
    // Cerrar drawer INMEDIATAMENTE
    Navigator.pop(context);
    print('✅ Drawer cerrado');

    // Guardar TODAS las referencias necesarias ANTES del diálogo
    final authNotifier = ref.read(authStateProvider.notifier);
    final navigator = GoRouter.of(context);
    
    // Pequeña pausa para que termine la animación del drawer
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) {
      print('❌ Contexto no válido después de cerrar drawer');
      return;
    }
    
    // Mostrar diálogo de confirmación
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true) {
      print('✅ Usuario confirmó logout desde drawer');
      
      try {
        // Realizar el logout INMEDIATAMENTE sin Timer
        await authNotifier.logout();
        print('✅ Logout completado desde drawer');
        
        // Navegar usando la referencia guardada
        navigator.go('/');
        print('✅ Navegación completada desde drawer');
        
      } catch (e) {
        print('❌ Error durante logout desde drawer: $e');
        
        // Fallback de navegación si hay error
        try {
          if (context.mounted) {
            context.go('/');
            print('✅ Navegación fallback completada');
          }
        } catch (navError) {
          print('❌ Error en navegación fallback: $navError');
        }
      }
    } else {
      print('ℹ️ Usuario canceló logout desde drawer');
    }
  }

}
