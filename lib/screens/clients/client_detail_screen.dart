import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/mobile_utils.dart';
import '../../data/database/app_database.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/utils/currency_formatter.dart';
import 'client_form_screen.dart';
import '../quotes/quote_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  static const String routeName = '/client-detail';

  const ClientDetailScreen({Key? key}) : super(key: key);

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  Client? _client;
  List<Quote> _quotes = [];
  bool _loadingQuotes = true;
  int? _clientId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _clientId = args?['clientId'];
    if (_clientId != null) {
      _client = context.read<ClientProvider>().getClientById(_clientId!);
      _loadQuotes();
    }
  }

  Future<void> _loadQuotes() async {
    if (_clientId == null) return;
    setState(() => _loadingQuotes = true);
    final quotes = await context.read<ClientProvider>().getClientQuotes(_clientId!);
    if (mounted) {
      setState(() {
        _quotes = quotes;
        _loadingQuotes = false;
      });
    }
  }

  Future<void> _deleteClient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le client'),
        content: const Text('Cette action est irréversible. Confirmer la suppression ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ClientProvider>().deleteClient(_clientId!);
      if (!mounted) return;
      if (success) {
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Client supprimé avec succès',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
        Navigator.of(context).pop();
      } else {
        final error = context.read<ClientProvider>().errorMessage;
        MobileUtils.showMobileSnackBar(
          context,
          message: error ?? 'Erreur lors de la suppression',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final scaffoldBg = isDark ? th.scaffoldBackgroundColor : const Color(0xFFF6F8F8);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1A1A);

    if (_client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche client')),
        body: const Center(child: Text('Client introuvable')),
      );
    }

    // Avatar
    final nameParts = _client!.name.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : _client!.name.substring(0, _client!.name.length >= 2 ? 2 : 1).toUpperCase();

    final colors = [
      const Color(0xFF1A7B7B),
      const Color(0xFF2E7D32),
      const Color(0xFF1976D2),
      const Color(0xFF7B1FA2),
      const Color(0xFFC62828),
      const Color(0xFFEF6C00),
    ];
    final colorIndex = (initials.codeUnitAt(0) + (initials.length > 1 ? initials.codeUnitAt(1) : 0)) % colors.length;
    final avatarColor = colors[colorIndex];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 20),
          onPressed: () {
            MobileUtils.lightHaptic();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Fiche client',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Bouton Modifier
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () {
              MobileUtils.lightHaptic();
              Navigator.of(context)
                  .pushNamed(ClientFormScreen.routeName, arguments: {'clientId': _clientId})
                  .then((_) {
                // Recharger le client si modifié
                if (mounted) {
                  setState(() {
                    _client = context.read<ClientProvider>().getClientById(_clientId!);
                  });
                }
              });
            },
            tooltip: 'Modifier',
          ),
          // Bouton Supprimer
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteClient,
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQuotes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── En-tête avatar + infos ──
              Container(
                color: cardBg,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: avatarColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: avatarColor.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _client!.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_quotes.length} devis',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Coordonnées ──
              _buildSection(
                title: 'COORDONNÉES',
                cardBg: cardBg,
                children: [
                  if (_client!.phone != null && _client!.phone!.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, 'Téléphone', _client!.phone!, isDark),
                  if (_client!.email != null && _client!.email!.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, 'Email', _client!.email!, isDark),
                  if (_client!.address != null && _client!.address!.isNotEmpty)
                    _buildInfoRow(Icons.location_on_outlined, 'Adresse', _client!.address!, isDark),
                  if ((_client!.phone == null || _client!.phone!.isEmpty) &&
                      (_client!.email == null || _client!.email!.isEmpty) &&
                      (_client!.address == null || _client!.address!.isEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Aucune coordonnée renseignée',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Devis associés ──
              _buildSection(
                title: 'DEVIS ASSOCIÉS',
                cardBg: cardBg,
                trailing: _quotes.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_quotes.length}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                children: [
                  if (_loadingQuotes)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: LoadingIndicator()),
                    )
                  else if (_quotes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun devis pour ce client',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._quotes.map((quote) => _buildQuoteRow(quote, isDark)).toList(),
                ],
              ),

              const SizedBox(height: 16),

              // ── Bouton Nouveau devis ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    MobileUtils.lightHaptic();
                    Navigator.of(context).pushNamed(
                      QuoteFormScreen.routeName,
                      arguments: {'preselectedClientId': _clientId},
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Créer un devis pour ce client',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color cardBg,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteRow(Quote quote, bool isDark) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (quote.status) {
      case 'sent':
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'ENVOYÉ';
        statusIcon = Icons.send_outlined;
        break;
      case 'accepted':
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'ACCEPTÉ';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = const Color(0xFFF44336);
        statusLabel = 'REFUSÉ';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFF9E9E9E);
        statusLabel = 'BROUILLON';
        statusIcon = Icons.edit_note_outlined;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Icône statut
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, size: 18, color: statusColor),
              ),
              const SizedBox(width: 12),
              // Numéro + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.quoteNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDate(quote.quoteDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Badge statut + montant
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(quote.totalTTC),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_quotes.last.id != quote.id)
          Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
