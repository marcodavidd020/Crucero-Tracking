import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/auth/screens/user_type_selection_page.dart';
import '../features/auth/screens/login_page.dart';
import '../features/auth/screens/register_page.dart';
import '../features/map/screens/client_map_page.dart';
import '../features/map/screens/employee_map_page.dart';
import '../features/map/screens/micrero_dashboard.dart';
import '../features/map/screens/search_bus_route.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // Pantalla de selección de tipo de usuario
    GoRoute(
      path: '/',
      builder: (context, state) => const UserTypeSelectionPage(),
    ),
    
    // Login con parámetro de tipo de usuario
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final tipo = state.uri.queryParameters['tipo'] ?? 'cliente';
        return LoginPage(tipoUsuario: tipo);
      },
    ),
    
    // Registro con parámetro de tipo de usuario
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final tipo = state.uri.queryParameters['tipo'] ?? 'cliente';
        return RegisterPage(tipoUsuario: tipo);
      },
    ),
    
    // Dashboard para micreros
    GoRoute(
      path: '/micrero-dashboard',
      builder: (context, state) => const MicreroDashboard(),
    ),
    
    // Mapa para clientes (pasajeros)
    GoRoute(
      path: '/client-map',
      builder: (context, state) => const ClientMapPage(),
    ),
    
    // Mapa para micreros (empleados/conductores)
    GoRoute(
      path: '/employee-map',
      builder: (context, state) => const EmployeeMapPage(),
    ),
    
    // Búsqueda de rutas (solo para clientes)
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    
    // Ruta alternativa para búsqueda (legacy)
    GoRoute(
      path: '/search-route',
      builder: (context, state) => const SearchPage(),
    ),
  ],
  
  // Redirección basada en el tipo de usuario autenticado
  redirect: (context, state) {
    // Esta lógica se puede expandir para manejar autenticación
    // y redireccionar automáticamente según el tipo de usuario
    return null;
  },
  
  // Manejo de errores de navegación
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Error'),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Página no encontrada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'La ruta "${state.uri}" no existe',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al Inicio'),
          ),
        ],
      ),
    ),
  ),
);
