import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/map_service.dart';

// Provider simple para crear MapService
final mapServiceProvider = Provider<MapService Function(WidgetRef)>((ref) {
  return (widgetRef) => MapService(widgetRef);
}); 