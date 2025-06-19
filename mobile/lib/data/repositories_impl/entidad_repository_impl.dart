import 'package:app_map_tracking/data/datasource/api/entidad_api_datasource.dart';
import 'package:app_map_tracking/data/datasource/local/entidad_local_datasource.dart';
import 'package:app_map_tracking/domain/entities/entidad.dart';
import 'package:app_map_tracking/domain/repositories/entidad_repository.dart';
import 'package:app_map_tracking/data/models/entidad_model.dart';

class EntidadRepositoryImpl implements EntidadRepository{
  final EntidadApiDatasource api;
  final EntidadLocalDatasource local;

  EntidadRepositoryImpl(this.api, this.local);

  @override
  Future<List<Entidad>> getEntidades() async {
    // 🔄 MODO SOLO LOCAL - No intentar API
    print("🔄 Obteniendo entidades SOLO desde base de datos local...");
    
    try {
      final localData = await local.getAll();
      final entities = localData.map((e) => e.toEntity()).toList();
      print("💾 Entidades locales encontradas: ${entities.length}");
      
      // Mostrar detalles si hay datos
      if (entities.isNotEmpty) {
        await local.debugPrintAll();
      } else {
        print("⚠️  No hay entidades en la base de datos local");
        print("💡 Tip: Primero necesitas poblar la BD con datos de prueba");
      }
      
      return entities;
    } catch (e) {
      print("❌ Error al obtener datos locales: $e");
      rethrow;
    }
  }

  // 🔍 Función para ver solo datos locales (sin intentar API)
  Future<List<Entidad>> getEntidadesLocal() async {
    print("🔄 Obteniendo SOLO datos locales...");
    try {
      final localData = await local.getAll();
      final entities = localData.map((e) => e.toEntity()).toList();
      print("💾 Datos locales encontrados: ${entities.length}");
      await local.debugPrintAll(); // Imprimir detalles
      return entities;
    } catch (e) {
      print("❌ Error al obtener datos locales: $e");
      rethrow;
    }
  }

  // ➕ Función para poblar datos de prueba localmente
  Future<void> poblarDatosPrueba() async {
    print("🌱 Poblando datos de prueba en base de datos local...");
    
    try {
      // 🚌 ENTIDADES DE SANTA CRUZ DE LA SIERRA, BOLIVIA
      final entidadesPrueba = [
        {
          'id': 'ENT001',
          'nombre': 'Surtrans',
          'tipo': 'Transporte Urbano',
          'direccion': 'Av. Alemana 123, Santa Cruz de la Sierra, Bolivia',
          'correo_contacto': 'contacto@surtrans.bo',
          'wallet_address': '0x1234567890abcdef1234567890abcdef12345678',
          'saldo_ingresos': 18500.75,
          'estado': true,
        },
        {
          'id': 'ENT002',
          'nombre': 'Línea Amarilla',
          'tipo': 'Transporte Público',
          'direccion': 'Av. San Martín 456, Santa Cruz de la Sierra, Bolivia',
          'correo_contacto': 'info@lineaamarilla.bo',
          'wallet_address': '0xabcdef1234567890abcdef1234567890abcdef12',
          'saldo_ingresos': 12300.50,
          'estado': true,
        },
        {
          'id': 'ENT003',
          'nombre': 'Copacabana',
          'tipo': 'Transporte Interprovincial',
          'direccion': 'Terminal Bimodal, Santa Cruz de la Sierra, Bolivia',
          'correo_contacto': 'admin@copacabana.bo',
          'wallet_address': '0x9876543210fedcba9876543210fedcba98765432',
          'saldo_ingresos': 25600.25,
          'estado': true,
        },
      ];

      // Convertir a modelos y guardar
      final modelos = entidadesPrueba.map((e) => 
        EntidadModel.fromJson(e)
      ).toList();
      
      await local.saveAll(modelos);
      print("✅ ${modelos.length} entidades de prueba guardadas exitosamente");
      
    } catch (e) {
      print("❌ Error al poblar datos de prueba: $e");
      rethrow;
    }
  }
}