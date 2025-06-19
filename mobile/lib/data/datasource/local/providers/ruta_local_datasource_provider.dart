import 'package:app_map_tracking/data/datasource/local/ruta_local_datasource.dart';
import 'package:app_map_tracking/data/models/ruta_model.dart';
import 'package:app_map_tracking/data/datasource/local/providers/isar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rutaLocalDataSourceProvider = FutureProvider<RutaLocalDatasource>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return RutaLocalDatasource(isar);
});