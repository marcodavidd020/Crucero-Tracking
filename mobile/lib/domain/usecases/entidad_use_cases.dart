import 'package:app_map_tracking/domain/entities/entidad.dart';
import 'package:app_map_tracking/domain/repositories/entidad_repository.dart';

class EntidadUseCases {
  final EntidadRepository repository;

  EntidadUseCases(this.repository);

  Future<List<Entidad>> call() async {
    return await repository.getEntidades();
  }
}