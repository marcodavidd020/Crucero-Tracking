import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';

/// Widget que muestra el estado offline/online para clientes
class OfflineStatusIndicator extends ConsumerWidget {
  const OfflineStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'En línea' : 'Modo offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget extendido que muestra información detallada del estado offline
class DetailedOfflineStatus extends ConsumerWidget {
  final bool isExpanded;
  
  const DetailedOfflineStatus({
    super.key,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    
    if (!isExpanded) {
      return const OfflineStatusIndicator();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Conectado al servidor' : 'Sin conexión a internet',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isOnline
                ? '• Datos sincronizados en tiempo real\n• Ubicaciones de micros actualizadas'
                : '• Usando datos locales guardados\n• Todas las rutas disponibles\n• Búsqueda funciona normalmente',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (!isOnline) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 Tip: Las rutas se sincronizarán automáticamente cuando tengas conexión',
                style: TextStyle(
                  color: Colors.orange[200],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 