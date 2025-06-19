import 'package:app_map_tracking/data/datasource/api/providers/entidad_api_datasource_provider.dart';
import 'package:app_map_tracking/data/datasource/local/providers/entidad_local_datasource_provider.dart';
import 'package:app_map_tracking/data/repositories_impl/entidad_repository_impl.dart';
import 'package:app_map_tracking/domain/repositories/entidad_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entidadRepositoryProvider = FutureProvider<EntidadRepository>((ref) {
  final remoteDataSource = ref.watch(entidadApiDataSourceProvider);
  final localDataSource = ref.watch(entidadLocalDataSourceProvider).requireValue;
  return EntidadRepositoryImpl(remoteDataSource, localDataSource);
});