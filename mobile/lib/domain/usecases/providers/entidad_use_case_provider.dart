import 'package:app_map_tracking/domain/entities/entidad.dart';
import 'package:app_map_tracking/domain/repositories/providers/entidad_repository_provider.dart';
import 'package:app_map_tracking/domain/usecases/entidad_use_cases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entidadUseCasesProvider = FutureProvider<EntidadUseCases>((ref) async {
  final entidadRepository = await ref.watch(entidadRepositoryProvider.future);
  return EntidadUseCases(entidadRepository);
});