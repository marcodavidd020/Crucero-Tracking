import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/ruta_provider.dart';

class ClientSearchBar extends ConsumerWidget {
  final VoidCallback? onSearchTap;

  const ClientSearchBar({
    super.key,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRuta = ref.watch(selectedRutaProvider);
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: selectedRuta != null 
                ? '🛣️ ${selectedRuta.nombre} - Toca para cambiar'
                : '🔍 Buscar línea de transporte...',
            suffixIcon: selectedRuta != null 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.search),
            prefixIcon: selectedRuta != null 
                ? const Icon(Icons.route, color: Colors.blue)
                : const Icon(Icons.business),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            fillColor: selectedRuta != null 
                ? Colors.green.withOpacity(0.1)
                : null,
            filled: selectedRuta != null,
          ),
          onTap: onSearchTap ?? () async {
            print('🔍 Abriendo búsqueda de rutas...');
            final result = await context.push("/search-route");
            if (result == true) {
              print('✅ Búsqueda completada');
            }
          },
        ),
      ),
    );
  }
} 