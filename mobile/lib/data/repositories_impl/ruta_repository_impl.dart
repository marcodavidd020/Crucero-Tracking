import 'package:app_map_tracking/data/datasource/api/ruta_api_datasource.dart';
import 'package:app_map_tracking/data/datasource/local/ruta_local_datasource.dart';
import 'package:app_map_tracking/domain/entities/ruta.dart';
import 'package:app_map_tracking/domain/repositories/ruta_repository.dart';
import 'package:app_map_tracking/data/models/ruta_model.dart';

class RutaRepositoryImpl implements RutaRepository {
  final RutaApiDatasource api;
  final RutaLocalDatasource local;

  RutaRepositoryImpl(this.api, this.local);

  @override
  Future<Ruta> getRutaByIdEntidad(String idEntidad) async {
    // 🔄 MODO SOLO LOCAL - No intentar API
    print("🔄 Obteniendo rutas SOLO desde base de datos local para entidad: $idEntidad");
    
    try {
      final localData = await local.getRutasByEntidad(idEntidad);
      
      if (localData.isNotEmpty) {
        print("💾 Rutas locales encontradas: ${localData.length}");
        await local.debugPrintByEntidad(idEntidad);
        return localData[0].toEntity();
      } else {
        print("⚠️  No hay rutas para la entidad $idEntidad en la base de datos local");
        print("💡 Tip: Primero necesitas poblar la BD con datos de prueba");
        
        // Poblar datos de prueba si no hay datos
        await poblarRutasPrueba();
        
        // Intentar de nuevo después de poblar
        final newLocalData = await local.getRutasByEntidad(idEntidad);
        if (newLocalData.isNotEmpty) {
          return newLocalData[0].toEntity();
        } else {
          throw Exception("No se encontraron rutas para la entidad $idEntidad");
        }
      }
    } catch (e) {
      print("❌ Error al obtener rutas locales: $e");
      rethrow;
    }
  }

  // ➕ Función para poblar rutas de prueba localmente
  Future<void> poblarRutasPrueba() async {
    print("🌱 Poblando rutas de prueba en base de datos local...");
    
    try {
      // 🛣️ RUTAS DE SANTA CRUZ DE LA SIERRA, BOLIVIA
      final rutasPrueba = [
        {
          'id': 'RUT001',
          'id_entidad': 'ENT001',
          'nombre': 'Centro - Plan 3000',
          'descripcion': 'Ruta desde el centro de Santa Cruz hasta el Plan 3000',
          'origenLat': '-17.79329000',
          'origenLong': '-63.18680000',
          'destinoLat': '-17.78120000',
          'destinoLong': '-63.18883000',
          'vertices': '[{"lat":-17.79329,"lng":-63.1868},{"lat":-17.79051,"lng":-63.18722},{"lat":-17.7887,"lng":-63.18777},{"lat":-17.78693,"lng":-63.18843},{"lat":-17.78533,"lng":-63.18888},{"lat":-17.78328,"lng":-63.18886},{"lat":-17.7812,"lng":-63.18883}]',
          'distancia': 8.5,
          'tiempo': 25.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'RUT003',
          'id_entidad': 'ENT002',
          'nombre': 'Equipetrol - Terminal',
          'descripcion': 'Ruta desde Equipetrol Norte hasta Terminal Bimodal',
          'origenLat': '-17.76500000',
          'origenLong': '-63.19500000',
          'destinoLat': '-17.80500000',
          'destinoLong': '-63.13500000',
          'vertices': '[{"lat":-17.7650,"lng":-63.1950},{"lat":-17.7750,"lng":-63.1850},{"lat":-17.7850,"lng":-63.1650},{"lat":-17.7950,"lng":-63.1500},{"lat":-17.8050,"lng":-63.1350}]',
          'distancia': 15.2,
          'tiempo': 40.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'RUT004',
          'id_entidad': 'ENT002',
          'nombre': 'Las Palmas - Centro',
          'descripcion': 'Conexión desde Las Palmas hasta el centro comercial',
          'origenLat': '-17.74000000',
          'origenLong': '-63.17000000',
          'destinoLat': '-17.78390000',
          'destinoLong': '-63.18190000',
          'vertices': '[{"lat":-17.7400,"lng":-63.1700},{"lat":-17.7500,"lng":-63.1750},{"lat":-17.7650,"lng":-63.1780},{"lat":-17.7750,"lng":-63.1800},{"lat":-17.7839,"lng":-63.1819}]',
          'distancia': 9.8,
          'tiempo': 28.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'RUT005',
          'id_entidad': 'ENT003',
          'nombre': 'Santa Cruz - Warnes',
          'descripcion': 'Ruta interprovincial desde Santa Cruz hacia Warnes',
          'origenLat': '-17.78390000',
          'origenLong': '-63.18190000',
          'destinoLat': '-17.51670000',
          'destinoLong': '-63.16670000',
          'vertices': '[{"lat":-17.7839,"lng":-63.1819},{"lat":-17.7500,"lng":-63.1750},{"lat":-17.7000,"lng":-63.1700},{"lat":-17.6500,"lng":-63.1680},{"lat":-17.6000,"lng":-63.1670},{"lat":-17.5500,"lng":-63.1668},{"lat":-17.5167,"lng":-63.1667}]',
          'distancia': 32.4,
          'tiempo': 50.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      // Convertir a modelos y guardar
      final modelos = rutasPrueba.map((e) => 
        RutaModel.fromJson(e)
      ).toList();
      
      await local.saveAll(modelos);
      print("✅ ${modelos.length} rutas de prueba guardadas exitosamente");
      
    } catch (e) {
      print("❌ Error al poblar rutas de prueba: $e");
      rethrow;
    }
  }

  @override
  Future<List<Ruta>> getAllRutas() async {
    print("🔍 === OBTENIENDO TODAS LAS RUTAS ===");
    
    try {
      // 🌐 Intentar obtener desde API primero
      try {
        print("🌐 Intentando obtener rutas desde API...");
        final apiData = await api.fetchAllRutas();
        
        if (apiData.isNotEmpty) {
          print("✅ API: Recibidas ${apiData.length} rutas desde backend");
          
          // 🗑️ Limpiar caché antes de guardar datos nuevos del API
          await local.clearAll();
          
          // Guardar en local para caché
          await local.saveAll(apiData);
          print("💾 Rutas del backend guardadas en caché local");
          
          return apiData.map((model) => model.toEntity()).toList();
        }
      } catch (e) {
        print("⚠️ Error de API: $e");
        print("🔄 Intentando con datos locales...");
      }
      
      // 📱 Fallback a datos locales
      final allLocalData = await local.getAll();
      print("💾 Total de rutas locales encontradas: ${allLocalData.length}");
      
      if (allLocalData.isEmpty) {
        print("⚠️  No hay rutas en la base de datos local");
        print("💡 Intentando poblar datos de prueba de respaldo...");
        
        // Poblar datos de prueba solo si no hay conexión al backend
        await poblarRutasPrueba();
        
        // Intentar de nuevo después de poblar
        final newLocalData = await local.getAll();
        if (newLocalData.isNotEmpty) {
          print("✅ Datos de respaldo poblados. Total: ${newLocalData.length} rutas");
          return newLocalData.map((model) => model.toEntity()).toList();
        } else {
          print("❌ No se pudieron poblar las rutas");
          return [];
        }
      }
      
      // Convertir modelos a entidades
      final rutas = allLocalData.map((model) => model.toEntity()).toList();
      
      // Debug: mostrar información de las rutas
      for (int i = 0; i < rutas.length; i++) {
        final ruta = rutas[i];
        print("🛣️ Ruta ${i + 1}: ${ruta.nombre} (${ruta.id}) - Entidad: ${ruta.idEntidad}");
      }
      
      return rutas;
      
    } catch (e) {
      print("❌ Error al obtener todas las rutas: $e");
      return [];
    }
  }
}
