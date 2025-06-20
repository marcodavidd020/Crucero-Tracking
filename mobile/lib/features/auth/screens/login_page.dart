import 'package:app_map_tracking/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String tipoUsuario;
  
  const LoginPage({Key? key, required this.tipoUsuario}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Ingrese un email válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {      await ref.read(authStateProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      
      // Obtener el usuario directamente del userProvider
      final user = ref.read(userProvider);
      print("Usuario después del login desde userProvider: $user");

      if (mounted) {
        if (user == null) {
          setState(() {
            _errorMessage = 'Error: No se pudo obtener la información del usuario';
          });
        } else if (user.esCliente || widget.tipoUsuario == 'cliente') {
          print('👤 Redirigiendo a mapa cliente');
          context.go('/client-map');
        } else if (user.esMicrero || widget.tipoUsuario == 'micrero') {
          print('🚌 Redirigiendo a dashboard micrero - Usuario: ${user.nombre}, Tipo: ${user.tipo}');
          context.go('/micrero-dashboard');
        } else {
          setState(() {
            _errorMessage = 'Tipo de usuario no reconocido: ${user.tipo}';
          });
        }
      }
    } catch (e) {
      print("Error capturado en login: $e");
      setState(() {
        _errorMessage = 'Error de inicio de sesión: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogin() {
    _login(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState == AuthState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navegar de vuelta a la selección de tipo de usuario
            context.go('/user-type-selection');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del servidor
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 Servidor: http://localhost:3001/api',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🔧 Conexión local para desarrollo',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Campo de email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingresa tu correo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Usuarios de prueba
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👤 Usuarios de Prueba:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🚐 Micrero: carlos.mamani@crucero.bo / password123',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                    ),
                    Text(
                      '🔧 Debug: debug@crucero.bo / password123',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                    ),
                  ],
                ),
              ),

              // Botones de login rápido
              Row(
                children: [
                  // Botón de login rápido para chofer
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : () {
                          // Llenar campos automáticamente
                          _emailController.text = 'marco.chofer@gmail.com';
                          _passwordController.text = '12345678';
                          // Ejecutar login automáticamente
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _handleLogin();
                          });
                        },
                        icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                        label: const Text(
                          '⚡ Chofer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Botón de login rápido para cliente
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 8, bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : () {
                          // Llenar campos automáticamente
                          _emailController.text = 'jose.cliente@gmail.com';
                          _passwordController.text = '12345678';
                          // Ejecutar login automáticamente
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _handleLogin();
                          });
                        },
                        icon: const Icon(Icons.person, color: Colors.white, size: 18),
                        label: const Text(
                          '⚡ Cliente',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Botón de inicio de sesión
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 16),

              // Link a registro
              TextButton(
                onPressed: () {
                  context.push('/register');
                },
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
              
              // Espaciado adicional para evitar overflow
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
