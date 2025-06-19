import 'package:app_map_tracking/domain/repositories/providers/ruta_repository_provider.dart';
import 'package:app_map_tracking/domain/usecases/ruta_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rutaUseCaseProvider = FutureProvider.family((ref, String id) async {
  final repository = await ref.watch(rutaRepositoryProvider.future);
  final useCase = RutaUseCase(repository);
  return useCase(id);
});
