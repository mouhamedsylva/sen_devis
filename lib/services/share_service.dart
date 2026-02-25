import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';

// Import conditionnel pour les fonctions de plateforme
import 'share_service_web.dart' if (dart.library.io) 'share_service_io.dart' as platform;

class ShareService {
  static final ShareService instance = ShareService._init();
  ShareService._init();

  // Partager un fichier PDF (accepte File ou Uint8List)
  Future<bool> sharePdf(dynamic pdfData, String quoteNumber) async {
    try {
      return await platform.sharePdf(
        pdfData,
        quoteNumber,
        '${AppConstants.shareSubject}$quoteNumber',
        AppConstants.shareMessage,
      );
    } catch (e) {
      print('Erreur lors du partage: $e');
      return false;
    }
  }

  // Partager via WhatsApp
  Future<bool> shareViaWhatsApp({
    required dynamic pdfData,
    required String quoteNumber,
    String? phoneNumber,
  }) async {
    try {
      // Si un numéro est fourni, ouvrir directement une conversation
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        final message = Uri.encodeComponent(
          '${AppConstants.shareSubject}$quoteNumber\n${AppConstants.shareMessage}',
        );
        
        final whatsappUrl = 'whatsapp://send?phone=$cleanPhone&text=$message';
        final uri = Uri.parse(whatsappUrl);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          // Note: Le fichier ne peut pas être envoyé directement via URL
          // L'utilisateur devra l'attacher manuellement après avoir ouvert WhatsApp
          return true;
        }
      }
      
      // Sinon, partager normalement (l'utilisateur choisira le contact)
      return await sharePdf(pdfData, quoteNumber);
    } catch (e) {
      print('Erreur lors du partage WhatsApp: $e');
      return false;
    }
  }

  // Partager par SMS
  Future<bool> shareBySMS({
    required String quoteNumber,
    required String phoneNumber,
  }) async {
    try {
      final message = Uri.encodeComponent(
        '${AppConstants.shareSubject}$quoteNumber\n${AppConstants.shareMessage}',
      );
      
      final smsUrl = await platform.getSmsUrl(phoneNumber, message);
      final uri = Uri.parse(smsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de l\'envoi SMS: $e');
      return false;
    }
  }

  // Partager par email
  Future<bool> shareByEmail({
    required dynamic pdfData,
    required String quoteNumber,
    String? emailAddress,
  }) async {
    try {
      final subject = Uri.encodeComponent('${AppConstants.shareSubject}$quoteNumber');
      final body = Uri.encodeComponent(AppConstants.shareMessage);
      final emailUrl = 'mailto:${emailAddress ?? ''}?subject=$subject&body=$body';
      
      final uri = Uri.parse(emailUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // Note: Le fichier PDF ne peut pas être attaché automatiquement via mailto
        // Utiliser Share.shareXFiles à la place si disponible
        return true;
      }
      
      return await sharePdf(pdfData, quoteNumber);
    } catch (e) {
      print('Erreur lors de l\'envoi email: $e');
      return false;
    }
  }

  // Ouvrir le fichier PDF
  Future<bool> openPdf(dynamic pdfData) async {
    try {
      return await platform.openPdf(pdfData);
    } catch (e) {
      print('Erreur lors de l\'ouverture du PDF: $e');
      return false;
    }
  }
}