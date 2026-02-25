import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/company_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/models/model_extensions.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../widgets/loading_indicator.dart';
import 'quote_form_screen.dart';

class QuotePreviewScreen extends StatefulWidget {
  static const String routeName = '/quote-preview';

  const QuotePreviewScreen({Key? key}) : super(key: key);

  @override
  State<QuotePreviewScreen> createState() => _QuotePreviewScreenState();
}

class _QuotePreviewScreenState extends State<QuotePreviewScreen> {
  int? _quoteId;
  QuoteWithDetails? _quoteDetails;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _quoteId = args?['quoteId'];
    
    if (_quoteId != null) {
      _loadQuote();
    }
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
    });

    final quoteDetails = await context.read<QuoteProvider>().loadQuoteWithItems(_quoteId!);
    
    setState(() {
      _quoteDetails = quoteDetails;
      _isLoading = false;
    });
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_quoteDetails == null) return;

    final success = await context.read<QuoteProvider>().updateQuoteStatus(
      _quoteDetails!.quote.id,
      newStatus,
    );

    if (success) {
      await _loadQuote();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _generateAndSharePDF() async {
    if (_quoteDetails == null) return;

    final company = context.read<CompanyProvider>().company;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez configurer votre entreprise'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingIndicator()),
    );

    final pdfData = await PdfService.instance.generateQuotePdf(
      quoteDetails: _quoteDetails!,
      company: company,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // Fermer le dialogue de chargement

    if (pdfData != null) {
      // Options de partage
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(context);
                  ShareService.instance.sharePdf(pdfData, _quoteDetails!.quote.quoteNumber);
                },
              ),
              if (_quoteDetails!.client?.phone != null)
                ListTile(
                  leading: Icon(Icons.chat, color: Colors.green),
                  title: const Text('WhatsApp'),
                  onTap: () {
                    Navigator.pop(context);
                    ShareService.instance.shareViaWhatsApp(
                      pdfData: pdfData,
                      quoteNumber: _quoteDetails!.quote.quoteNumber,
                      phoneNumber: _quoteDetails!.client?.phone,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Ouvrir'),
                onTap: () {
                  Navigator.pop(context);
                  ShareService.instance.openPdf(pdfData);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la génération du PDF'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (_quoteDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Devis')),
        body: const Center(
          child: Text('Devis introuvable'),
        ),
      );
    }

    final quote = _quoteDetails!.quote;
    Color statusColor;
    switch (quote.status) {
      case 'draft':
        statusColor = AppColors.statusDraft;
        break;
      case 'sent':
        statusColor = AppColors.statusSent;
        break;
      case 'accepted':
        statusColor = AppColors.statusAccepted;
        break;
      default:
        statusColor = AppColors.statusDraft;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quote.quoteNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                QuoteFormScreen.routeName,
                arguments: {'quoteId': quote.id},
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (quote.status != 'sent')
                PopupMenuItem(
                  value: 'mark_sent',
                  child: const Text('Marquer comme envoyé'),
                ),
              if (quote.status != 'accepted')
                PopupMenuItem(
                  value: 'mark_accepted',
                  child: const Text('Marquer comme accepté'),
                ),
              if (quote.status != 'draft')
                PopupMenuItem(
                  value: 'mark_draft',
                  child: const Text('Marquer comme brouillon'),
                ),
            ],
            onSelected: (value) {
              if (value == 'mark_sent') {
                _changeStatus('sent');
              } else if (value == 'mark_accepted') {
                _changeStatus('accepted');
              } else if (value == 'mark_draft') {
                _changeStatus('draft');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getStatusIcon(_quoteDetails!.quote.status), color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    _quoteDetails!.quote.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Informations client
            _buildSection(
              'Client',
              [
                _buildInfoRow(Icons.person, _quoteDetails!.client?.name ?? 'Inconnu'),
                if (_quoteDetails!.client?.phone != null)
                  _buildInfoRow(Icons.phone, _quoteDetails!.client!.phone!),
                if (_quoteDetails!.client?.address != null)
                  _buildInfoRow(Icons.location_on, _quoteDetails!.client!.address!),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date: ${DateFormatter.format(_quoteDetails!.quote.quoteDate)}',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Articles
            _buildSection(
              'Articles',
              _quoteDetails!.items?.map((item) => _buildItemRow(item)).toList() ?? [],
            ),
            const SizedBox(height: 24),

            // Totaux
            _buildTotalsSection(),
            
            // Notes
            if (_quoteDetails!.quote.notes != null && _quoteDetails!.quote.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Notes',
                [
                  Text(_quoteDetails!.quote.notes!),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generateAndSharePDF,
                  icon: const Icon(Icons.share),
                  label: const Text(AppStrings.share),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateAndSharePDF,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'accepted':
        return Icons.check_circle;
      default:
        return Icons.edit;
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildItemRow(item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemBg = isDark ? const Color(0xFF1E1E1E) : AppColors.background;
    final borderClr = isDark ? Colors.grey.shade800 : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(item.totalHT),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'TVA ${item.vatRate}%: ${CurrencyFormatter.format(item.totalVAT)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTotalRow('Total HT', _quoteDetails!.quote.totalHT),
            const SizedBox(height: 8),
            _buildTotalRow('TVA', _quoteDetails!.quote.totalVAT),
            const Divider(height: 24),
            _buildTotalRow('Total TTC', _quoteDetails!.quote.totalTTC, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}
