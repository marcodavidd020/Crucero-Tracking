import 'package:app_map_tracking/data/datasource/api/entidad_api_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final entidadApiDataSourceProvider = Provider<EntidadApiDatasource>( (ref){
  final client = http.Client();
  return EntidadApiDatasource(client);
} );