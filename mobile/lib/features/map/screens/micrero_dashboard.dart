import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/rutas_disponibles_section.dart';
import '../widgets/dashboard_actions_grid.dart';
import '../widgets/dashboard_logout_button.dart';
import '../../../common/widgets/app_drawer.dart';

class MicreroDashboard extends ConsumerWidget {
  const MicreroDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Micrero'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange,
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: const SafeArea(
          child: Column(
            children: [
              // Header con información del micrero
              DashboardHeader(),

              // Sección de rutas disponibles
              RutasDisponiblesSection(),

              // Opciones principales
              DashboardActionsGrid(),

              // Botón de logout que SÍ funciona
              DashboardLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

} 