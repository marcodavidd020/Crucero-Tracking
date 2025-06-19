import 'dart:convert';
import 'package:app_map_tracking/domain/usecases/providers/ruta_use_case_provider.dart';
import 'package:app_map_tracking/domain/entities/ruta.dart';
import 'package:app_map_tracking/features/providers/entidad_id_provider.dart';
import 'package:app_map_tracking/domain/repositories/providers/ruta_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

final rutaProvider = FutureProvider.autoDispose<Ruta>((ref) async {
  final entidadIdAsync = await ref.watch(entidadIdProvider.future);
  if (entidadIdAsync == null) throw Exception('Entidad ID is null');
  
  final ruta = await ref.watch(rutaUseCaseProvider(entidadIdAsync).future);
  return ruta;
});

// 🔍 Proveedor específico para búsqueda de rutas (ÚNICO PROVIDER ACTIVO)
final searchRutasProvider = FutureProvider.autoDispose<List<Ruta>>((ref) async {
  try {
    // Usar el repositorio directamente para obtener todas las rutas desde el backend
    final rutaRepository = await ref.watch(rutaRepositoryProvider.future);
    final rutas = await rutaRepository.getAllRutas();
    print('🔍 searchRutasProvider: Encontradas ${rutas.length} rutas desde backend');
    return rutas;
  } catch (e) {
    print('❌ Error en searchRutasProvider: $e');
    return [];
  }
});

// 🌟 Provider para ruta seleccionada específicamente por el usuario
final selectedRutaProvider = StateProvider<Ruta?>((ref) => null);

// Provider para obtener ruta por nombre (desde backend)
final rutaByNombreProvider = FutureProvider.family<Ruta?, String>((ref, nombre) async {
  try {
    final rutaRepository = await ref.watch(rutaRepositoryProvider.future);
    final rutas = await rutaRepository.getAllRutas();
    return rutas.where((ruta) => ruta.nombre == nombre).firstOrNull;
  } catch (e) {
    print('❌ Error buscando ruta por nombre: $e');
    return null;
  }
});

// Provider para obtener ruta por ID (desde backend)
final rutaByIdProvider = FutureProvider.family<Ruta?, String>((ref, id) async {
  try {
    final rutaRepository = await ref.watch(rutaRepositoryProvider.future);
    final rutas = await rutaRepository.getAllRutas();
    return rutas.where((ruta) => ruta.id == id).firstOrNull;
  } catch (e) {
    print('❌ Error buscando ruta por ID: $e');
    return null;
  }
});

// Función helper para convertir vertices JSON a LatLng
List<LatLng> parseVertices(String verticesJson) {
  try {
    print('🔍 Parsing vertices JSON: $verticesJson');
    final dynamic verticesData = json.decode(verticesJson);
    
    if (verticesData is List) {
      // Verificar si es un array de arrays [lng, lat] (formato del backend)
      if (verticesData.isNotEmpty && verticesData[0] is List) {
        print('📍 Formato backend detectado: array de arrays [lng, lat]');
        return verticesData.map<LatLng>((vertex) {
          if (vertex is List && vertex.length >= 2) {
            // El backend envía [longitude, latitude], pero LatLng espera (latitude, longitude)
            double lng = vertex[0].toDouble();
            double lat = vertex[1].toDouble();
            return LatLng(lat, lng);
          } else {
            throw Exception('Formato de vértice inválido: $vertex');
          }
        }).toList();
      } 
      // Formato local con objetos {"lat": ..., "lng": ...}
      else if (verticesData.isNotEmpty && verticesData[0] is Map) {
        print('📍 Formato local detectado: array de objetos {lat, lng}');
        return verticesData.map<LatLng>((vertex) {
          return LatLng(vertex['lat'].toDouble(), vertex['lng'].toDouble());
        }).toList();
      }
    }
    
    print('❌ Formato de vertices no reconocido');
    return [];
  } catch (e) {
    print('❌ Error parsing vertices: $e');
    return [];
  }
}

