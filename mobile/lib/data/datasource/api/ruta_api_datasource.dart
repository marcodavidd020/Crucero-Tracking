import 'dart:convert';
import 'package:app_map_tracking/config/constants.dart';
import 'package:app_map_tracking/data/models/ruta_model.dart';
import 'package:http/http.dart' as http;
import '../../models/entidad_model.dart';
import 'entidad_api_datasource.dart';

class RutaApiDatasource {
  final http.Client client;

  RutaApiDatasource(this.client);

  Future<List<RutaModel>> fetchRutasByIdEntidad(String idEntidad) async {
    final response = await client.get(Uri.parse('${baseUrl}/ruta/${idEntidad}'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List data = responseData["data"]['rutas'];
      return data.map((e) => RutaModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener rutas de la entidad');
    }
  }

  // 🔍 Método para obtener TODAS las rutas de TODAS las entidades
  Future<List<RutaModel>> fetchAllRutas() async {
    try {
      print('🔍 === OBTENIENDO TODAS LAS RUTAS POR ENTIDADES ===');
      
      // 1. Primero obtener todas las entidades
      final entidadDatasource = EntidadApiDatasource(client);
      final entidades = await entidadDatasource.fetchEntidades();
      print('🏢 Entidades encontradas: ${entidades.length}');
      
      // 2. Luego obtener rutas de cada entidad
      List<RutaModel> todasLasRutas = [];
      
      for (final entidad in entidades) {
        try {
          print('🌐 Obteniendo rutas de entidad: ${entidad.nombre} (${entidad.codigo})');
          final rutasEntidad = await fetchRutasByIdEntidad(entidad.codigo);
          todasLasRutas.addAll(rutasEntidad);
          print('✅ ${rutasEntidad.length} rutas obtenidas de ${entidad.nombre}');
        } catch (e) {
          print('⚠️ Error obteniendo rutas de ${entidad.nombre}: $e');
          // Continuar con la siguiente entidad
        }
      }
      
      print('✅ Total de rutas obtenidas: ${todasLasRutas.length}');
      return todasLasRutas;
      
    } catch (e) {
      print('❌ Error en fetchAllRutas: $e');
      rethrow;
    }
  }
}
