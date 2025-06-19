import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_map_tracking/common/shared_preference_helper.dart';

final entidadIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  return await SharedPreferenceHelper().getSelectedEntidad();
});
