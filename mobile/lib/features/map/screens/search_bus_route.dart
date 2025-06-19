import 'package:app_map_tracking/common/shared_preference_helper.dart';
import 'package:app_map_tracking/domain/entities/entidad.dart';
import 'package:app_map_tracking/domain/entities/ruta.dart';
import 'package:app_map_tracking/features/providers/entidad_provider.dart';
import 'package:app_map_tracking/features/providers/ruta_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';


class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Entidad> _allEntidades = [];
  List<Entidad> _filteredEntidades = [];
  
  // 🛣️ Variables para rutas
  List<Ruta> _allRutas = [];
  List<Ruta> _filteredRutas = [];
  
  // 🔄 Control de modo de búsqueda
  bool _searchingRoutes = true; // Por defecto buscar rutas



  @override
  void initState() {
    super.initState();
    // _filteredItems = _allItems;
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_searchingRoutes) {
        // 🛣️ Filtrar rutas
        _filteredRutas = _allRutas
            .where((ruta) => 
                ruta.nombre.toLowerCase().contains(query) ||
                ruta.descripcion.toLowerCase().contains(query))
            .toList();
      } else {
        // 🚌 Filtrar entidades
        _filteredEntidades = _allEntidades
            .where((item) => item.nombre.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🛣️ Nueva función para guardar ruta seleccionada
  Future<void> _guardarRutaSeleccionada(BuildContext context, Ruta ruta) async {
    try {
      print('🎯 === GUARDANDO RUTA SELECCIONADA ===');
      print('🛣️ Ruta: ${ruta.nombre} (${ruta.id})');
      print('🏢 Entidad: ${ruta.idEntidad}');
      
      // Guardar la ruta seleccionada en el provider
      ref.read(selectedRutaProvider.notifier).state = ruta;
      
      // También guardar la entidad para compatibilidad
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPreferenceHelper.SELECTED_ENTIDAD_ID, ruta.idEntidad);
      
      print('✅ Ruta guardada exitosamente');
      
      // Mostrar confirmación
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ruta "${ruta.nombre}" seleccionada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Pequeña espera para que el usuario vea la confirmación
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Regresar con éxito
        context.pop(true);
      }
    } catch (e) {
      print('❌ Error guardando ruta: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🚌 Función para guardar entidad (modo legacy)
  Future<void> _guardarEntidadSeleccionada(BuildContext context, String entidadId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferenceHelper.SELECTED_ENTIDAD_ID, entidadId);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final entidadesAsync = ref.watch(entidadProvider);
    final rutasAsync = ref.watch(searchRutasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_searchingRoutes ? "Rutas de Santa Cruz" : "Líneas de Micros"),
        actions: [
          // 🔄 Botón para cambiar entre rutas y entidades
          IconButton(
            icon: Icon(_searchingRoutes ? Icons.route : Icons.directions_bus),
            onPressed: () {
              setState(() {
                _searchingRoutes = !_searchingRoutes;
                _searchController.clear();
              });
            },
            tooltip: _searchingRoutes ? 'Ver Entidades' : 'Ver Rutas',
          ),
        ],
      ),
      body: _searchingRoutes ? _buildRoutesView(rutasAsync) : _buildEntitiesView(entidadesAsync),
    );
  }

  // 🛣️ Vista para mostrar rutas
  Widget _buildRoutesView(AsyncValue<List<Ruta>> rutasAsync) {
    return rutasAsync.when(
      data: (rutas) {
        if (_allRutas.isEmpty) {
          _allRutas = rutas;
          _filteredRutas = rutas;
        }
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar rutas por nombre o descripción...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_filteredRutas.isEmpty && _searchController.text.isNotEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No se encontraron rutas'),
                      SizedBox(height: 8),
                      Text('Intenta con otro término de búsqueda', 
                        style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredRutas.length,
                  itemBuilder: (_, index) {
                    final ruta = _filteredRutas[index];
                    final isSelected = ref.watch(selectedRutaProvider)?.id == ruta.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          Icons.route, 
                          color: isSelected ? Colors.blue : Colors.blue.shade300,
                        ),
                        title: Text(
                          ruta.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue.shade700 : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ruta.descripcion),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('${ruta.distancia} km', 
                                  style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('${ruta.tiempo.toInt()} min', 
                                  style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios),
                          ],
                        ),
                        onTap: () => _guardarRutaSeleccionada(context, ruta),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error al cargar rutas: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(searchRutasProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  // 🚌 Vista para mostrar entidades (modo anterior)
  Widget _buildEntitiesView(AsyncValue<List<Entidad>> entidadesAsync) {
    return entidadesAsync.when(
      data: (entidades) {
        if (_allEntidades.isEmpty) {
          _allEntidades = entidades;
          _filteredEntidades = entidades;
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar entidades...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredEntidades.length,
                itemBuilder: (_, index) {
                  final entidad = _filteredEntidades[index];
                  return ListTile(
                    title: Text(entidad.nombre),
                    onTap: () => _guardarEntidadSeleccionada(context, entidad.id),
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
