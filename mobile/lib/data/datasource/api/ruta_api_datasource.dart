import 'dart:convert';
import 'package:app_map_tracking/config/constants.dart';
import 'package:app_map_tracking/data/models/ruta_model.dart';
import 'package:http/http.dart' as http;
import '../../models/entidad_model.dart';

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

  // 🔍 Método para obtener TODAS las rutas
  Future<List<RutaModel>> fetchAllRutas() async {
    try {
      print('🌐 Obteniendo todas las rutas desde: ${baseUrl}/ruta');
      final response = await client.get(Uri.parse('${baseUrl}/ruta'));

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body (primeros 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('🔍 Response structure: ${responseData.keys}');
        
        final data = responseData["data"];
        print('🔍 Data type: ${data.runtimeType}');
        print('🔍 Data is List: ${data is List}');
        
        if (data is List) {
          print('✅ API: Recibidas ${data.length} rutas');
          
          List<RutaModel> rutas = [];
          for (int i = 0; i < data.length; i++) {
            try {
              print('🔄 Procesando ruta $i: ${data[i]['id']}');
              final ruta = RutaModel.fromJson(data[i]);
              rutas.add(ruta);
              print('✅ Ruta $i procesada exitosamente');
            } catch (e) {
              print('❌ Error procesando ruta $i: $e');
              print('🔍 Data de ruta $i: ${data[i]}');
            }
          }
          
          return rutas;
        } else {
          throw Exception('Los datos no son una lista: ${data.runtimeType}');
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error al obtener todas las rutas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en fetchAllRutas: $e');
      rethrow;
    }
  }
}
