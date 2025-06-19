import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// This function copies an asset file from the asset bundle to the temporary
/// app directory.
///
/// **It is not recommended to use this in production and for larger files.**
/// Instead download your files from a web server or s3 storage.
Future<File> copyAssetToFile(String assetFile) async {
  final tempDir = await getTemporaryDirectory();
  final filename = assetFile.split('/').last;
  final file = File('${tempDir.path}/$filename');

  final data = await rootBundle.load(assetFile);
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return file.absolute;
}

Future<String> leerArchivoAssets(String assetFile) async {
  try {
    String contenido = await rootBundle.loadString(assetFile);
    return contenido;
  } catch (e) {
    print('Error al leer el archivo de assets: $e');
    return ''; // O maneja el error de otra manera
  }
}
Future<String> copyAssetDirectoryToAppDir(String assetPath) async {
  final files = await listAssetFiles(assetPath);
  final appDir = await getTemporaryDirectory(); // o getApplicationSupportDirectory()
  final targetDir = Directory('${appDir.path}/${assetPath.split('/').last}');
  await targetDir.create(recursive: true);

  for (final path in files) {
    final data = await rootBundle.load(path);
    final file = File('${targetDir.path}/${path.split('/').last}');
    await file.writeAsBytes(data.buffer.asUint8List());
  }

  return targetDir.path;
}

Future<List<String>> listAssetFiles(String path) async {
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = json.decode(manifestContent);
  return manifestMap.keys
      .where((String key) => key.startsWith(path))
      .toList();
}

Future<void> copyAssetsToCache(String assetsPath) async {
  try {
    // 1. Obtener directorio de caché
    final cacheDir = await getTemporaryDirectory();
    final targetPath = p.join(cacheDir.path, assetsPath);

    // 2. Leer el manifiesto de assets
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestContent);

    // 3. Filtrar los assets que pertenecen al directorio
    final assetsToCopy = manifest.keys
        .where((key) => key.startsWith('$assetsPath/'))
        .toList();

    // 4. Procesar cada asset
    for (final assetPath in assetsToCopy) {
      // Obtener path relativo
      final relativePath = assetPath.substring(assetsPath.length + 1);
      final fullTargetPath = p.join(targetPath, relativePath);

      // Crear directorios padres si no existen
      final targetFile = File(fullTargetPath);
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      // Copiar el archivo
      final byteData = await rootBundle.load(assetPath);
      await targetFile.writeAsBytes(byteData.buffer.asUint8List());

      print('Copiado: $assetPath → $fullTargetPath');
    }

    print('¡Copia completada! Directorio: $targetPath');
  } catch (e) {
    print('Error durante la copia: $e');
    rethrow;
  }
}