import 'package:app_map_tracking/data/datasource/api/providers/ruta_api_datasource_provider.dart';
import 'package:app_map_tracking/data/datasource/local/providers/ruta_local_datasource_provider.dart';
import 'package:app_map_tracking/data/repositories_impl/ruta_repository_impl.dart';
import 'package:app_map_tracking/domain/repositories/ruta_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rutaRepositoryProvider = FutureProvider<RutaRepository>((ref) async {
  final remoteDataSource = ref.watch(rutaApiDataSourceProvider);
  final localDataSource = await ref.watch(rutaLocalDataSourceProvider.future);
  return RutaRepositoryImpl(remoteDataSource, localDataSource);
});
