// import 'package:isar/isar.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:app_map_tracking/data/models/ruta_model.dart';
// import 'package:app_map_tracking/data/models/entidad_model.dart';
// import 'package:app_map_tracking/features/auth/models/user_model.dart';
//
// final isarProvider = FutureProvider<Isar>((ref) async {
//   final dir = await getApplicationDocumentsDirectory();
//   return await Isar.open(
//     [RutaModelSchema, EntidadModelSchema, UsuarioSchema],
//     directory: dir.path,
//     inspector: true,
//   );
// });
