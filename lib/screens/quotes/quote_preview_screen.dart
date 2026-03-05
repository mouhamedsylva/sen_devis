import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../providers/quote_provider.dart';
import '../../providers/company_provider.dart';
import '../../core/utils/mobile_utils.dart';
import '../../data/database/app_database.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../widgets/loading_indicator.dart';

class QuotePreviewScreen extends StatefulWidget {
  static const String routeName = '/quote-preview';
  const QuotePreviewScreen({Key? key}) : super(key: key);

  @override
  State<QuotePreviewScreen> createState() => _QuotePreviewScreenState();
}

class _QuotePreviewScreenState extends State<QuotePreviewScreen> {
  int? _quoteId;
  QuoteWithDetails? _quoteDetails;
  Company? _company;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  bool _dataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _quoteId = args?['quoteId'];
      print('📱 Arguments reçus - quoteId: $_quoteId');
      if (_quoteId != null) {
        _dataLoaded = true;
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    print('🔍 Chargement du devis ID: $_quoteId');
    final quoteDetails = await context.read<QuoteProvider>().loadQuoteWithItems(_quoteId!);
    final company = context.read<CompanyProvider>().company;
    
    print('📄 Devis chargé: ${quoteDetails != null ? "OUI" : "NON"}');
    print('🏢 Entreprise: ${company != null ? "OUI" : "NON"}');
    
    setState(() {
      _quoteDetails = quoteDetails;
      _company = company;
      _isLoading = false;
    });
    
    if (quoteDetails == null) {
      print('❌ ERREUR: Le devis $_quoteId n\'a pas été trouvé');
    }
    if (company == null) {
      print('❌ ERREUR: L\'entreprise n\'est pas configurée');
    }
  }

  Future<void> _sharePdf() async {
    if (_quoteDetails == null || _company == null) return;
    
    MobileUtils.mediumHaptic();
    setState(() => _isGeneratingPdf = true);

    final pdfData = await PdfService.instance.generateQuotePdf(
      quoteDetails: _quoteDetails!,
      company: _company!,
    );

    setState(() => _isGeneratingPdf = false);

    if (pdfData != null && mounted) {
      ShareService.instance.sharePdf(pdfData, _quoteDetails!.quote.quoteNumber);
    } else if (mounted) {
      MobileUtils.showMobileSnackBar(
        context,
        message: 'Erreur lors de la génération du PDF',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_quoteDetails == null || _company == null) return;
    
    MobileUtils.mediumHaptic();
    setState(() => _isGeneratingPdf = true);

    final pdfData = await PdfService.instance.generateQuotePdf(
      quoteDetails: _quoteDetails!,
      company: _company!,
    );

    setState(() => _isGeneratingPdf = false);

    if (pdfData != null && mounted) {
      ShareService.instance.openPdf(pdfData);
    } else if (mounted) {
      MobileUtils.showMobileSnackBar(
        context,
        message: 'Erreur lors de la génération du PDF',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0D7C7E);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_quoteDetails == null || _company == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_company == null ? 'Configuration requise' : 'Devis'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _company == null ? Icons.business_outlined : Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _company == null 
                      ? 'Entreprise non configurée'
                      : 'Devis introuvable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _company == null
                      ? 'Veuillez configurer les informations de votre entreprise pour générer des devis PDF.'
                      : 'Ce devis n\'existe plus ou a été supprimé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                if (_company == null) ...[
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      MobileUtils.mediumHaptic();
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(
                        '/company-settings',
                        arguments: {
                          'isFirstSetup': true,
                        },
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text(
                      'Configurer mon entreprise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7C7E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: primaryColor,
            size: 20,
          ),
          onPressed: () {
            MobileUtils.lightHaptic();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Devis ${_quoteDetails!.quote.quoteNumber}',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              icon: Icon(Icons.share, color: primaryColor, size: 22),
              onPressed: _sharePdf,
              tooltip: 'Partager',
            ),
            IconButton(
              icon: Icon(Icons.download, color: primaryColor, size: 22),
              onPressed: _exportPdf,
              tooltip: 'Exporter',
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final pdfDoc = await PdfService.instance.generateQuotePdfDocument(
            quoteDetails: _quoteDetails!,
            company: _company!,
          );
          return pdfDoc.save();
        },
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfFileName: '${_quoteDetails!.quote.quoteNumber}.pdf',
        loadingWidget: const Center(child: LoadingIndicator()),
        scrollViewDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        ),
      ),
    );
  }
}
