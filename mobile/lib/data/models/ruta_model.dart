import 'dart:convert';
import 'package:app_map_tracking/domain/entities/ruta.dart';
import 'package:isar/isar.dart';

part 'ruta_model.g.dart';

@Collection()
class RutaModel {
  RutaModel();
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String codigo;

  late String idEntidad;
  late String nombre;
  late String descripcion;
  late double origenLat;
  late double origenLong;
  late double destinoLat;
  late double destinoLong;
  late String vertices;
  late double distancia;
  late double tiempo;
  late DateTime createdAt;
  late DateTime updatedAt;

  Ruta toEntity() =>  Ruta(
      id: codigo,
      idEntidad: idEntidad,
      nombre: nombre,
      descripcion: descripcion,
      origenLat: origenLat,
      origenLong: origenLong,
      destinoLat: destinoLat,
      destinoLong: destinoLong,
      vertices: vertices,
      distancia: distancia,
      tiempo: tiempo,
      createdAt: createdAt,
      updatedAt: updatedAt,
  );


  factory RutaModel.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Parsing RutaModel from JSON: ${json.keys}');
      return RutaModel()
        ..codigo = json['id'] ?? ''
        ..idEntidad = json['id_entidad'] ?? json['idEntidad'] ?? ''
        ..nombre = json['nombre'] ?? ''
        ..descripcion = json['descripcion'] ?? ''
        ..origenLat = _parseDouble(json['origen_lat'] ?? json['origenLat'])
        ..origenLong = _parseDouble(json['origen_long'] ?? json['origenLong'])
        ..destinoLat = _parseDouble(json['destino_lat'] ?? json['destinoLat'])
        ..destinoLong = _parseDouble(json['destino_long'] ?? json['destinoLong'])
        ..vertices = json['vertices'] ?? ''
        ..distancia = _parseDouble(json['distancia'])
        ..tiempo = _parseDouble(json['tiempo'])
        ..createdAt = _parseDateTime(json['created_at'] ?? json['createdAt'])
        ..updatedAt = _parseDateTime(json['updated_at'] ?? json['updatedAt']);
    } catch (e) {
      print('❌ Error parsing RutaModel: $e');
      print('🔍 JSON data: $json');
      rethrow;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}