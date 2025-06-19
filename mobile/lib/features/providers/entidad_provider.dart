import 'package:app_map_tracking/domain/usecases/providers/entidad_use_case_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entidad.dart';


final entidadProvider = FutureProvider.autoDispose<List<Entidad>>((ref) async {
  final useCase = await ref.watch(entidadUseCasesProvider.future);
  return useCase.call();
});
