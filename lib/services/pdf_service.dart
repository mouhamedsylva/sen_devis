import 'dart:typed_data';
import 'dart:convert' show base64Decode;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../data/database/app_database.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';

// Imports conditionnels pour le web
import 'pdf_service_web.dart' if (dart.library.io) 'pdf_service_io.dart' as platform;

class PdfService {
  static final PdfService instance = PdfService._init();
  PdfService._init();

  // Couleurs du thème
  static final primaryColor = PdfColor.fromHex('#1A7B7B');
  static final accentColor = PdfColor.fromHex('#2D9B9B');
  static final darkColor = PdfColor.fromHex('#1A3B5D');
  static final lightGray = PdfColor.fromHex('#F5F7FA');
  static final borderGray = PdfColor.fromHex('#E2E8F0');

  // Générer le PDF d'un devis
  Future<dynamic> generateQuotePdf({
    required QuoteWithDetails quoteDetails,
    required Company company,
  }) async {
    try {
      final quote = quoteDetails.quote;
      final client = quoteDetails.client;
      final items = quoteDetails.items;
      
      // Charger la signature si elle existe
      pw.MemoryImage? signatureImage;
      if (company.signaturePath != null && company.signaturePath!.isNotEmpty) {
        print('Chargement de la signature depuis: ${company.signaturePath}');
        signatureImage = await _loadSignatureImage(company.signaturePath!);
        if (signatureImage != null) {
          print('Signature chargée avec succès');
        } else {
          print('Échec du chargement de la signature');
        }
      } else {
        print('Aucune signature configurée');
      }
      
      final pdf = pw.Document();

      // Ajouter la page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildHeader(company, quote),
                pw.SizedBox(height: 30),

                // Informations client
                _buildClientInfo(client),
                pw.SizedBox(height: 30),

                // Tableau des articles
                _buildItemsTable(items),
                pw.SizedBox(height: 20),

                // Totaux
                _buildTotals(quote),
                
                pw.Spacer(),

                // Notes
                if (quote.notes != null && quote.notes!.isNotEmpty)
                  _buildNotes(quote.notes!),
                
                // Signature
                if (signatureImage != null)
                  pw.SizedBox(height: 20),
                
                if (signatureImage != null)
                  _buildSignature(signatureImage),
                
                // Pied de page
                _buildFooter(company),
              ],
            );
          },
        ),
      );

      // Sauvegarder le fichier selon la plateforme
      return await _savePdf(pdf, quote.quoteNumber);
    } catch (e) {
      print('Erreur lors de la génération du PDF: $e');
      return null;
    }
  }

  // Charger l'image de signature
  Future<pw.MemoryImage?> _loadSignatureImage(String signaturePath) async {
    try {
      Uint8List? signatureBytes;
      
      if (signaturePath.startsWith('data:image')) {
        // Data URL (web) - extraire et décoder le base64
        final base64String = signaturePath.split(',')[1];
        signatureBytes = base64Decode(base64String);
      } else if (signaturePath.startsWith('http')) {
        // URL réseau
        final response = await http.get(Uri.parse(signaturePath));
        if (response.statusCode == 200) {
          signatureBytes = response.bodyBytes;
        }
      } else {
        // Fichier local - utiliser la fonction de plateforme
        signatureBytes = await platform.readFileBytes(signaturePath);
      }

      if (signatureBytes != null && signatureBytes.isNotEmpty) {
        return pw.MemoryImage(signatureBytes);
      }
    } catch (e) {
      print('Erreur lors du chargement de la signature: $e');
    }
    
    return null;
  }

  // En-tête du document
  pw.Widget _buildHeader(Company company, Quote quote) {
    return pw.Column(
      children: [
        // Bande de couleur en haut
        pw.Container(
          width: double.infinity,
          height: 8,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryColor, accentColor],
            ),
          ),
        ),
        pw.SizedBox(height: 25),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Informations entreprise
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name,
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (company.phone != null)
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          company.phone!,
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  if (company.address != null)
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: pw.Text(
                            company.address!,
                            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Badge DEVIS avec numéro et date
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: primaryColor, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DEVIS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'N° ${quote.quoteNumber}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    DateFormatter.format(quote.quoteDate),
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Informations client
  pw.Widget _buildClientInfo(Client? client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border(
          left: pw.BorderSide(color: primaryColor, width: 4),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Icon(
              pw.IconData(0xe7fd), // person icon
              color: PdfColors.white,
              size: 20,
            ),
          ),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FACTURÉ À',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  client?.name ?? '',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                if (client?.phone != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '📞 ${client!.phone!}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
                if (client?.address != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '📍 ${client!.address!}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tableau des articles
  pw.Widget _buildItemsTable(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: borderGray, width: 1),
        verticalInside: pw.BorderSide(color: borderGray, width: 1),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête avec gradient
        pw.TableRow(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryColor, accentColor],
            ),
          ),
          children: [
            _buildTableCell('Désignation', isHeader: true, textColor: PdfColors.white),
            _buildTableCell('Qté', isHeader: true, alignment: pw.Alignment.center, textColor: PdfColors.white),
            _buildTableCell('Prix Unit.', isHeader: true, alignment: pw.Alignment.centerRight, textColor: PdfColors.white),
            _buildTableCell('TVA', isHeader: true, alignment: pw.Alignment.center, textColor: PdfColors.white),
            _buildTableCell('Total HT', isHeader: true, alignment: pw.Alignment.centerRight, textColor: PdfColors.white),
          ],
        ),
        
        // Articles avec alternance de couleurs
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isEven = index % 2 == 0;
          
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : lightGray,
            ),
            children: [
              _buildTableCell(item.productName),
              _buildTableCell(
                item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                CurrencyFormatter.format(item.unitPrice, showSymbol: false),
                alignment: pw.Alignment.centerRight,
              ),
              _buildTableCell(
                '${item.vatRate.toStringAsFixed(0)}%',
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                CurrencyFormatter.format(item.totalHT, showSymbol: false),
                alignment: pw.Alignment.centerRight,
                isBold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // Cellule de tableau
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.Alignment? alignment,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.white : darkColor),
        ),
      ),
    );
  }

  // Section totaux
  pw.Widget _buildTotals(Quote quote) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 280,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderGray, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Sous-total HT', quote.totalHT, isSubtotal: true),
              pw.Divider(height: 1, color: borderGray),
              _buildTotalRow('TVA', quote.totalVAT, isSubtotal: true),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [primaryColor, accentColor],
                  ),
                  borderRadius: const pw.BorderRadius.only(
                    bottomLeft: pw.Radius.circular(7),
                    bottomRight: pw.Radius.circular(7),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL TTC',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.Text(
                      CurrencyFormatter.format(quote.totalTTC),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Ligne de total
  pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isSubtotal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            CurrencyFormatter.format(amount),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
          ),
        ],
      ),
    );
  }

  // Notes
  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border(
          left: pw.BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Icon(
                  pw.IconData(0xe873), // note icon
                  color: PdfColors.white,
                  size: 12,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Notes & Conditions',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notes,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, lineSpacing: 1.3),
          ),
        ],
      ),
    );
  }

  // Signature
  pw.Widget _buildSignature(pw.MemoryImage signatureImage) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 15),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: primaryColor, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Signature autorisée',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: 160,
                  height: 70,
                  child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pied de page
  pw.Widget _buildFooter(Company company) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            company.name,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: darkColor,
            ),
          ),
          if (company.phone != null) ...[
            pw.SizedBox(width: 15),
            pw.Text(
              '•',
              style: pw.TextStyle(color: primaryColor, fontSize: 10),
            ),
            pw.SizedBox(width: 15),
            pw.Text(
              company.phone!,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
          if (company.address != null) ...[
            pw.SizedBox(width: 15),
            pw.Text(
              '•',
              style: pw.TextStyle(color: primaryColor, fontSize: 10),
            ),
            pw.SizedBox(width: 15),
            pw.Text(
              company.address!,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
  }

  // Sauvegarder le PDF selon la plateforme
  Future<dynamic> _savePdf(pw.Document pdf, String quoteNumber) async {
    final fileName = 'devis_${quoteNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfBytes = await pdf.save();
    
    // Utiliser la fonction de plateforme appropriée
    return await platform.savePdf(pdfBytes, fileName);
  }
}
