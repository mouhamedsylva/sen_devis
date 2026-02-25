// Version web (dart:html)
import 'dart:typed_data';

// Sur le web, on retourne simplement les bytes
Future<Uint8List> savePdf(Uint8List pdfBytes, String fileName) async {
  return pdfBytes;
}

// Sur le web, pas de système de fichiers local
Future<Uint8List?> readFileBytes(String filePath) async {
  // Les fichiers locaux n'existent pas sur le web
  return null;
}
