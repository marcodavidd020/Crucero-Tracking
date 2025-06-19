import 'package:app_map_tracking/services/tracking_socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trackingServiceProvider = Provider<TrackingSocketService>((ref) {
  return TrackingSocketService();
});