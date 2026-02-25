import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService instance = StorageService._init();
  StorageService._init();

  final ImagePicker _imagePicker = ImagePicker();

  // Obtenir le répertoire de l'application
  Future<Directory> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  // Créer un sous-répertoire
  Future<Directory> createDirectory(String dirName) async {
    final appDir = await getAppDirectory();
    final dir = Directory(path.join(appDir.path, dirName));
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return dir;
  }

  // Sauvegarder un fichier
  Future<String?> saveFile(File file, String dirName, String fileName) async {
    try {
      final dir = await createDirectory(dirName);
      final newPath = path.join(dir.path, fileName);
      final newFile = await file.copy(newPath);
      return newFile.path;
    } catch (e) {
      print('Erreur lors de la sauvegarde du fichier: $e');
      return null;
    }
  }

  // Supprimer un fichier
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression du fichier: $e');
      return false;
    }
  }

  // Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  // Prendre une photo avec la caméra
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  // Sauvegarder le logo de l'entreprise
  Future<String?> saveCompanyLogo(File imageFile) async {
    final fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await saveFile(imageFile, 'logos', fileName);
  }

  // Sélectionner une image depuis la galerie (retourne bytes)
  Future<Uint8List?> pickImageFromGalleryAsBytes() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  // Prendre une photo avec la caméra (retourne bytes)
  Future<Uint8List?> takePhotoAsBytes() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  // Sauvegarder le logo de l'entreprise depuis bytes
  Future<String?> saveCompanyLogoFromBytes(Uint8List bytes) async {
    try {
      if (kIsWeb) {
        // Sur le web, on retourne une data URL
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else {
        // Sur mobile, on sauvegarde dans un fichier
        final dir = await createDirectory('logos');
        final fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde du logo: $e');
      return null;
    }
  }

  // Sauvegarder la signature de l'entreprise depuis bytes
  Future<String?> saveCompanySignatureFromBytes(Uint8List bytes) async {
    try {
      if (kIsWeb) {
        // Sur le web, on retourne une data URL
        return 'data:image/png;base64,${base64Encode(bytes)}';
      } else {
        // Sur mobile, on sauvegarde dans un fichier
        final dir = await createDirectory('signatures');
        final fileName = 'company_signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = path.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde de la signature: $e');
      return null;
    }
  }

  // Obtenir la taille d'un fichier
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  // Vérifier si un fichier existe
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}