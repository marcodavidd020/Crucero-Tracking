import 'package:app_map_tracking/features/auth/models/user_model.dart';
import 'package:app_map_tracking/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants.dart';
import '../../../features/providers/micrero_provider.dart';
import '../../../common/shared_preference_helper.dart';
import '../../../services/tracking_socket_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

// Provider para almacenar el usuario actual
final userProvider = StateProvider<UserModel?>((ref) => null);

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ApiService(baseUrl: baseUrl), ref);
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final Ref _ref;

  AuthStateNotifier(this._apiService, this._ref) : super(AuthState.initial);
  
  // El usuario ahora lo obtenemos directamente del userProvider
  UserModel? get user => _ref.read(userProvider);  Future<void> login(String email, String password) async {
    try {
      state = AuthState.loading;
      
      // Usar exactamente el mismo formato que en Postman
      final data = {
        'correo': email,
        'contrasena': password,
      };
      
      print("🔐 Enviando login request: $data");
      final response = await _apiService.post('auth/sign-in', data);
      print("📱 API Response del servidor: $response");
      
      // ARREGLO: Validar tanto formato success como statusCode
      bool isSuccessful = false;
      
      if (response != null && response['data'] != null) {
        // Formato con success: true
        if (response['success'] == true) {
          isSuccessful = true;
        }
        // Formato con statusCode 200-299
        else if (response.containsKey('statusCode')) {
          final statusCode = response['statusCode'];
          if (statusCode >= 200 && statusCode < 300) {
            isSuccessful = true;
          }
        }
      }
      
      if (isSuccessful) {
        final responseData = response['data'];
        
        // CORREGIR: Pasar todos los datos del response al UserModel
        final usuario = UserModel.fromJson(responseData);
        
        // Guardar información de la entidad en localStorage para uso posterior
        if (usuario.esMicrero && usuario.entidadId != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('entidad_id', usuario.entidadId!);
            print('💾 Entidad ID guardada en localStorage: ${usuario.entidadId}');
          } catch (e) {
            print('⚠️ Error guardando entidad ID: $e');
          }
        }
        
        // Guardar el usuario autenticado
        _ref.read(userProvider.notifier).state = usuario;
        
        print("✅ Usuario autenticado: ${usuario.nombre}, ${usuario.email}, ${usuario.tipo}");
        state = AuthState.authenticated;
      } else {
        final message = response?['message'] ?? 'Unknown error';
        print("❌ Error: Login falló - $message");
        state = AuthState.error;
        throw Exception('Login failed: $message');
      }
    } catch (e) {
      print("❌ Error en login: $e");
      state = AuthState.error;
      throw Exception('Login failed: $e');
    }
  }
  Future<void> logout() async {
    print('🔓 Iniciando proceso de logout...');
    
    // Cambiar el estado inmediatamente para evitar problemas de UI
    state = AuthState.loading;
    
    try {
      // 1. Detener servicios de tracking si están activos
      try {
        final trackingService = TrackingSocketService();
        trackingService.stopLocationTracking();
        trackingService.dispose();
        print('✅ Servicios de tracking detenidos');
      } catch (e) {
        print('⚠️ Error deteniendo tracking: $e');
        // No es crítico si falla
      }
      
      // 2. Limpiar datos de SharedPreferences de forma más robusta
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Lista de todas las claves a limpiar
        final keysToRemove = [
          SharedPreferenceHelper.USER_LOGGED_KEY,
          SharedPreferenceHelper.SELECTED_ENTIDAD_ID,
          SharedPreferenceHelper.RUTA_ID_KEY,
          'pendingLocations',
          'entidad_id',
          'ruta_activa_id',
          'ruta_activa_nombre',
          'user_type',
          'is_logged_in',
        ];
        
        // Limpiar cada clave
        for (final key in keysToRemove) {
          try {
            await prefs.remove(key);
          } catch (e) {
            print('⚠️ Error limpiando clave $key: $e');
          }
        }
        
        // Limpiar todas las claves que empiecen con ciertos prefijos
        final allKeys = prefs.getKeys();
        for (final key in allKeys) {
          if (key.startsWith('location_') || 
              key.startsWith('route_') || 
              key.startsWith('tracking_')) {
            try {
              await prefs.remove(key);
            } catch (e) {
              print('⚠️ Error limpiando clave prefijo $key: $e');
            }
          }
        }
        
        print('✅ SharedPreferences limpiado completamente');
      } catch (e) {
        print('⚠️ Error limpiando SharedPreferences: $e');
        // Intentar limpiar al menos las claves principales
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear(); // Limpiar todo como último recurso
          print('✅ SharedPreferences limpiado con clear()');
        } catch (clearError) {
          print('❌ Error en clear(): $clearError');
        }
      }
      
      // 3. Limpiar el estado del usuario en el provider de forma segura
      try {
        _ref.read(userProvider.notifier).state = null;
        print('✅ Estado de usuario limpiado');
      } catch (e) {
        print('⚠️ Error limpiando estado de usuario: $e');
      }
      
      // 4. Cambiar el estado de autenticación
      state = AuthState.unauthenticated;
      
      print('✅ Logout completado exitosamente');
      
    } catch (e) {
      print('❌ Error durante logout: $e');
      
      // Aún así, intentar limpiar el estado básico para no dejar la app en estado inconsistente
      try {
        _ref.read(userProvider.notifier).state = null;
        state = AuthState.unauthenticated;
        print('✅ Estado básico limpiado después de error');
      } catch (stateError) {
        print('❌ Error crítico limpiando estado: $stateError');
        // Como último recurso, forzar el estado
        state = AuthState.unauthenticated;
      }
      
      // Re-lanzar el error para que el UI pueda manejarlo
      rethrow;
    }
  }
}

// Provider para acceder al usuario actual
// Ahora simplemente redirige al userProvider
final currentUsuarioProvider = Provider<UserModel?>((ref) {
  final user = ref.watch(userProvider);
  print("currentUsuarioProvider llamado - usuario: ${user?.nombre ?? 'null'}");
  return user;
});
