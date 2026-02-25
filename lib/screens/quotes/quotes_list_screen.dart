import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../data/database/app_database.dart';
import '../../data/models/model_extensions.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_bottom_navbar.dart';
import 'quote_form_screen.dart';
import 'quote_preview_screen.dart';

class QuotesListScreen extends StatefulWidget {
  static const String routeName = '/quotes';

  const QuotesListScreen({Key? key}) : super(key: key);

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  int _selectedIndex = 2; // Quotes tab

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      await context.read<QuoteProvider>().loadQuotes(userId);
    }
  }

  void _navigateToNewQuote() {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(QuoteFormScreen.routeName);
  }

  void _navigateToQuotePreview(int quoteId) {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(
      QuotePreviewScreen.routeName,
      arguments: {'quoteId': quoteId},
    );
  }

  Future<void> _deleteQuote(int quoteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<QuoteProvider>().deleteQuote(quoteId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.deleteSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final errorMessage = context.read<QuoteProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? AppStrings.errorOccurred),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<QuoteWithClient> _filterQuotes(List<QuoteWithClient> quotesWithClients) {
    var filtered = quotesWithClients;

    // Filtrer par statut
    if (_selectedFilter != 'all') {
      filtered = filtered.where((qwc) => qwc.quote.status == _selectedFilter).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((qwc) {
        return qwc.quote.quoteNumber.toLowerCase().contains(lowerQuery) ||
            qwc.client?.name.toLowerCase().contains(lowerQuery) == true;
      }).toList();
    }

    return filtered;
  }

  void _showFilterOptions() {
    // Vous pouvez implémenter ici des options de filtrage avancées
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options de filtrage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Trier par date'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter le tri
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Trier par montant'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter le tri
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A3B5D);
    final primaryColor = th.primaryColor;
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: th.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('quotes'),
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          Consumer<QuoteProvider>(
            builder: (context, quoteProvider, child) {
              if (quoteProvider.quotesWithClients.isEmpty) {
                return const SizedBox(width: 8);
              }
              
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7A8E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                onPressed: _navigateToNewQuote,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: titleColor),
                      decoration: InputDecoration(
                        hintText: context.tr('search_quotes'),
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterOptions,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Filtres horizontaux
          // Container(
          //   color: Colors.white,
          //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          //   child: SingleChildScrollView(
          //     scrollDirection: Axis.horizontal,
          //     child: Row(
          //       children: [
          //         _buildFilterChip('Tous', 'all'),
          //         const SizedBox(width: 8),
          //         _buildFilterChip('Brouillon', 'draft'),
          //         const SizedBox(width: 8),
          //         _buildFilterChip('Envoyé', 'sent'),
          //         const SizedBox(width: 8),
          //         _buildFilterChip('Accepté', 'accepted'),
          //       ],
          //     ),
          //   ),
          // ),

          // Liste des devis
          Expanded(
            child: Consumer<QuoteProvider>(
              builder: (context, quoteProvider, child) {
                if (quoteProvider.isLoading) {
                  return const Center(child: LoadingIndicator());
                }

                final filteredQuotes = _filterQuotes(quoteProvider.quotesWithClients);

                if (filteredQuotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? context.tr('no_quotes_yet')
                              : context.tr('no_quote_found'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty)
                          Text(
                            context.tr('create_first_quote'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _navigateToNewQuote,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              context.tr('generate_quote'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D7A8E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadQuotes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredQuotes.length,
                    itemBuilder: (context, index) {
                      final quoteWithClient = filteredQuotes[index];
                      return _buildQuoteCard(quoteWithClient);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, child) {
          // Afficher le bouton flottant seulement s'il y a des devis
          if (quoteProvider.quotesWithClients.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: _navigateToNewQuote,
            backgroundColor: const Color(0xFF2D7A8E),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              context.tr('generate_quote'),
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D7A8E) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D7A8E) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(QuoteWithClient quoteWithClient) {
    final quote = quoteWithClient.quote;
    final client = quoteWithClient.client;
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A3B5D);
    final borderClr = isDark ? Colors.grey.shade800 : Colors.grey[200]!;
    
    Color statusColor;
    String statusLabel;

    switch (quote.status) {
      case 'draft':
        statusColor = const Color(0xFF9E9E9E);
        statusLabel = 'BROUILLON';
        break;
      case 'sent':
        statusColor = const Color(0xFF2196F3);
        statusLabel = 'ENVOYÉ';
        break;
      case 'accepted':
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'ACCEPTÉ';
        break;
      case 'rejected':
        statusColor = const Color(0xFFF44336);
        statusLabel = 'REFUSÉ';
        break;
      default:
        statusColor = const Color(0xFF9E9E9E);
        statusLabel = 'BROUILLON';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderClr, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToQuotePreview(quote.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      client?.name ?? 'Client inconnu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${quote.quoteNumber} • ${_formatDate(quote.quoteDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2D7A8E).withOpacity(0.1),
                    child: Text(
                      (client?.name ?? 'C').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D7A8E),
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(quote.totalTTC),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    MobileUtils.lightHaptic();
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Dashboard
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // Products
        Navigator.of(context).pushReplacementNamed('/products');
        break;
      case 2: // Quotes - already here
        break;
      case 3: // Clients
        Navigator.of(context).pushReplacementNamed('/clients');
        break;
      case 4: // Settings
        Navigator.of(context).pushReplacementNamed('/settings');
        break;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}