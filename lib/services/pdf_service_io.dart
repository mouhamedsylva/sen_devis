// Version mobile/desktop (dart:io)
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Sauvegarder le PDF dans un fichier
Future<File> savePdf(Uint8List pdfBytes, String fileName) async {
  final output = await getTemporaryDirectory();
  final file = File(path.join(output.path, fileName));
  await file.writeAsBytes(pdfBytes);
  return file;
}

// Lire les bytes d'un fichier
Future<Uint8List?> readFileBytes(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (e) {
    print('Erreur lecture fichier: $e');
  }
  return null;
}
