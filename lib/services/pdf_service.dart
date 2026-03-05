/// Service PDF — Design PREMIUM Teal + Sable
/// Palette : Teal #1A7B7B + Sable chaud #C8956A + Blanc ivoire + Ardoise
import 'dart:typed_data';
import 'dart:convert' show base64Decode;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../data/database/app_database.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import 'pdf_service_web.dart' if (dart.library.io) 'pdf_service_io.dart' as platform;

class PdfService {
  static final PdfService instance = PdfService._init();
  PdfService._init();

  // ─── Palette Teal + Sable ─────────────────────────────────────────────────
  static final _teal        = PdfColor.fromHex('#1A7B7B'); // Teal principal
  static final _tealDark    = PdfColor.fromHex('#0F5252'); // Teal sombre (header)
  static final _tealMid     = PdfColor.fromHex('#2D9B9B'); // Teal médium
  static final _tealFaint   = PdfColor.fromHex('#EAF5F5'); // Teal très clair
  static final _sand        = PdfColor.fromHex('#C8956A'); // Sable/terre cuite
  static final _sandLight   = PdfColor.fromHex('#EDD9C4'); // Sable clair
  static final _ink         = PdfColor.fromHex('#0D1F1F'); // Quasi-noir tealé
  static final _white       = PdfColors.white;
  static final _ivory       = PdfColor.fromHex('#FAFAF8'); // Blanc ivoire
  static final _smoke       = PdfColor.fromHex('#F3F7F7'); // Fumée tealée
  static final _slate       = PdfColor.fromHex('#7A9494'); // Ardoise tealée
  static final _charcoal    = PdfColor.fromHex('#2C4444'); // Gris-teal foncé
  static final _divider     = PdfColor.fromHex('#D8E8E8'); // Séparateur doux

  // ─── API publique ─────────────────────────────────────────────────────────

  Future<pw.Document> generateQuotePdfDocument({
    required QuoteWithDetails quoteDetails,
    required Company company,
  }) async {
    final quote  = quoteDetails.quote;
    final client = quoteDetails.client;
    final items  = quoteDetails.items ?? [];

    final images = await Future.wait([
      _loadImage(company.logoPath),
      _loadImage(company.signaturePath),
    ]);
    final logoImage      = images[0];
    final signatureImage = images[1];

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Stack(
          children: [
            // Fond ivoire
            pw.Positioned.fill(child: pw.Container(color: _ivory)),
            // Bande latérale sable (gauche)
            pw.Positioned(
              left: 0, top: 0, bottom: 0,
              child: pw.Container(width: 5, color: _sand),
            ),
            // Contenu
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(32, 0, 32, 28),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(company, quote, logoImage),
                  pw.SizedBox(height: 22),
                  _buildClientDateRow(client, quote),
                  pw.SizedBox(height: 22),
                  _buildItemsTable(items),
                  pw.SizedBox(height: 18),
                  _buildBottomSection(quote, company, signatureImage),
                  pw.Spacer(),
                  if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                    _buildNotes(quote.notes!),
                    pw.SizedBox(height: 12),
                  ],
                  _buildFooter(company, quote),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  Future<dynamic> generateQuotePdf({
    required QuoteWithDetails quoteDetails,
    required Company company,
  }) async {
    try {
      final pdf = await generateQuotePdfDocument(
        quoteDetails: quoteDetails,
        company: company,
      );
      return await _savePdf(pdf, quoteDetails.quote.quoteNumber);
    } catch (e) {
      print('Erreur génération PDF: $e');
      return null;
    }
  }

  // ─── 1. HEADER ────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(Company company, Quote quote, pw.MemoryImage? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.fromLTRB(-32, 0, -32, 0),
      padding: const pw.EdgeInsets.fromLTRB(37, 26, 32, 26),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_tealDark, _teal],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [

          // ── Identité entreprise
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo ou initiale
              if (logo != null)
                pw.Container(
                  width: 60, height: 60,
                  decoration: pw.BoxDecoration(
                    color: _white,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                pw.Container(
                  width: 60, height: 60,
                  decoration: pw.BoxDecoration(
                    color: _sand,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      company.name.isNotEmpty ? company.name[0].toUpperCase() : 'E',
                      style: pw.TextStyle(
                        fontSize: 28, fontWeight: pw.FontWeight.bold, color: _white,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(width: 16),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold,
                      color: _white, letterSpacing: 2.0,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(width: 36, height: 1.5, color: _sand),
                  pw.SizedBox(height: 5),
                  if (company.phone != null)
                    pw.Text(company.phone!,
                      style: pw.TextStyle(fontSize: 8.5, color: _sandLight)),
                  if (company.address != null)
                    pw.Text(company.address!,
                      style: pw.TextStyle(fontSize: 8.5, color: _tealFaint)),
                ],
              ),
            ],
          ),

          // ── Badge DEVIS + numéro
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'DEVIS',
                style: pw.TextStyle(
                  fontSize: 38, fontWeight: pw.FontWeight.bold,
                  color: _white, letterSpacing: 6,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _sand,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  quote.quoteNumber,
                  style: pw.TextStyle(
                    fontSize: 9.5, fontWeight: pw.FontWeight.bold,
                    color: _white, letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. CLIENT + DATES ────────────────────────────────────────────────────

  pw.Widget _buildClientDateRow(Client? client, Quote quote) {
    final validUntil = quote.quoteDate.add(const Duration(days: 30));
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: _card(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionLabel('ADRESSÉ À'),
                pw.SizedBox(height: 8),
                pw.Text(
                  (client?.name ?? '').toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink,
                  ),
                ),
                if (client?.phone != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(client!.phone!,
                    style: pw.TextStyle(fontSize: 9, color: _slate)),
                ],
                if (client?.address != null)
                  pw.Text(client!.address!,
                    style: pw.TextStyle(fontSize: 9, color: _slate)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          flex: 2,
          child: _card(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionLabel('INFORMATIONS'),
                pw.SizedBox(height: 8),
                _infoLine('Date d\'émission', DateFormatter.format(quote.quoteDate)),
                pw.SizedBox(height: 7),
                pw.Container(height: 0.5, color: _divider),
                pw.SizedBox(height: 7),
                _infoLine('Valide jusqu\'au', DateFormatter.format(validUntil)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 3. TABLEAU ───────────────────────────────────────────────────────────

  pw.Widget _buildItemsTable(List<QuoteItem> items) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _divider, width: 0.8),
        color: _white,
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(3.8),
          1: pw.FlexColumnWidth(0.8),
          2: pw.FlexColumnWidth(1.3),
          3: pw.FlexColumnWidth(0.8),
          4: pw.FlexColumnWidth(1.4),
        },
        children: [
          // En-tête teal dégradé
          pw.TableRow(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [_tealDark, _teal]),
            ),
            children: [
              _th('DÉSIGNATION'),
              _th('QTÉ', align: pw.TextAlign.center),
              _th('P.U. HT', align: pw.TextAlign.right),
              _th('TVA', align: pw.TextAlign.center),
              _th('TOTAL HT', align: pw.TextAlign.right),
            ],
          ),
          // Lignes articles
          ...items.asMap().entries.map((e) {
            final item   = e.value;
            final isLast = e.key == items.length - 1;
            final isEven = e.key % 2 == 0;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isEven ? _white : _smoke,
                border: !isLast
                    ? pw.Border(bottom: pw.BorderSide(color: _divider, width: 0.5))
                    : null,
              ),
              children: [
                _tdDesignation(item.productName),
                _td(item.quantity.toStringAsFixed(
                  item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                  align: pw.TextAlign.center),
                _td(CurrencyFormatter.format(item.unitPrice, showSymbol: false),
                  align: pw.TextAlign.right),
                _tdBadge('${item.vatRate.toStringAsFixed(0)}%'),
                _td(CurrencyFormatter.format(item.totalHT, showSymbol: false),
                  align: pw.TextAlign.right, bold: true, color: _teal),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── 4. SIGNATURE + TOTAUX ────────────────────────────────────────────────

  pw.Widget _buildBottomSection(Quote quote, Company company, pw.MemoryImage? sig) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        // ── Bloc signature complet
        pw.Expanded(
          child: _card(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _sectionLabel('SIGNATURE & CACHET'),
                pw.SizedBox(height: 12),

                // Zone signature
                pw.Container(
                  height: 95,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    color: sig != null ? _white : _tealFaint,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: sig != null ? _divider : _teal,
                      width: sig != null ? 0.8 : 1.2,
                    ),
                  ),
                  child: sig != null
                      ? pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Image(sig, fit: pw.BoxFit.contain),
                        )
                      : pw.Center(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Container(width: 40, height: 0.8, color: _slate),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Signature',
                                style: pw.TextStyle(fontSize: 9, color: _slate),
                              ),
                            ],
                          ),
                        ),
                ),

                pw.SizedBox(height: 10),

                // Ligne de date de signature
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: pw.BoxDecoration(
                    color: _smoke,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Fait à : _______________',
                        style: pw.TextStyle(fontSize: 8, color: _slate),
                      ),
                      pw.Text(
                        'Le : _______________',
                        style: pw.TextStyle(fontSize: 8, color: _slate),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // Mention légale
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: _sand, width: 2.5),
                    ),
                  ),
                  child: pw.Text(
                    'Bon pour accord — Signature précédée\nde la mention manuscrite « Lu et approuvé »',
                    style: pw.TextStyle(
                      fontSize: 7.5, color: _slate, lineSpacing: 1.5,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(width: 16),

        // ── Récapitulatif financier
        pw.Expanded(
          child: pw.Column(
            children: [
              // HT + TVA
              _card(
                child: pw.Column(
                  children: [
                    _summaryLine('Sous-total HT',
                      CurrencyFormatter.format(quote.totalHT)),
                    pw.SizedBox(height: 6),
                    pw.Container(height: 0.5, color: _divider),
                    pw.SizedBox(height: 6),
                    _summaryLine('TVA',
                      CurrencyFormatter.format(quote.totalVAT)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // NET À PAYER — card teal premium
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [_tealDark, _teal],
                    begin: pw.Alignment.centerLeft,
                    end: pw.Alignment.centerRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'NET À PAYER',
                      style: pw.TextStyle(
                        fontSize: 8, color: _sandLight,
                        letterSpacing: 1.5, fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TTC',
                          style: pw.TextStyle(fontSize: 9, color: _tealFaint)),
                        pw.Text(
                          CurrencyFormatter.format(quote.totalTTC),
                          style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold, color: _white,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 7),
                    // Ligne sable décorative
                    pw.Container(height: 1.5, color: _sand),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Acompte attendu (conditionnel)
              if (quote.depositRequired)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: _sandLight,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _sand.shade(0.4), width: 0.8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            quote.depositType == 'percentage'
                                ? 'ACOMPTE (${quote.depositPercentage.toStringAsFixed(0)}%)'
                                : 'ACOMPTE',
                            style: pw.TextStyle(
                              fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                              color: _charcoal, letterSpacing: 0.8,
                            ),
                          ),
                          pw.Text('À la commande',
                            style: pw.TextStyle(fontSize: 7, color: _slate)),
                        ],
                      ),
                      pw.Text(
                        CurrencyFormatter.format(
                          quote.depositType == 'percentage'
                              ? quote.totalTTC * (quote.depositPercentage / 100)
                              : quote.depositAmount
                        ),
                        style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold, color: _charcoal,
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

  // ─── 5. NOTES ─────────────────────────────────────────────────────────────

  pw.Widget _buildNotes(String notes) {
    return _card(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3, height: 50,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_sand, _sandLight],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NOTES & CONDITIONS',
                  style: pw.TextStyle(
                    fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                    color: _charcoal, letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(notes,
                  style: pw.TextStyle(fontSize: 8.5, color: _slate, lineSpacing: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. FOOTER ────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(Company company, Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_tealDark, _teal],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              _footerCondition('Validité', '${quote.validityDays} jours'),
              pw.Container(width: 0.5, height: 28, color: _tealMid),
              _footerCondition('Acompte', quote.depositRequired 
                  ? (quote.depositType == 'percentage'
                      ? '${quote.depositPercentage.toStringAsFixed(0)}% à la commande'
                      : '${CurrencyFormatter.format(quote.depositAmount)} à la commande')
                  : 'Paiement comptant'),
              pw.Container(width: 0.5, height: 28, color: _tealMid),
              _footerCondition('Délai livraison', quote.deliveryDelay ?? 'À définir'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(height: 0.8, color: _sand.shade(0.5)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    company.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold,
                      color: _white, letterSpacing: 1.5,
                    ),
                  ),
                  if (company.address != null)
                    pw.Text(company.address!,
                      style: pw.TextStyle(fontSize: 7.5, color: _tealFaint)),
                ],
              ),
              if (company.phone != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: _sand,
                    borderRadius: pw.BorderRadius.circular(16),
                  ),
                  child: pw.Text(
                    company.phone!,
                    style: pw.TextStyle(
                      fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────

  pw.Widget _card({required pw.Widget child}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _divider, width: 0.8),
      ),
      child: child,
    );
  }

  pw.Widget _sectionLabel(String text) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 12, color: _sand),
        pw.SizedBox(width: 6),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 7.5, fontWeight: pw.FontWeight.bold,
            color: _charcoal, letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  pw.Widget _infoLine(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
          style: pw.TextStyle(fontSize: 7, color: _slate, letterSpacing: 0.8)),
        pw.SizedBox(height: 2),
        pw.Text(value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
      ],
    );
  }

  pw.Widget _summaryLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _slate)),
        pw.Text(value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _charcoal)),
      ],
    );
  }

  pw.Widget _th(String label, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: pw.Text(
        label, textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5, fontWeight: pw.FontWeight.bold,
          color: _sandLight, letterSpacing: 1.0,
        ),
      ),
    );
  }

  pw.Widget _tdDesignation(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: pw.Text(value,
        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink)),
    );
  }

  pw.Widget _td(String value, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: pw.Text(
        value, textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _charcoal,
        ),
      ),
    );
  }

  pw.Widget _tdBadge(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: _tealFaint,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Text(
            value, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8, fontWeight: pw.FontWeight.bold, color: _teal,
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _footerCondition(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(label,
            style: pw.TextStyle(fontSize: 7, color: _tealFaint, letterSpacing: 0.8)),
          pw.SizedBox(height: 2),
          pw.Text(value,
            style: pw.TextStyle(
              fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _sandLight,
            )),
        ],
      ),
    );
  }

  // ─── Utilitaires ──────────────────────────────────────────────────────────

  Future<pw.MemoryImage?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      Uint8List? bytes;
      if (path.startsWith('data:image')) {
        bytes = base64Decode(path.split(',')[1]);
      } else if (path.startsWith('http')) {
        final res = await http.get(Uri.parse(path));
        if (res.statusCode == 200) bytes = res.bodyBytes;
      } else {
        bytes = await platform.readFileBytes(path);
      }
      if (bytes != null && bytes.isNotEmpty) return pw.MemoryImage(bytes);
    } catch (e) {
      print('Erreur chargement image PDF: $e');
    }
    return null;
  }

  Future<dynamic> _savePdf(pw.Document pdf, String quoteNumber) async {
    final name = 'devis_${quoteNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await pdf.save();
    return await platform.savePdf(bytes, name);
  }
}