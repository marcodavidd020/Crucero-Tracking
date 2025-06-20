import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardActionsGrid extends StatelessWidget {
  const DashboardActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
} 