import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/imported_contact.dart';

class ContactImportService {
  static final ContactImportService instance = ContactImportService._();
  ContactImportService._();

  // ==================== IMPORT DEPUIS LE TÉLÉPHONE ====================

  /// Demander la permission d'accès aux contacts
  Future<bool> requestContactsPermission() async {
    if (kIsWeb) return false; // Pas de contacts sur web

    return await FlutterContacts.requestPermission();
  }

  /// Vérifier si la permission est accordée
  Future<bool> hasContactsPermission() async {
    if (kIsWeb) return false;

    // Sur flutter_contacts, requestPermission peut être utilisé pour vérifier le statut
    // sans forcément afficher la popup si on ne demande pas explicitement.
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// Importer les contacts depuis le téléphone
  Future<List<ImportedContact>> importFromPhone() async {
    if (kIsWeb) {
      throw Exception('Import de contacts non disponible sur web');
    }

    // Vérifier et demander la permission
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      throw Exception('Permission d\'accès aux contacts refusée');
    }

    // Récupérer les contacts avec propriétés détaillées
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: false,
    );

    // Convertir en ImportedContact
    final importedContacts = <ImportedContact>[];
    
    for (final contact in contacts) {
      final name = contact.displayName;
      if (name.isEmpty) continue;

      String? phone;
      if (contact.phones.isNotEmpty) {
        phone = contact.phones.first.number;
        // Nettoyer le numéro (enlever espaces, tirets, etc.)
        phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      }

      String? address;
      if (contact.addresses.isNotEmpty) {
        final addr = contact.addresses.first;
        final parts = <String>[];
        if (addr.street.isNotEmpty) parts.add(addr.street);
        if (addr.city.isNotEmpty) parts.add(addr.city);
        if (addr.postalCode.isNotEmpty) parts.add(addr.postalCode);
        address = parts.join(', ');
      }

      importedContacts.add(ImportedContact(
        name: name,
        phone: phone,
        address: address,
      ));
    }

    return importedContacts;
  }

  // ==================== IMPORT DEPUIS CSV ====================

  /// Importer les contacts depuis un fichier CSV
  Future<List<ImportedContact>> importFromCSV() async {
    // Sélectionner le fichier
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('Aucun fichier sélectionné');
    }

    final file = result.files.first;
    String csvContent;

    // Lire le contenu du fichier
    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('Impossible de lire le fichier');
      }
      csvContent = String.fromCharCodes(file.bytes!);
    } else {
      if (file.path == null) {
        throw Exception('Chemin du fichier invalide');
      }
      final ioFile = File(file.path!);
      csvContent = await ioFile.readAsString();
    }

    // Parser le CSV
    return parseCSV(csvContent);
  }

  /// Parser le contenu CSV
  List<ImportedContact> parseCSV(String csvContent) {
    final importedContacts = <ImportedContact>[];

    try {
      // Détecter le séparateur (virgule ou point-virgule)
      final separator = csvContent.contains(';') ? ';' : ',';
      
      final rows = const CsvToListConverter().convert(
        csvContent,
        fieldDelimiter: separator,
        eol: '\n',
      );

      if (rows.isEmpty) {
        throw Exception('Le fichier CSV est vide');
      }

      // Première ligne = en-têtes
      final headers = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
      
      // Trouver les indices des colonnes
      final nameIndex = _findColumnIndex(headers, ['nom', 'name', 'client', 'contact']);
      final phoneIndex = _findColumnIndex(headers, ['téléphone', 'telephone', 'phone', 'tel', 'mobile']);
      final addressIndex = _findColumnIndex(headers, ['adresse', 'address', 'rue', 'street']);

      if (nameIndex == -1) {
        throw Exception('Colonne "nom" non trouvée dans le CSV');
      }

      // Parcourir les lignes de données
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        
        if (row.length <= nameIndex) continue;
        
        final name = row[nameIndex].toString().trim();
        if (name.isEmpty) continue;

        String? phone;
        if (phoneIndex != -1 && row.length > phoneIndex) {
          phone = row[phoneIndex].toString().trim();
          if (phone.isEmpty) phone = null;
          // Nettoyer le numéro
          phone = phone?.replaceAll(RegExp(r'[^\d+]'), '');
        }

        String? address;
        if (addressIndex != -1 && row.length > addressIndex) {
          address = row[addressIndex].toString().trim();
          if (address.isEmpty) address = null;
        }

        importedContacts.add(ImportedContact(
          name: name,
          phone: phone,
          address: address,
        ));
      }

      return importedContacts;
    } catch (e) {
      throw Exception('Erreur lors de la lecture du CSV: ${e.toString()}');
    }
  }

  /// Trouver l'index d'une colonne par ses noms possibles
  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      for (final name in possibleNames) {
        if (header.contains(name)) {
          return i;
        }
      }
    }
    return -1;
  }

  // ==================== EXPORT TEMPLATE CSV ====================

  /// Générer un template CSV pour l'import
  String generateCSVTemplate() {
    return 'Nom,Téléphone,Adresse\n'
        'Jean Dupont,+221 77 123 45 67,123 Rue de la Paix\n'
        'Marie Martin,+221 76 987 65 43,456 Avenue du Commerce\n'
        'Pierre Durand,+221 78 555 12 34,789 Boulevard Central';
  }

  /// Exporter le template CSV
  Future<void> exportCSVTemplate() async {
    final template = generateCSVTemplate();
    
    if (kIsWeb) {
      // Sur web, télécharger le fichier
      // TODO: Implémenter le téléchargement web si nécessaire
      throw Exception('Export template non implémenté sur web');
    } else {
      // Sur mobile, sauvegarder dans les téléchargements
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        throw Exception('Dossier de téléchargement non trouvé');
      }
      
      final file = File('${directory.path}/template_clients.csv');
      await file.writeAsString(template);
    }
  }
}
