import 'package:app_map_tracking/data/datasource/api/entidad_api_datasource.dart';
import 'package:app_map_tracking/data/datasource/api/ruta_api_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final rutaApiDataSourceProvider = Provider<RutaApiDatasource>( (ref){
  final client = http.Client();
  return RutaApiDatasource(client);
} );