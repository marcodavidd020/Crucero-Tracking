import 'dart:convert';

import 'package:app_map_tracking/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static const String  USER_LOGGED_KEY = "user_logged_key";
  static const String  SELECTED_ENTIDAD_ID = "user_logged_key";
  static const String  APP_LIFE_CYCLE_ESTATE = "app_life_cycle_estate";
  static const String RUTA_ID_KEY = "ruta_id_key";


  static final SharedPreferenceHelper _instance = SharedPreferenceHelper._internal();
  SharedPreferences? _sharedPreferences;

  factory SharedPreferenceHelper() => _instance;

  SharedPreferenceHelper._internal() {
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get sharedPreferences async {
    if (_sharedPreferences == null) {
      await _initializeSharedPreferences();
    }
    return _sharedPreferences!;
  }

  static Future<void> setUserLogged(UserModel usuario) async {
    final prefs = await SharedPreferenceHelper().sharedPreferences;
    prefs.setString(USER_LOGGED_KEY, json.encode(usuario));
  }

  static Future<UserModel?> getUserLogged() async {
    final prefs = await SharedPreferenceHelper().sharedPreferences;
    final userJson = prefs.getString(USER_LOGGED_KEY);

    if(userJson != null){
      final UserModel usuario = json.decode(userJson);
      return usuario;
    }
    return null;

  }

  Future<String?> getSelectedEntidad() async {
    final prefs = await sharedPreferences;
    return prefs.getString(SELECTED_ENTIDAD_ID);
  }

  Future<String?> getRutaId() async {
    final prefs = await sharedPreferences;
    return prefs.getString(RUTA_ID_KEY);
  }

  static Future<void> setRutaId(String id) async {
    final prefs = await SharedPreferenceHelper().sharedPreferences;
    prefs.setString(RUTA_ID_KEY, id);
  }
}