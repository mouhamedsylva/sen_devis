// Version mobile/desktop (dart:io)
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Partager un PDF
Future<bool> sharePdf(
  dynamic pdfData,
  String quoteNumber,
  String subject,
  String message,
) async {
  if (pdfData is File) {
    final xFile = XFile(pdfData.path);
    await Share.shareXFiles(
      [xFile],
      subject: subject,
      text: message,
    );
    return true;
  }
  return false;
}

// Ouvrir un PDF
Future<bool> openPdf(dynamic pdfData) async {
  if (pdfData is File) {
    final uri = Uri.file(pdfData.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
  }
  return false;
}

// Obtenir l'URL SMS selon la plateforme
Future<String> getSmsUrl(String phoneNumber, String message) async {
  return Platform.isIOS
      ? 'sms:$phoneNumber&body=$message'
      : 'sms:$phoneNumber?body=$message';
}
