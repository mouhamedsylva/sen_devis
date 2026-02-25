// Version web (dart:html)
import 'dart:html' as html;
import 'dart:typed_data';

// Partager un PDF (télécharger sur le web)
Future<bool> sharePdf(
  dynamic pdfData,
  String quoteNumber,
  String subject,
  String message,
) async {
  if (pdfData is Uint8List) {
    try {
      final blob = html.Blob([pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'devis_$quoteNumber.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (e) {
      print('Erreur téléchargement web: $e');
      return false;
    }
  }
  return false;
}

// Ouvrir un PDF dans un nouvel onglet
Future<bool> openPdf(dynamic pdfData) async {
  if (pdfData is Uint8List) {
    try {
      final blob = html.Blob([pdfData], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (e) {
      print('Erreur ouverture web: $e');
      return false;
    }
  }
  return false;
}

// URL SMS pour le web
Future<String> getSmsUrl(String phoneNumber, String message) async {
  return 'sms:$phoneNumber?body=$message';
}
