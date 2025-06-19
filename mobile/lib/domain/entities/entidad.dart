class Entidad {
  final String id;
  final String nombre;
  final String tipo;
  final String direccion;
  final String correoContacto;
  final String walletAddress;
  final double saldoIngresos;
  final bool estado;

  Entidad({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.direccion,
    required this.correoContacto,
    required this.walletAddress,
    required this.saldoIngresos,
    required this.estado,
  });
}
