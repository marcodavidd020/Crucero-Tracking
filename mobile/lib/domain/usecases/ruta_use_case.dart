import 'package:app_map_tracking/domain/entities/ruta.dart';
import 'package:app_map_tracking/domain/repositories/ruta_repository.dart';

class RutaUseCase {
  final RutaRepository repository;

  RutaUseCase(this.repository);

  Future<Ruta> call(String id) async {
    return await repository.getRutaByIdEntidad(id);
  }
}
