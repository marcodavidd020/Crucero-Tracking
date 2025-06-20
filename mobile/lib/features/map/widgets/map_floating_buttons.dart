import 'package:flutter/material.dart';

class MapFloatingButtons extends StatelessWidget {
  final bool isServiceActive;
  final bool followMicro;
  final VoidCallback onToggleTracking;
  final VoidCallback onCenterOnMicro;

  const MapFloatingButtons({
    super.key,
    required this.isServiceActive,
    required this.followMicro,
    required this.onToggleTracking,
    required this.onCenterOnMicro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón para centrar en el micro
        FloatingActionButton(
          heroTag: "center_micro",
          mini: true,
          backgroundColor: followMicro ? Colors.green : Colors.grey,
          onPressed: onCenterOnMicro,
          child: Icon(
            followMicro ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        
        // Botón principal para iniciar/detener tracking
        FloatingActionButton(
          heroTag: "tracking_toggle",
          backgroundColor: isServiceActive ? Colors.red : Colors.green,
          onPressed: onToggleTracking,
          child: Icon(
            isServiceActive ? Icons.stop : Icons.play_arrow,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 