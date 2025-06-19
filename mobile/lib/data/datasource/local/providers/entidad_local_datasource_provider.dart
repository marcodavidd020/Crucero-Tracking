import 'package:app_map_tracking/data/datasource/local/entidad_local_datasource.dart';
import 'package:app_map_tracking/data/models/entidad_model.dart';
import 'package:app_map_tracking/data/datasource/local/providers/isar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entidadLocalDataSourceProvider = FutureProvider<EntidadLocalDatasource>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return EntidadLocalDatasource(isar);
});