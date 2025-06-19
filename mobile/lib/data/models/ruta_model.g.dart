// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ruta_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRutaModelCollection on Isar {
  IsarCollection<RutaModel> get rutaModels => this.collection();
}

const RutaModelSchema = CollectionSchema(
  name: r'RutaModel',
  id: -2523608373054187089,
  properties: {
    r'codigo': PropertySchema(
      id: 0,
      name: r'codigo',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'descripcion': PropertySchema(
      id: 2,
      name: r'descripcion',
      type: IsarType.string,
    ),
    r'destinoLat': PropertySchema(
      id: 3,
      name: r'destinoLat',
      type: IsarType.double,
    ),
    r'destinoLong': PropertySchema(
      id: 4,
      name: r'destinoLong',
      type: IsarType.double,
    ),
    r'distancia': PropertySchema(
      id: 5,
      name: r'distancia',
      type: IsarType.double,
    ),
    r'idEntidad': PropertySchema(
      id: 6,
      name: r'idEntidad',
      type: IsarType.string,
    ),
    r'nombre': PropertySchema(
      id: 7,
      name: r'nombre',
      type: IsarType.string,
    ),
    r'origenLat': PropertySchema(
      id: 8,
      name: r'origenLat',
      type: IsarType.double,
    ),
    r'origenLong': PropertySchema(
      id: 9,
      name: r'origenLong',
      type: IsarType.double,
    ),
    r'tiempo': PropertySchema(
      id: 10,
      name: r'tiempo',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'vertices': PropertySchema(
      id: 12,
      name: r'vertices',
      type: IsarType.string,
    )
  },
  estimateSize: _rutaModelEstimateSize,
  serialize: _rutaModelSerialize,
  deserialize: _rutaModelDeserialize,
  deserializeProp: _rutaModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'codigo': IndexSchema(
      id: 2475659939796141935,
      name: r'codigo',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'codigo',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _rutaModelGetId,
  getLinks: _rutaModelGetLinks,
  attach: _rutaModelAttach,
  version: '3.1.0',
);

int _rutaModelEstimateSize(
  RutaModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.codigo.length * 3;
  bytesCount += 3 + object.descripcion.length * 3;
  bytesCount += 3 + object.idEntidad.length * 3;
  bytesCount += 3 + object.nombre.length * 3;
  bytesCount += 3 + object.vertices.length * 3;
  return bytesCount;
}

void _rutaModelSerialize(
  RutaModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.codigo);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.descripcion);
  writer.writeDouble(offsets[3], object.destinoLat);
  writer.writeDouble(offsets[4], object.destinoLong);
  writer.writeDouble(offsets[5], object.distancia);
  writer.writeString(offsets[6], object.idEntidad);
  writer.writeString(offsets[7], object.nombre);
  writer.writeDouble(offsets[8], object.origenLat);
  writer.writeDouble(offsets[9], object.origenLong);
  writer.writeDouble(offsets[10], object.tiempo);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeString(offsets[12], object.vertices);
}

RutaModel _rutaModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RutaModel();
  object.codigo = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.descripcion = reader.readString(offsets[2]);
  object.destinoLat = reader.readDouble(offsets[3]);
  object.destinoLong = reader.readDouble(offsets[4]);
  object.distancia = reader.readDouble(offsets[5]);
  object.id = id;
  object.idEntidad = reader.readString(offsets[6]);
  object.nombre = reader.readString(offsets[7]);
  object.origenLat = reader.readDouble(offsets[8]);
  object.origenLong = reader.readDouble(offsets[9]);
  object.tiempo = reader.readDouble(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  object.vertices = reader.readString(offsets[12]);
  return object;
}

P _rutaModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _rutaModelGetId(RutaModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _rutaModelGetLinks(RutaModel object) {
  return [];
}

void _rutaModelAttach(IsarCollection<dynamic> col, Id id, RutaModel object) {
  object.id = id;
}

extension RutaModelByIndex on IsarCollection<RutaModel> {
  Future<RutaModel?> getByCodigo(String codigo) {
    return getByIndex(r'codigo', [codigo]);
  }

  RutaModel? getByCodigoSync(String codigo) {
    return getByIndexSync(r'codigo', [codigo]);
  }

  Future<bool> deleteByCodigo(String codigo) {
    return deleteByIndex(r'codigo', [codigo]);
  }

  bool deleteByCodigoSync(String codigo) {
    return deleteByIndexSync(r'codigo', [codigo]);
  }

  Future<List<RutaModel?>> getAllByCodigo(List<String> codigoValues) {
    final values = codigoValues.map((e) => [e]).toList();
    return getAllByIndex(r'codigo', values);
  }

  List<RutaModel?> getAllByCodigoSync(List<String> codigoValues) {
    final values = codigoValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'codigo', values);
  }

  Future<int> deleteAllByCodigo(List<String> codigoValues) {
    final values = codigoValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'codigo', values);
  }

  int deleteAllByCodigoSync(List<String> codigoValues) {
    final values = codigoValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'codigo', values);
  }

  Future<Id> putByCodigo(RutaModel object) {
    return putByIndex(r'codigo', object);
  }

  Id putByCodigoSync(RutaModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'codigo', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCodigo(List<RutaModel> objects) {
    return putAllByIndex(r'codigo', objects);
  }

  List<Id> putAllByCodigoSync(List<RutaModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'codigo', objects, saveLinks: saveLinks);
  }
}

extension RutaModelQueryWhereSort
    on QueryBuilder<RutaModel, RutaModel, QWhere> {
  QueryBuilder<RutaModel, RutaModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RutaModelQueryWhere
    on QueryBuilder<RutaModel, RutaModel, QWhereClause> {
  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> codigoEqualTo(
      String codigo) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'codigo',
        value: [codigo],
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterWhereClause> codigoNotEqualTo(
      String codigo) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'codigo',
              lower: [],
              upper: [codigo],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'codigo',
              lower: [codigo],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'codigo',
              lower: [codigo],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'codigo',
              lower: [],
              upper: [codigo],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RutaModelQueryFilter
    on QueryBuilder<RutaModel, RutaModel, QFilterCondition> {
  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'codigo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'codigo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'codigo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'codigo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'codigo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'codigo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'codigo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'codigo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'codigo',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> codigoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'codigo',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> descripcionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      descripcionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> descripcionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> descripcionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'descripcion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      descripcionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> descripcionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> descripcionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> descripcionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descripcion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      descripcionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descripcion',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      descripcionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descripcion',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> destinoLatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destinoLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      destinoLatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'destinoLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> destinoLatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'destinoLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> destinoLatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'destinoLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> destinoLongEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destinoLong',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      destinoLongGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'destinoLong',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> destinoLongLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'destinoLong',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> destinoLongBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'destinoLong',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> distanciaEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distancia',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      distanciaGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distancia',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> distanciaLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distancia',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> distanciaBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distancia',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idEntidad',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      idEntidadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idEntidad',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idEntidad',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idEntidad',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idEntidad',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idEntidad',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idEntidad',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idEntidad',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> idEntidadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idEntidad',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      idEntidadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idEntidad',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nombre',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombre',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombre',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> nombreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombre',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> origenLatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'origenLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      origenLatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'origenLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> origenLatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'origenLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> origenLatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'origenLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> origenLongEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'origenLong',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      origenLongGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'origenLong',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> origenLongLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'origenLong',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> origenLongBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'origenLong',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> tiempoEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tiempo',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> tiempoGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tiempo',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> tiempoLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tiempo',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> tiempoBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tiempo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vertices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vertices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vertices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vertices',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'vertices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'vertices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'vertices',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'vertices',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition> verticesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vertices',
        value: '',
      ));
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterFilterCondition>
      verticesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'vertices',
        value: '',
      ));
    });
  }
}

extension RutaModelQueryObject
    on QueryBuilder<RutaModel, RutaModel, QFilterCondition> {}

extension RutaModelQueryLinks
    on QueryBuilder<RutaModel, RutaModel, QFilterCondition> {}

extension RutaModelQuerySortBy on QueryBuilder<RutaModel, RutaModel, QSortBy> {
  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByCodigo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codigo', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByCodigoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codigo', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDestinoLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLat', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDestinoLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLat', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDestinoLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLong', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDestinoLongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLong', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDistancia() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distancia', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByDistanciaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distancia', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByIdEntidad() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idEntidad', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByIdEntidadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idEntidad', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByOrigenLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLat', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByOrigenLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLat', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByOrigenLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLong', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByOrigenLongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLong', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByTiempo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tiempo', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByTiempoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tiempo', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByVertices() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vertices', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> sortByVerticesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vertices', Sort.desc);
    });
  }
}

extension RutaModelQuerySortThenBy
    on QueryBuilder<RutaModel, RutaModel, QSortThenBy> {
  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByCodigo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codigo', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByCodigoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'codigo', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDestinoLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLat', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDestinoLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLat', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDestinoLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLong', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDestinoLongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoLong', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDistancia() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distancia', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByDistanciaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distancia', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByIdEntidad() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idEntidad', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByIdEntidadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idEntidad', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByOrigenLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLat', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByOrigenLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLat', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByOrigenLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLong', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByOrigenLongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origenLong', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByTiempo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tiempo', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByTiempoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tiempo', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByVertices() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vertices', Sort.asc);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QAfterSortBy> thenByVerticesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vertices', Sort.desc);
    });
  }
}

extension RutaModelQueryWhereDistinct
    on QueryBuilder<RutaModel, RutaModel, QDistinct> {
  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByCodigo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'codigo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByDescripcion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descripcion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByDestinoLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destinoLat');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByDestinoLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destinoLong');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByDistancia() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distancia');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByIdEntidad(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idEntidad', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByNombre(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nombre', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByOrigenLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'origenLat');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByOrigenLong() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'origenLong');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByTiempo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tiempo');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<RutaModel, RutaModel, QDistinct> distinctByVertices(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vertices', caseSensitive: caseSensitive);
    });
  }
}

extension RutaModelQueryProperty
    on QueryBuilder<RutaModel, RutaModel, QQueryProperty> {
  QueryBuilder<RutaModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RutaModel, String, QQueryOperations> codigoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'codigo');
    });
  }

  QueryBuilder<RutaModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<RutaModel, String, QQueryOperations> descripcionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descripcion');
    });
  }

  QueryBuilder<RutaModel, double, QQueryOperations> destinoLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destinoLat');
    });
  }

  QueryBuilder<RutaModel, double, QQueryOperations> destinoLongProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destinoLong');
    });
  }

  QueryBuilder<RutaModel, double, QQueryOperations> distanciaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distancia');
    });
  }

  QueryBuilder<RutaModel, String, QQueryOperations> idEntidadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idEntidad');
    });
  }

  QueryBuilder<RutaModel, String, QQueryOperations> nombreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nombre');
    });
  }

  QueryBuilder<RutaModel, double, QQueryOperations> origenLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'origenLat');
    });
  }

  QueryBuilder<RutaModel, double, QQueryOperations> origenLongProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'origenLong');
    });
  }

  QueryBuilder<RutaModel, double, QQueryOperations> tiempoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tiempo');
    });
  }

  QueryBuilder<RutaModel, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<RutaModel, String, QQueryOperations> verticesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vertices');
    });
  }
}
