class Ruta {
  final String id;
  final String idEntidad;
  final String nombre;
  final String descripcion;
  final double origenLat;
  final double origenLong;
  final double destinoLat;
  final double destinoLong;
  final String vertices;
  final double distancia;
  final double tiempo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ruta({
    required this.id,
    required this.idEntidad,
    required this.nombre,
    required this.descripcion,
    required this.origenLat,
    required this.origenLong,
    required this.destinoLat,
    required this.destinoLong,
    required this.vertices,
    required this.distancia,
    required this.tiempo,
    required this.createdAt,
    required this.updatedAt,
  });
}