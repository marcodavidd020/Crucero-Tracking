import 'package:flutter/material.dart';

class MapStatusIndicator extends StatelessWidget {
  final bool isServiceActive;
  final bool followMicro;

  const MapStatusIndicator({
    super.key,
    required this.isServiceActive,
    required this.followMicro,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isServiceActive ? Colors.green.withOpacity(0.9) : Colors.grey.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isServiceActive ? Icons.location_on : Icons.location_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isServiceActive 
                  ? (followMicro ? '🚌 Siguiendo micro en tiempo real' : '🚌 Tracking activo (seguimiento manual)')
                  : '⏸️ Tracking detenido',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (followMicro && isServiceActive) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 