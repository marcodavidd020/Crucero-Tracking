import 'package:isar/isar.dart';
import '../../models/entidad_model.dart';

class EntidadLocalDatasource {
  final Isar isar;

  EntidadLocalDatasource(this.isar);

  Future<void> saveAll(List<EntidadModel> entidades) async {
    await isar.writeTxn(() async {
      for (final nuevaEntidad in entidades) {
        final existente = await isar.entidadModels
            .filter()
            .codigoEqualTo(nuevaEntidad.codigo)
            .findFirst();

        if (existente != null) {
          existente
            ..nombre = nuevaEntidad.nombre
            ..tipo = nuevaEntidad.tipo
            ..direccion = nuevaEntidad.direccion
            ..correoContacto = nuevaEntidad.correoContacto
            ..walletAddress = nuevaEntidad.walletAddress
            ..saldoIngresos = nuevaEntidad.saldoIngresos
            ..estado = nuevaEntidad.estado;

          await isar.entidadModels.put(existente);
        } else {
          await isar.entidadModels.put(nuevaEntidad);
        }
      }
    });
  }

  Future<List<EntidadModel>> getAll() async {
    return await isar.entidadModels.where().findAll();
  }

  // 🔍 Función de debug para imprimir todos los datos
  Future<void> debugPrintAll() async {
    final entidades = await getAll();
    print('📊 === DATOS LOCALES DE ENTIDADES ===');
    print('📋 Total de entidades: ${entidades.length}');
    
    for (int i = 0; i < entidades.length; i++) {
      final entidad = entidades[i];
      print('');
      print('🚌 Entidad ${i + 1}:');
      print('   ID: ${entidad.id} (Auto-increment)');
      print('   Código: ${entidad.codigo}');
      print('   Nombre: ${entidad.nombre}');
      print('   Tipo: ${entidad.tipo}');
      print('   Dirección: ${entidad.direccion}');
      print('   Email: ${entidad.correoContacto}');
      print('   Wallet: ${entidad.walletAddress}');
      print('   Saldo: \$${entidad.saldoIngresos}');
      print('   Estado: ${entidad.estado ? "Activo" : "Inactivo"}');
    }
    
    if (entidades.isEmpty) {
      print('⚠️  No hay entidades almacenadas localmente');
    }
    print('📊 === FIN DATOS ENTIDADES ===');
  }

  // 🗑️ Función para limpiar todos los datos (para testing)
  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.entidadModels.clear();
    });
    print('🗑️ Todas las entidades han sido eliminadas de la BD local');
  }
}
