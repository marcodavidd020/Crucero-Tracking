import 'dart:convert';
import 'package:app_map_tracking/config/constants.dart';
import 'package:http/http.dart' as http;
import '../../models/entidad_model.dart';

class EntidadApiDatasource {
  final http.Client client;

  EntidadApiDatasource(this.client);

  Future<List<EntidadModel>> fetchEntidades() async {
    final url = '${baseUrl}/entidad-operadora';
    print('🌐 Intentando conectar a: $url');
    
    try {
      final response = await client.get(Uri.parse(url));
      print('📱 Status Code: ${response.statusCode}');
      print('📱 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List data = responseData["data"]['entidades'];
        print('✅ Entidades recibidas: ${data.length}');
        return data.map((e) => EntidadModel.fromJson(e)).toList();
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw Exception('Error al obtener entidades: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception en fetchEntidades: $e');
      rethrow;
    }
  }
}
