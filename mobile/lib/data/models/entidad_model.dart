import 'package:isar/isar.dart';
import '../../domain/entities/entidad.dart';

part 'entidad_model.g.dart';

@Collection()
class EntidadModel {
  EntidadModel();
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String codigo;

  late String nombre;
  late String tipo;
  late String direccion;
  late String correoContacto;
  late String walletAddress;
  late double saldoIngresos;
  late bool estado;

  Entidad toEntity() => Entidad(
    id: codigo,
    nombre: nombre,
    tipo: tipo,
    direccion: direccion,
    correoContacto: correoContacto,
    walletAddress: walletAddress,
    saldoIngresos: saldoIngresos,
    estado: estado,
  );

  factory EntidadModel.fromJson(Map<String, dynamic> json) => EntidadModel()
    ..codigo = json['id']
    ..nombre = json['nombre']
    ..tipo = json['tipo']
    ..direccion = json['direccion']
    ..correoContacto = json['correo_contacto']
    ..walletAddress = json['wallet_address']
    ..saldoIngresos = (json['saldo_ingresos'] as num).toDouble()
    ..estado = json['estado'];
}
