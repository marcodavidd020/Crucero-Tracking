import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/models/user_model.dart';

// Datos de prueba para micreros de Santa Cruz usando UserModel
final List<UserModel> _micrerosPrueba = [
  // Carlos Mamani - datos reales de la BD con ruta de Santa Cruz
  UserModel(
    id: 'USR002',
    email: 'carlos.mamani@crucero.bo',
    nombre: 'Carlos Mamani',
    tipo: 'micrero',
    activo: true,
    microId: 'MICRO001',
    placaMicro: 'LAP-1234',
    entidadId: 'ENT001',
    rutaAsignada: 'Centro - Plan 3000',
  ),
  UserModel(
    id: '1',
    email: 'carlos.mendoza@surtrans.bo',
    nombre: 'Carlos Mendoza',
    tipo: 'micrero',
    activo: true,
    microId: '1',
    placaMicro: 'SCZ-1234',
    entidadId: '1',
    rutaAsignada: 'Centro - Plan 3000',
  ),
  UserModel(
    id: '2', 
    email: 'maria.vargas@lineaamarilla.bo',
    nombre: 'María Vargas',
    tipo: 'micrero',
    activo: true,
    microId: '3',
    placaMicro: 'SCZ-5678',
    entidadId: '2',
    rutaAsignada: 'Villa 1ro de Mayo - Centro',
  ),
  UserModel(
    id: '3',
    email: 'jose.rocha@copacabana.bo',
    nombre: 'José Rocha',
    tipo: 'micrero',
    activo: true,
    microId: '5',
    placaMicro: 'SCZ-9012',
    entidadId: '3',
    rutaAsignada: 'Equipetrol - Terminal',
  ),
  // Usuario debugger que puede ver todas las rutas
  UserModel(
    id: 'DEBUG001',
    email: 'debug@crucero.bo',
    nombre: 'Usuario Debug',
    tipo: 'debugger',
    activo: true,
    microId: 'DEBUG_MICRO',
    placaMicro: 'DEBUG-001',
    entidadId: 'DEBUG_ENT',
    rutaAsignada: 'Todas las Rutas - Debug',
  ),
];

// Provider para obtener micrero por email (simulación de login)
final micreroByEmailProvider = Provider.family<UserModel?, String>((ref, email) {
  try {
    return _micrerosPrueba.firstWhere((micrero) => micrero.email == email);
  } catch (e) {
    return null;
  }
});

// Provider para obtener todos los micreros
final micrerosProvider = Provider<List<UserModel>>((ref) {
  return _micrerosPrueba;
});

// Provider para obtener micrero por ID
final micreroByIdProvider = Provider.family<UserModel?, String>((ref, id) {
  try {
    return _micrerosPrueba.firstWhere((micrero) => micrero.id == id);
  } catch (e) {
    return null;
  }
});