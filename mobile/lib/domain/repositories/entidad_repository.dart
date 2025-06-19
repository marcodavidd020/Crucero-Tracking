import 'package:app_map_tracking/domain/entities/entidad.dart';

abstract class EntidadRepository{
  Future<List<Entidad>> getEntidades();
}