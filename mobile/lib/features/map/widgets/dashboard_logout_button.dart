import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';

class DashboardLogoutButton extends ConsumerWidget {
  const DashboardLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleLogout(context, ref),
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
    );
  }

  // Implementación EXACTA que funciona en el dashboard original
  void _handleLogout(BuildContext context, WidgetRef ref) async {
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
  }
} 