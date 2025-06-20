import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/entidad_provider.dart';

// Provider para verificar conectividad
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // Devolver el primer resultado de conectividad
    return results.isNotEmpty ? results.first : ConnectivityResult.none;
  });
});

// Provider para estado de conexión (boolean) - MEJORADO
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) {
      final hasConnectivity = result != ConnectivityResult.none;
      
      // Debug logging
      print('🔍 Conectividad: $result -> ${hasConnectivity ? "ONLINE" : "OFFLINE"}');
      
      return hasConnectivity;
    },
    loading: () {
      print('🔍 Conectividad: LOADING -> asumiendo ONLINE');
      return true; // Asumir online durante carga para evitar errores falsos
    },
    error: (error, stack) {
      print('🔍 Conectividad: ERROR -> asumiendo ONLINE');
      print('⚠️ Error de conectividad: $error');
      return true; // Asumir online en caso de error
    },
  );
});

// Provider para el servicio de sincronización
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncService {
  final Ref ref;
  bool _hasBeenOffline = false;

  SyncService(this.ref) {
    _monitorConnectivityChanges();
  }

  void _monitorConnectivityChanges() {
    ref.listen(connectivityProvider, (previous, next) {
      next.when(
        data: (connectivityResult) {
          final isOnline = connectivityResult != ConnectivityResult.none;
          
          if (!isOnline) {
            // Se perdió la conexión
            _hasBeenOffline = true;
            print('🔴 Conexión perdida - activando modo offline');
            print('📱 Las rutas ahora se cargarán desde la base de datos local');
          } else if (_hasBeenOffline) {
            // Se recuperó la conexión después de estar offline
            print('🟢 Conexión recuperada - iniciando sincronización automática');
            _syncDataWhenOnline();
            _hasBeenOffline = false;
          }
        },
        loading: () {},
        error: (error, stack) {
          print('❌ Error monitoreando conectividad: $error');
        },
      );
    });
  }

  Future<void> _syncDataWhenOnline() async {
    try {
      print('🔄 Iniciando sincronización automática de rutas...');
      
      // Invalidar los providers para forzar recarga desde API
      // Esto hará que los datos se obtengan nuevamente desde el servidor
      // y se guarden automáticamente en la BD local
      ref.invalidate(entidadProvider);
      
      print('✅ Providers invalidados - la próxima consulta traerá datos frescos del servidor');
      print('💾 Los datos se guardarán automáticamente en BD local para uso offline');
    } catch (e) {
      print('❌ Error en sincronización automática: $e');
    }
  }

  /// Método manual para forzar sincronización
  Future<void> forceSync() async {
    print('🔄 Sincronización manual iniciada...');
    await _syncDataWhenOnline();
  }

  /// Verificar si hay conexión actual
  bool get isOnline {
    return ref.read(isOnlineProvider);
  }

  /// Mostrar estado actual del modo offline
  void showOfflineStatus() {
    if (isOnline) {
      print('🟢 ESTADO: Online - datos desde servidor');
    } else {
      print('🔴 ESTADO: Offline - datos desde BD local');
    }
  }
} 