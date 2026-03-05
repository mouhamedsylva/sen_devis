import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/quote_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../data/database/app_database.dart';
import '../../data/models/model_extensions.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/mobile_button.dart';
import '../../widgets/product_autocomplete_field.dart';
import '../clients/client_form_screen.dart';

class QuoteFormScreen extends StatefulWidget {
  static const String routeName = '/quote-form';

  const QuoteFormScreen({Key? key}) : super(key: key);

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _deliveryDelayController = TextEditingController();
  final _depositPercentageController = TextEditingController(text: '40');
  final _depositAmountController = TextEditingController(text: '0');
  final _validityDaysController = TextEditingController(text: '30');

  int? _quoteId;
  int? _preselectedClientId;
  Client? _selectedClient;
  DateTime _selectedDate = DateTime.now();
  List<QuoteItem> _items = [];
  List<QuoteItem> _laborItems = [];
  bool _isLoading = false;
  String _quoteNumber = '';
  
  // Nouvelles conditions du devis
  bool _depositRequired = false;
  String _depositType = 'percentage'; // 'percentage' ou 'amount'
  double _depositPercentage = 40.0;
  double _depositAmount = 0.0;
  int _validityDays = 30;
  bool _validityEnabled = false;
  bool _deliveryDelayEnabled = false;

  double _totalHT = 0.0;
  double _totalVAT = 0.0;
  double _totalTTC = 0.0;

  // Couleurs dynamiques
  late Color _primaryColor;
  late Color _backgroundColor;
  late Color _cardBackground;
  late Color _textPrimary;
  late Color _textSecondary;
  late Color _borderColor;

  void _initColors(BuildContext context) {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    _primaryColor = const Color(0xFF0D7C7E);
    _backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    _cardBackground = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    _textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    _textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    _borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
  }

  @override
  void initState() {
    super.initState();
    // Initialiser les couleurs avec des valeurs par défaut (mode clair)
    _primaryColor = const Color(0xFF0D7C7E);
    _backgroundColor = const Color(0xFFF8F9FA);
    _cardBackground = Colors.white;
    _textPrimary = const Color(0xFF1F2937);
    _textSecondary = const Color(0xFF6B7280);
    _borderColor = const Color(0xFFE5E7EB);
    
    _generateQuoteNumber();
    // ✅ Écouter les changements dans les notes pour sauvegarder automatiquement
    _notesController.addListener(() {
      if (_quoteId == null) { // Seulement pour les nouveaux devis
        _saveDraft();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _quoteId = args?['quoteId'];
    _preselectedClientId = args?['preselectedClientId'];
  }

  // ✅ Sauvegarde automatique du brouillon
  Future<void> _saveDraft() async {
    // Ne pas sauvegarder si on édite un devis existant
    if (_quoteId != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'clientId': _selectedClient?.id,
      'date': _selectedDate.toIso8601String(),
      'notes': _notesController.text,
      // ❌ NE PAS sauvegarder le numéro de devis - il sera régénéré
      'items': _items.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'vatRate': item.vatRate,
      }).toList(),
      'laborItems': _laborItems.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'vatRate': item.vatRate,
      }).toList(),
    };
    await prefs.setString('quote_draft', jsonEncode(draft));
  }

  // ✅ Restauration du brouillon
  Future<void> _loadDraft() async {
    // Ne pas charger le brouillon si on édite un devis existant
    if (_quoteId != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString('quote_draft');
    
    if (draftJson != null) {
      try {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        
        // Restaurer le client
        if (draft['clientId'] != null) {
          final client = context.read<ClientProvider>().getClientById(draft['clientId']);
          if (client != null) {
            _selectedClient = client;
          }
        }
        
        // Restaurer la date
        if (draft['date'] != null) {
          _selectedDate = DateTime.parse(draft['date']);
        }
        
        // Restaurer les notes
        if (draft['notes'] != null) {
          _notesController.text = draft['notes'];
        }
        
        // ❌ NE PAS restaurer le numéro de devis - un nouveau a déjà été généré dans initState
        
        // Restaurer les produits
        if (draft['items'] != null) {
          _items = (draft['items'] as List).map((item) {
            return QuoteItemExtension.createTemp(
              productId: item['productId'] ?? 0,
              productName: item['productName'] ?? '',
              quantity: (item['quantity'] ?? 1).toDouble(),
              unitPrice: (item['unitPrice'] ?? 0).toDouble(),
              vatRate: (item['vatRate'] ?? 0).toDouble(),
            );
          }).toList();
        }
        
        // Restaurer la main d'œuvre
        if (draft['laborItems'] != null) {
          _laborItems = (draft['laborItems'] as List).map((item) {
            return QuoteItemExtension.createTemp(
              productId: item['productId'] ?? 0,
              productName: item['productName'] ?? '',
              quantity: (item['quantity'] ?? 1).toDouble(),
              unitPrice: (item['unitPrice'] ?? 0).toDouble(),
              vatRate: (item['vatRate'] ?? 0).toDouble(),
            );
          }).toList();
        }
        
        setState(() {});
        _calculateTotals();
        
        // Afficher un message de confirmation
        if (mounted) {
          MobileUtils.showMobileSnackBar(
            context,
            message: 'Brouillon restauré',
            backgroundColor: Colors.blue,
            icon: Icons.restore,
          );
        }
      } catch (e) {
        // Erreur lors de la restauration, supprimer le brouillon corrompu
        await prefs.remove('quote_draft');
      }
    }
  }

  // ✅ Suppression du brouillon
  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quote_draft');
  }

  void _generateQuoteNumber() {
    final now = DateTime.now();
    _quoteNumber = 'DV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      await context.read<ClientProvider>().loadClients(userId);
      await context.read<ProductProvider>().loadProducts(userId);

      // ✅ AJOUTER : Présélectionner le client si fourni
      if (_preselectedClientId != null) {
        final client = context.read<ClientProvider>().getClientById(_preselectedClientId!);
        if (client != null) {
          setState(() {
            _selectedClient = client;
          });
        }
      }

      if (_quoteId != null) {
        await _loadQuote();
      } else {
        // ✅ Charger le brouillon si on crée un nouveau devis
        await _loadDraft();
      }
    }
  }

  Future<void> _loadQuote() async {
    final quoteDetails = await context.read<QuoteProvider>().loadQuoteWithItems(_quoteId!);
    if (quoteDetails != null) {
      setState(() {
        _selectedClient = quoteDetails.client;
        _selectedDate = quoteDetails.quote.quoteDate;
        // ✅ Séparer produits et main d'œuvre
        _items = quoteDetails.items
            .where((i) => !QuoteItemExtension.isLaborItem(i))
            .toList();
        _laborItems = quoteDetails.items
            .where((i) => QuoteItemExtension.isLaborItem(i))
            .toList();
        _notesController.text = quoteDetails.quote.notes ?? '';
        _quoteNumber = quoteDetails.quote.quoteNumber;
        
        // Charger les conditions
        _depositRequired = quoteDetails.quote.depositRequired ?? false;
        _depositType = quoteDetails.quote.depositType ?? 'percentage';
        _depositPercentage = quoteDetails.quote.depositPercentage ?? 40.0;
        _depositAmount = quoteDetails.quote.depositAmount ?? 0.0;
        _depositPercentageController.text = _depositPercentage.toStringAsFixed(0);
        _depositAmountController.text = _depositAmount.toStringAsFixed(0);
        
        _validityDays = quoteDetails.quote.validityDays ?? 30;
        _validityEnabled = _validityDays > 0;
        _validityDaysController.text = _validityDays.toString();
        
        _deliveryDelayController.text = quoteDetails.quote.deliveryDelay ?? '';
        _deliveryDelayEnabled = quoteDetails.quote.deliveryDelay != null && quoteDetails.quote.deliveryDelay!.isNotEmpty;
      });
      _calculateTotals();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _deliveryDelayController.dispose();
    _depositPercentageController.dispose();
    _depositAmountController.dispose();
    _validityDaysController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double ht = 0.0;
    double vat = 0.0;
    double ttc = 0.0;

    // ✅ Produits + Main d'œuvre
    for (var item in [..._items, ..._laborItems]) {
      ht += item.totalHT;
      vat += item.totalVAT;
      ttc += item.totalTTC;
    }

    setState(() {
      _totalHT = ht;
      _totalVAT = vat;
      _totalTTC = ttc;
    });
  }

  Future<void> _handleAbandonQuote() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('abandon_quote'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('abandon_quote_message'),
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: _borderColor),
                      ),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('abandon'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      // Supprimer le brouillon sauvegardé
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quote_draft');
      
      if (mounted) {
        MobileUtils.showMobileSnackBar(
          context,
          message: context.tr('quote_abandoned'),
          icon: Icons.check_circle,
          backgroundColor: Colors.green.shade600,
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _selectClient() async {
    MobileUtils.lightHaptic();
    final clients = context.read<ClientProvider>().clients;

    if (clients.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
      final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
      final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
      
      // Obtenir la largeur de l'écran pour adapter le design
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      
      final create = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: cardBg,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône
                  Container(
                    width: isSmallScreen ? 56 : 64,
                    height: isSmallScreen ? 56 : 64,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: _primaryColor,
                      size: isSmallScreen ? 28 : 32,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Titre
                  Text(
                    context.tr('no_client'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 12),
                  
                  // Message
                  Text(
                    context.tr('must_create_client'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  
                  // Boutons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Si l'écran est très petit, empiler les boutons verticalement
                      if (constraints.maxWidth < 280) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bouton Créer (en premier pour l'action principale)
                            ElevatedButton(
                              onPressed: () {
                                MobileUtils.mediumHaptic();
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.tr('create_client'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Bouton Annuler
                            OutlinedButton(
                              onPressed: () {
                                MobileUtils.lightHaptic();
                                Navigator.of(context).pop(false);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                context.tr('cancel'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      // Sinon, afficher les boutons côte à côte
                      return Row(
                        children: [
                          // Bouton Annuler
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                MobileUtils.lightHaptic();
                                Navigator.of(context).pop(false);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                context.tr('cancel'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Bouton Créer
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                MobileUtils.mediumHaptic();
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.tr('create_client'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (create == true) {
        // Naviguer vers le formulaire de création de client
        final createdClient = await Navigator.of(context).pushNamed(ClientFormScreen.routeName);
        
        // Recharger la liste des clients
        await context.read<ClientProvider>().loadClients(
              context.read<AuthProvider>().userId!,
            );
        
        // Si un client a été créé, le sélectionner automatiquement
        if (createdClient != null && createdClient is Client) {
          setState(() {
            _selectedClient = createdClient;
          });
          _saveDraft(); // ✅ Sauvegarder le brouillon
          MobileUtils.showMobileSnackBar(
            context,
            message: 'Client "${createdClient.name}" sélectionné',
            icon: Icons.check_circle_outline,
            backgroundColor: _primaryColor,
          );
        }
      }
      return;
    }

    final selected = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientPickerSheet(
        clients: clients,
        primaryColor: _primaryColor,
        cardBackground: _cardBackground,
        backgroundColor: _backgroundColor,
        textPrimary: _textPrimary,
        textSecondary: _textSecondary,
        borderColor: _borderColor,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedClient = selected;
      });
      _saveDraft(); // ✅ Sauvegarder le brouillon
    }
  }

  Future<void> _selectDate() async {
    MobileUtils.lightHaptic();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _saveDraft(); // ✅ Sauvegarder le brouillon
    }
  }

  Future<void> _addItem() async {
    final products = context.read<ProductProvider>().products;

    if (products.isEmpty) {
      MobileUtils.showMobileSnackBar(
        context,
        message: context.tr('must_create_products'),
        backgroundColor: Colors.orange,
        icon: Icons.warning_outlined,
      );
      return;
    }

    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductPickerSheet(
        products: products,
        primaryColor: _primaryColor,
        cardBackground: _cardBackground,
        backgroundColor: _backgroundColor,
        textPrimary: _textPrimary,
        textSecondary: _textSecondary,
        borderColor: _borderColor,
      ),
    );

    if (selected != null) {
      await _showQuantityDialog(selected);
    }
  }

  Future<void> _createNewProduct() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final taxRateController = TextEditingController(text: '18.0');
    final quantityController = TextEditingController(text: '1');
    
    // FocusNodes pour gérer l'effacement automatique
    final priceFocusNode = FocusNode();
    final taxRateFocusNode = FocusNode();
    final quantityFocusNode = FocusNode();
    
    bool isTaxable = true;
    
    // Vider le champ prix lors du premier focus
    bool priceCleared = false;
    void priceFocusListener() {
      if (priceFocusNode.hasFocus && !priceCleared && priceController.text.isEmpty) {
        priceController.clear();
        priceCleared = true;
      }
    }
    priceFocusNode.addListener(priceFocusListener);
    
    // Vider le champ taux de TVA lors du premier focus
    bool taxRateCleared = false;
    void taxRateFocusListener() {
      if (taxRateFocusNode.hasFocus && !taxRateCleared && taxRateController.text == '18.0') {
        taxRateController.clear();
        taxRateCleared = true;
      }
    }
    taxRateFocusNode.addListener(taxRateFocusListener);
    
    // Vider le champ quantité lors du premier focus
    bool quantityCleared = false;
    void quantityFocusListener() {
      if (quantityFocusNode.hasFocus && !quantityCleared && quantityController.text == '1') {
        quantityController.clear();
        quantityCleared = true;
      }
    }
    quantityFocusNode.addListener(quantityFocusListener);
    
    // Variable pour stocker les suggestions (en dehors du builder pour persister)
    List<Product> suggestions = [];

    // Récupérer la liste des produits existants
    final products = context.read<ProductProvider>().products;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setSheet) {

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poignée
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Titre
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, color: _primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('new_product_dialog'),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: _textSecondary, size: 20),
                          onPressed: () => Navigator.pop(modalContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nom du produit avec auto-complétion
                    _buildSheetLabel(context.tr('product_name')),
                    const SizedBox(height: 8),
                    ProductAutocompleteField(
                      controller: nameController,
                      products: products,
                      hint: context.tr('product_name_hint'),
                      primaryColor: _primaryColor,
                      cardBackground: _cardBackground,
                      textPrimary: _textPrimary,
                      textSecondary: _textSecondary,
                      borderColor: _borderColor,
                      onSuggestionsChanged: (newSuggestions) {
                        debugPrint('=== onSuggestionsChanged CALLBACK ===');
                        debugPrint('Suggestions count: ${newSuggestions.length}');
                        setSheet(() {
                          suggestions = newSuggestions;
                        });
                      },
                    ),
                    
                    // Afficher les suggestions directement dans la modale
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: suggestions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: _borderColor),
                          itemBuilder: (context, index) {
                            final product = suggestions[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: Icon(Icons.inventory_2_outlined, color: _primaryColor, size: 20),
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${CurrencyFormatter.format(product.unitPrice)} • TVA ${product.vatRate.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12, color: _textSecondary),
                                ),
                                onTap: () {
                                  debugPrint('=== SUGGESTION TAPPED ===');
                                  debugPrint('Product: ${product.name}');
                                  debugPrint('Price: ${product.unitPrice}');
                                  debugPrint('VAT: ${product.vatRate}');
                                  
                                  // Pré-remplir les champs
                                  nameController.text = product.name;
                                  priceController.text = product.unitPrice.toStringAsFixed(2);
                                  taxRateController.text = product.vatRate.toStringAsFixed(1);
                                  
                                  setSheet(() {
                                    isTaxable = product.vatRate > 0;
                                    suggestions = []; // Effacer les suggestions
                                  });
                                  
                                  debugPrint('=== FIELDS UPDATED ===');
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                  // Prix + TVA
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetLabel(context.tr('unit_price')),
                            const SizedBox(height: 8),
                            _buildSheetTextField(
                              controller: priceController,
                              focusNode: priceFocusNode,
                              hint: '0.00',
                              icon: Icons.attach_money,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetLabel(context.tr('tax_rate')),
                            const SizedBox(height: 8),
                            _buildSheetTextField(
                              controller: taxRateController,
                              focusNode: taxRateFocusNode,
                              hint: '18.0',
                              suffix: '%',
                              enabled: isTaxable,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ AJOUTER : Séparateur + champ quantité
                  Divider(height: 1, color: _borderColor),
                  const SizedBox(height: 16),

                  _buildSheetLabel(context.tr('quantity')),
                  const SizedBox(height: 8),
                  _buildSheetTextField(
                    controller: quantityController,
                    focusNode: quantityFocusNode,
                    hint: '1',
                    icon: Icons.numbers,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // Toggle taxable
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_outlined, size: 18, color: _textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('taxable'),
                              style: TextStyle(
                                fontSize: 14,
                                color: _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isTaxable,
                          activeColor: _primaryColor,
                          onChanged: (v) {
                            setSheet(() {
                              isTaxable = v;
                              if (!v) taxRateController.text = '0';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton créer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(modalContext, true),
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18), // ✅ icône mise à jour
                      label: Text(
                        context.tr('create'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );

    // Gérer le résultat du bouton "Créer"
    if (result == true) {
      // Créer un nouveau produit
      if (nameController.text.trim().isEmpty) {
        MobileUtils.showMobileSnackBar(
          context,
          message: context.tr('enter_product_name'),
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
        nameController.dispose(); priceController.dispose();
        taxRateController.dispose(); quantityController.dispose();
        return;
      }

      final price = double.tryParse(priceController.text.replaceAll(',', '.'));
      if (price == null || price <= 0) {
        MobileUtils.showMobileSnackBar(
          context,
          message: context.tr('enter_valid_price'),
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
        nameController.dispose(); priceController.dispose();
        taxRateController.dispose(); quantityController.dispose();
        return;
      }

      final taxRate = isTaxable
          ? (double.tryParse(taxRateController.text.replaceAll(',', '.')) ?? 18.0)
          : 0.0;

      // ✅ Lire la quantité ici directement
      final quantity = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 1.0;

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId == null) return;

      final productProvider = context.read<ProductProvider>();
      final idsBefore = productProvider.products.map((p) => p.id).toSet();

      final success = await productProvider.addProduct(
        userId: userId,
        name: nameController.text.trim(),
        unitPrice: price,
        vatRate: taxRate,
      );

      if (!mounted) return;

      if (success) {
        MobileUtils.showMobileSnackBar(
          context,
          message: context.tr('product_created'),
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );

        await productProvider.loadProducts(userId);

        final newProduct = productProvider.products
            .where((p) => !idsBefore.contains(p.id))
            .firstOrNull;

        // ✅ Utiliser la quantité saisie directement, sans modale supplémentaire
        if (newProduct != null) {
          final item = QuoteItemExtension.createTemp(
            productId: newProduct.id,
            productName: newProduct.name,
            quantity: quantity,
            unitPrice: newProduct.unitPrice,
            vatRate: newProduct.vatRate,
          );
          setState(() => _items.add(item));
          _calculateTotals();
          _saveDraft(); // ✅ Sauvegarder le brouillon
        }
      } else {
        MobileUtils.showMobileSnackBar(
          context,
          message: productProvider.errorMessage ?? context.tr('creation_error'),
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }

    nameController.dispose();
    priceController.dispose();
    taxRateController.dispose();
    quantityController.dispose();
    
    // Retirer les listeners et disposer les FocusNodes de manière sécurisée
    try {
      priceFocusNode.removeListener(priceFocusListener);
      priceFocusNode.dispose();
    } catch (e) {
      // Ignorer les erreurs de dispose
    }
    try {
      taxRateFocusNode.removeListener(taxRateFocusListener);
      taxRateFocusNode.dispose();
    } catch (e) {
      // Ignorer les erreurs de dispose
    }
    try {
      quantityFocusNode.removeListener(quantityFocusListener);
      quantityFocusNode.dispose();
    } catch (e) {
      // Ignorer les erreurs de dispose
    }
  }

  Future<void> _showQuantityDialog(Product product) async {
    final quantityController = TextEditingController(text: '1');
    final quantityFocusNode = FocusNode();
    final priceTTC = product.unitPrice * (1 + product.vatRate / 100);

    // Vider le champ quantité lors du premier focus
    bool quantityCleared = false;
    void quantityFocusListener() {
      if (quantityFocusNode.hasFocus && !quantityCleared && quantityController.text == '1') {
        quantityController.clear();
        quantityCleared = true;
      }
    }
    quantityFocusNode.addListener(quantityFocusListener);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Infos produit
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: _primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(product.unitPrice)} HT • TVA ${product.vatRate.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: _textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(priceTTC),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSheetLabel(context.tr('quantity')),
              const SizedBox(height: 8),
              _buildSheetTextField(
                controller: quantityController,
                focusNode: quantityFocusNode,
                hint: '1',
                icon: Icons.numbers,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                      label: Text(
                        context.tr('add'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final quantity = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 1;
      final item = QuoteItemExtension.createTemp(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.unitPrice,
        vatRate: product.vatRate,
      );
      setState(() => _items.add(item));
      _calculateTotals();
      _saveDraft(); // ✅ Sauvegarder le brouillon
    }

    quantityController.dispose();
    
    // Retirer le listener et disposer le FocusNode de manière sécurisée
    try {
      quantityFocusNode.removeListener(quantityFocusListener);
      quantityFocusNode.dispose();
    } catch (e) {
      // Ignorer les erreurs de dispose
    }
  }

  void _removeItem(int index) {
    MobileUtils.mediumHaptic();
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotals();
    _saveDraft(); // ✅ Sauvegarder le brouillon
  }

  Future<void> _editItem(int index) async {
    MobileUtils.lightHaptic();
    final item = _items[index];
    final quantityController = TextEditingController(
      text: item.quantity.toInt().toString(),
    );
    final priceController = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_outlined, color: _primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Modifier le produit',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Infos produit
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: _primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TVA ${item.vatRate.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: _textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSheetLabel(context.tr('quantity')),
              const SizedBox(height: 8),
              _buildSheetTextField(
                controller: quantityController,
                hint: '1',
                icon: Icons.numbers,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              _buildSheetLabel('Prix unitaire HT'),
              const SizedBox(height: 8),
              _buildSheetTextField(
                controller: priceController,
                hint: '0.00',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text(
                        'Modifier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final quantity = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 1;
      final unitPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? item.unitPrice;
      if (quantity > 0 && unitPrice >= 0) {
        setState(() {
          _items[index] = QuoteItemExtension.createTemp(
            productId: item.productId ?? 0,
            productName: item.productName,
            quantity: quantity,
            unitPrice: unitPrice,
            vatRate: item.vatRate,
          );
        });
        _calculateTotals();
        
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Produit modifié',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
        _saveDraft(); // ✅ Sauvegarder le brouillon
      }
    }

    quantityController.dispose();
  }

  Future<void> _saveQuote() async {
    if (_selectedClient == null) {
      MobileUtils.showMobileSnackBar(
        context,
        message: context.tr('select_client_error'),
        backgroundColor: Colors.orange,
        icon: Icons.warning_outlined,
      );
      return;
    }

    if (_items.isEmpty) {
      MobileUtils.showMobileSnackBar(
        context,
        message: context.tr('add_item_error'),
        backgroundColor: Colors.orange,
        icon: Icons.warning_outlined,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId == null) return;

    final quoteProvider = context.read<QuoteProvider>();
    
    bool success;
    if (_quoteId == null) {
      final quote = await quoteProvider.createQuote(
        userId: userId,
        clientId: _selectedClient!.id!,
        quoteDate: _selectedDate,
        items: [..._items, ..._laborItems],
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        quoteNumber: _quoteNumber, // ✅ Passer le numéro de devis généré
        depositRequired: _depositRequired,
        depositType: _depositType,
        depositPercentage: _depositRequired && _depositType == 'percentage' ? _depositPercentage : 0,
        depositAmount: _depositRequired && _depositType == 'amount' ? _depositAmount : 0,
        validityDays: _validityEnabled ? _validityDays : 0,
        deliveryDelay: _deliveryDelayEnabled && _deliveryDelayController.text.trim().isNotEmpty 
            ? _deliveryDelayController.text.trim() 
            : null,
      );
      success = quote != null;
    } else {
      success = await quoteProvider.updateQuote(
        quoteId: _quoteId!,
        clientId: _selectedClient!.id!,
        quoteDate: _selectedDate,
        items: [..._items, ..._laborItems],
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      // ✅ Supprimer le brouillon après sauvegarde réussie
      await _clearDraft();
      
      MobileUtils.showMobileSnackBar(
        context,
        message: context.tr('quote_saved'),
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
      Navigator.of(context).pop();
    } else {
      MobileUtils.showMobileSnackBar(
        context,
        message: quoteProvider.errorMessage ?? context.tr('error_occurred'),
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _addLaborItem() async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final vatController = TextEditingController(text: '18.0');
    bool isTaxable = true;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Titre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.engineering_outlined,
                                color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Ajouter main d\'œuvre',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context, false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildSheetLabel('Description de la prestation'),
                  const SizedBox(height: 8),
                  _buildSheetTextField(
                    controller: descController,
                    hint: 'ex. Installation, réparation, transport...',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 16),

                  // Montant HT
                  _buildSheetLabel('Montant HT'),
                  const SizedBox(height: 8),
                  _buildSheetTextField(
                    controller: amountController,
                    hint: '0.00',
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // TVA
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetLabel('TVA (%)'),
                            const SizedBox(height: 8),
                            _buildSheetTextField(
                              controller: vatController,
                              hint: '18.0',
                              suffix: '%',
                              enabled: isTaxable,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggle taxable
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_outlined, size: 18, color: _textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('taxable'),
                              style: TextStyle(
                                fontSize: 14,
                                color: _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isTaxable,
                          activeColor: Colors.orange,
                          onChanged: (v) {
                            setSheet(() {
                              isTaxable = v;
                              if (!v) vatController.text = '0';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.tr('cancel'),
                            style: TextStyle(
                                color: _textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text(
                            'Ajouter',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      if (descController.text.trim().isEmpty) {
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Veuillez saisir une description',
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
        descController.dispose(); 
        amountController.dispose(); 
        vatController.dispose();
        return;
      }

      final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
      if (amount == null || amount <= 0) {
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Veuillez saisir un montant valide',
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
        descController.dispose(); 
        amountController.dispose(); 
        vatController.dispose();
        return;
      }

      final vat = isTaxable 
          ? (double.tryParse(vatController.text.replaceAll(',', '.')) ?? 18.0)
          : 0.0;

      // Créer l'item avec quantité = 1 et prix unitaire = montant saisi
      final item = QuoteItemExtension.createLaborTemp(
        description: descController.text.trim(),
        hours: 1.0, // Quantité fixe à 1
        hourlyRate: amount, // Le montant saisi devient le "taux"
        vatRate: vat,
      );

      setState(() => _laborItems.add(item));
      _calculateTotals();
      _saveDraft(); // ✅ Sauvegarder le brouillon
    }

    descController.dispose();
    amountController.dispose();
    vatController.dispose();
  }

  void _removeLaborItem(int index) {
    MobileUtils.mediumHaptic();
    setState(() => _laborItems.removeAt(index));
    _calculateTotals();
    _saveDraft(); // ✅ Sauvegarder le brouillon
  }

  Future<void> _editLaborItem(int index) async {
    MobileUtils.lightHaptic();
    final item = _laborItems[index];
    final descController = TextEditingController(text: item.productName);
    final amountController = TextEditingController(
      text: item.unitPrice.toStringAsFixed(2),
    );
    final vatController = TextEditingController(
      text: item.vatRate.toStringAsFixed(1),
    );
    bool isTaxable = item.vatRate > 0;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Titre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_outlined,
                                color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Modifier main d\'œuvre',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context, false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildSheetLabel('Description de la prestation'),
                  const SizedBox(height: 8),
                  _buildSheetTextField(
                    controller: descController,
                    hint: 'ex. Installation, réparation, transport...',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 16),

                  // Montant HT
                  _buildSheetLabel('Montant HT'),
                  const SizedBox(height: 8),
                  _buildSheetTextField(
                    controller: amountController,
                    hint: '0.00',
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // TVA
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetLabel('TVA (%)'),
                            const SizedBox(height: 8),
                            _buildSheetTextField(
                              controller: vatController,
                              hint: '18.0',
                              suffix: '%',
                              enabled: isTaxable,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggle taxable
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_outlined, size: 18, color: _textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('taxable'),
                              style: TextStyle(
                                fontSize: 14,
                                color: _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: isTaxable,
                          activeColor: Colors.orange,
                          onChanged: (v) {
                            setSheet(() {
                              isTaxable = v;
                              if (!v) vatController.text = '0';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.tr('cancel'),
                            style: TextStyle(
                                color: _textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text(
                            'Modifier',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true) {
      if (descController.text.trim().isEmpty) {
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Veuillez saisir une description',
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
        descController.dispose(); 
        amountController.dispose(); 
        vatController.dispose();
        return;
      }

      final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
      if (amount == null || amount <= 0) {
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Veuillez saisir un montant valide',
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
        descController.dispose(); 
        amountController.dispose(); 
        vatController.dispose();
        return;
      }

      final vat = isTaxable 
          ? (double.tryParse(vatController.text.replaceAll(',', '.')) ?? 18.0)
          : 0.0;

      setState(() {
        _laborItems[index] = QuoteItemExtension.createLaborTemp(
          description: descController.text.trim(),
          hours: 1.0,
          hourlyRate: amount,
          vatRate: vat,
        );
      });
      _calculateTotals();
      _saveDraft(); // ✅ Sauvegarder le brouillon
      
      MobileUtils.showMobileSnackBar(
        context,
        message: 'Main d\'œuvre modifiée',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
    }

    descController.dispose();
    amountController.dispose();
    vatController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initColors(context);
    final isEdit = _quoteId != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isEdit),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildQuoteDetailsSection().animate().fadeIn(
                                delay: 200.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 200.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              const SizedBox(height: 24),
                              
                              _buildClientDetailsSection().animate().fadeIn(
                                delay: 300.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 300.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              const SizedBox(height: 24),
                              
                              _buildLineItemsSection().animate().fadeIn(
                                delay: 400.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 400.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              const SizedBox(height: 24),

                              _buildLaborSection().animate().fadeIn(
                                delay: 500.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 500.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ), // ✅ AJOUTER
                              const SizedBox(height: 24),
                              
                              _buildTotalsSection().animate().fadeIn(
                                delay: 600.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 600.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              const SizedBox(height: 24),
                              
                              _buildConditionsSection().animate().fadeIn(
                                delay: 700.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 700.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              const SizedBox(height: 24),
                              
                              _buildNotesSection().animate().fadeIn(
                                delay: 800.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 800.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              const SizedBox(height: 24),
                              
                              _buildSaveButton().animate().fadeIn(
                                delay: 900.ms,
                                duration: 500.ms,
                              ).slideY(
                                begin: 0.3,
                                end: 0,
                                delay: 900.ms,
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBackground,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: _textPrimary),
            onPressed: () {
              MobileUtils.lightHaptic();
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Text(
              isEdit ? context.tr('edit_quote') : context.tr('create_quote'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A7B7B),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _textPrimary),
            onSelected: (value) async {
              if (value == 'abandon') {
                _handleAbandonQuote();
              } else if (value == 'draft') {
                await _saveDraft();
                if (mounted) {
                  MobileUtils.showMobileSnackBar(
                    context,
                    message: 'Brouillon sauvegardé',
                    icon: Icons.check_circle,
                    backgroundColor: Colors.green.shade600,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              if (!isEdit) ...[
                PopupMenuItem(
                  value: 'draft',
                  child: Row(
                    children: [
                      Icon(Icons.save_outlined, size: 20, color: _primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('save_draft'),
                        style: TextStyle(color: _textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'abandon',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('abandon_quote'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSheetLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? suffix,
    bool enabled = true,
    bool autofocus = false,
    TextInputType? keyboardType,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? _backgroundColor : _backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: _textSecondary)
              : null,
          suffixText: suffix,
          suffixStyle: TextStyle(color: _textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildQuoteDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                context.tr('quote_details'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('quote_number'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _quoteNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('date'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            DateFormatter.format(_selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.calendar_today_outlined, size: 16, color: _textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('client_details'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  // Snapshot avant création
                  final clientsBefore = context.read<ClientProvider>().clients.map((c) => c.id).toSet();

                  await Navigator.of(context).pushNamed(ClientFormScreen.routeName);

                  await context.read<ClientProvider>().loadClients(
                    context.read<AuthProvider>().userId!,
                  );

                  // ✅ Trouver le client nouvellement créé et le présélectionner
                  final clientsAfter = context.read<ClientProvider>().clients;
                  final newClient = clientsAfter.where((c) => !clientsBefore.contains(c.id)).firstOrNull;

                  if (newClient != null && mounted) {
                    setState(() {
                      _selectedClient = newClient;
                    });
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.tr('new_client_button')),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('select_client'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectClient,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor),
                borderRadius: BorderRadius.circular(8),
                color: _backgroundColor,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: _textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedClient?.name ?? context.tr('search_client_placeholder'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedClient != null ? _textPrimary : _textSecondary,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 20, color: _textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('items'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _createNewProduct,
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.tr('new_product')),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 48,
                      color: _textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('no_items_added'),
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildLineItem(item, index);
            }).toList(),
          
          const SizedBox(height: 16),
          
          // Bouton Add Item
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _borderColor,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _addItem,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.tr('add_item'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLaborSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _laborItems.isEmpty
              ? _borderColor
              : Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.engineering_outlined,
                        size: 16, color: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Main d\'œuvre',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  if (_laborItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_laborItems.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton.icon(
                onPressed: _addLaborItem,
                icon: const Icon(Icons.add, size: 16, color: Colors.orange),
                label: const Text(
                  'Ajouter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ],
          ),

          if (_laborItems.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withOpacity(0.15),
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.engineering_outlined,
                      size: 32, color: Colors.orange.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune main d\'œuvre',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Optionnel — ajoutez si nécessaire',
                    style: TextStyle(
                      fontSize: 11,
                      color: _textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ..._laborItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildLaborItem(item, index);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildLaborItem(QuoteItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.engineering_outlined,
                size: 18, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Affichage simplifié : juste la TVA si applicable
                if (item.vatRate > 0)
                  _buildLaborChip(
                    'TVA ${item.vatRate.toStringAsFixed(0)}%',
                    Icons.receipt_outlined,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Utiliser le widget intelligent pour le montant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSmartAmount(
                item.totalHT,
                color: Colors.orange,
              ),
              Text(
                'HT',
                style: TextStyle(fontSize: 10, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Boutons d'action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _editLaborItem(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: Colors.orange),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeLaborItem(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaborChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.orange.shade700),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(QuoteItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: _primaryColor,
                    onPressed: () => _editItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Modifier la quantité',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: _textSecondary,
                    onPressed: () => _removeItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('qty'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity.toInt()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('unit_price_label'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSmartAmount(item.unitPrice),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr('total'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSmartAmount(item.totalHT),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final taxRate = _items.isEmpty ? 0.0 : (_totalVAT / _totalHT * 100);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          // Sous-total HT avec affichage intelligent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('subtotal'),
                style: TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
              _buildSmartAmount(_totalHT),
            ],
          ),
          const SizedBox(height: 12),
          // TVA avec affichage intelligent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${context.tr('tax')} (${taxRate.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.info_outline, size: 14, color: _textSecondary),
                ],
              ),
              _buildSmartAmount(_totalVAT),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: _borderColor),
          ),
          // Montant final TTC avec affichage intelligent et mise en valeur
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('final_amount'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              _buildSmartAmount(
                _totalTTC,
                isFinalAmount: true,
                color: _primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formate un montant en version abrégée (M pour millions, K pour milliers)
  String _formatAbbreviated(double amount) {
    if (amount >= 1000000000) { // >= 1 milliard
      final value = amount / 1000000000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}Mrd FCFA';
    } else if (amount >= 1000000) { // >= 1 million
      final value = amount / 1000000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}M FCFA';
    } else if (amount >= 1000) { // >= 1 millier
      final value = amount / 1000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}K FCFA';
    }
    return CurrencyFormatter.format(amount);
  }

  /// Widget intelligent pour afficher un montant avec taille adaptative
  Widget _buildSmartAmount(double amount, {
    bool isFinalAmount = false,
    Color? color,
  }) {
    String formatted;
    double fontSize;
    String? tooltip;
    
    if (amount >= 100000000) { // >= 100M : format abrégé avec tooltip
      formatted = _formatAbbreviated(amount);
      fontSize = isFinalAmount ? 20 : 14;
      tooltip = CurrencyFormatter.format(amount); // Montant complet dans le tooltip
    } else if (amount >= 10000000) { // >= 10M : taille réduite
      formatted = CurrencyFormatter.format(amount);
      fontSize = isFinalAmount ? 16 : 13;
    } else if (amount >= 1000000) { // >= 1M : légèrement réduit
      formatted = CurrencyFormatter.format(amount);
      fontSize = isFinalAmount ? 18 : 14;
    } else { // < 1M : taille normale
      formatted = CurrencyFormatter.format(amount);
      fontSize = isFinalAmount ? 20 : 14;
    }
    
    Widget text = Text(
      formatted,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isFinalAmount ? FontWeight.w700 : FontWeight.normal,
        color: color ?? (isFinalAmount ? _primaryColor : _textPrimary),
      ),
      textAlign: TextAlign.right,
    );
    
    // Ajouter tooltip si montant abrégé
    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 14, color: _textSecondary),
            const SizedBox(width: 4),
            text,
          ],
        ),
      );
    }
    
    return text;
  }

  Widget _buildConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 16, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'CONDITIONS DU DEVIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Acompte requis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _depositRequired,
                      onChanged: (value) {
                        MobileUtils.lightHaptic();
                        setState(() {
                          _depositRequired = value ?? false;
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'Acompte requis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_depositRequired) ...[
                  const SizedBox(height: 12),
                  // Sélecteur de type d'acompte
                  Padding(
                    padding: const EdgeInsets.only(left: 48, right: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              MobileUtils.lightHaptic();
                              setState(() {
                                _depositType = 'percentage';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _depositType == 'percentage' 
                                    ? _primaryColor 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _depositType == 'percentage' 
                                      ? _primaryColor 
                                      : _borderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.percent,
                                    size: 16,
                                    color: _depositType == 'percentage' 
                                        ? Colors.white 
                                        : _textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pourcentage',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _depositType == 'percentage' 
                                          ? Colors.white 
                                          : _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              MobileUtils.lightHaptic();
                              setState(() {
                                _depositType = 'amount';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _depositType == 'amount' 
                                    ? _primaryColor 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _depositType == 'amount' 
                                      ? _primaryColor 
                                      : _borderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: _depositType == 'amount' 
                                        ? Colors.white 
                                        : _textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Montant',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _depositType == 'amount' 
                                          ? Colors.white 
                                          : _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Champ de saisie selon le type
                  if (_depositType == 'percentage')
                    Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: TextField(
                            controller: _depositPercentageController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final percentage = double.tryParse(value) ?? 40.0;
                              setState(() {
                                _depositPercentage = percentage.clamp(0, 100);
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Pourcentage',
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            CurrencyFormatter.format(_totalTTC * (_depositPercentage / 100)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 48, right: 12),
                      child: TextField(
                        controller: _depositAmountController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                          setState(() {
                            _depositAmount = amount;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Montant de l\'acompte',
                          suffixText: 'FCFA',
                          helperText: _totalTTC > 0 
                              ? 'Soit ${((_depositAmount / _totalTTC) * 100).toStringAsFixed(1)}% du total'
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Validité du devis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _validityEnabled,
                      onChanged: (value) {
                        MobileUtils.lightHaptic();
                        setState(() {
                          _validityEnabled = value ?? false;
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'Validité du devis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_validityEnabled) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: TextField(
                      controller: _validityDaysController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final days = int.tryParse(value) ?? 30;
                        setState(() {
                          _validityDays = days;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Nombre de jours',
                        hintText: '30',
                        prefixIcon: Icon(Icons.calendar_today, color: _primaryColor, size: 20),
                        suffixText: 'jours',
                        helperText: 'Expire le ${DateFormatter.format(_selectedDate.add(Duration(days: _validityDays)))}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: _cardBackground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Délai de livraison
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _deliveryDelayEnabled,
                      onChanged: (value) {
                        MobileUtils.lightHaptic();
                        setState(() {
                          _deliveryDelayEnabled = value ?? false;
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'Délai de livraison',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_deliveryDelayEnabled) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: TextField(
                      controller: _deliveryDelayController,
                      decoration: InputDecoration(
                        labelText: 'Délai',
                        hintText: 'Ex: 2 semaines, 15 jours ouvrés...',
                        prefixIcon: Icon(Icons.local_shipping_outlined, color: _primaryColor, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: _cardBackground,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('notes_conditions'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: context.tr('notes_placeholder'),
              hintStyle: TextStyle(
                color: _textSecondary,
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: _backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return MobileButton(
      text: _isLoading ? context.tr('saving') : context.tr('generate_quote'),
      onPressed: _saveQuote,
      icon: Icons.save_outlined,
      isLoading: _isLoading,
      backgroundColor: _primaryColor,
      height: MobileConstants.buttonHeight,
    );
  }
}




class _ClientPickerSheet extends StatefulWidget {
  final List<Client> clients;
  final Color primaryColor;
  final Color cardBackground;
  final Color backgroundColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  const _ClientPickerSheet({
    required this.clients,
    required this.primaryColor,
    required this.cardBackground,
    required this.backgroundColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> get _filtered {
    if (_searchQuery.isEmpty) return widget.clients;
    final q = _searchQuery.toLowerCase();
    return widget.clients.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.toLowerCase().contains(q) ?? false) ||
          (c.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Client> get _paginated {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil();

  bool get _hasPagination => _filtered.length > _pageSize;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getAvatarColor(String initials) {
    final colors = [
      const Color(0xFF0D7C7E),
      const Color(0xFF2E7D32),
      const Color(0xFF1976D2),
      const Color(0xFF7B1FA2),
      const Color(0xFFC62828),
      const Color(0xFFEF6C00),
    ];
    final code = initials.codeUnitAt(0) + (initials.length > 1 ? initials.codeUnitAt(1) : 0);
    return colors[code % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;
    final paginated = _paginated;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Poignée ──
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Titre ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, color: widget.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sélectionner un client',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: widget.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filtered.length} client${filtered.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Champ de recherche ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: false,
                    style: TextStyle(color: widget.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, téléphone...',
                      hintStyle: TextStyle(color: widget.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: widget.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: widget.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 0;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 0;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Divider(height: 1, color: widget.borderColor),

              // ── Liste ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: widget.primaryColor.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Aucun client trouvé',
                              style: TextStyle(
                                color: widget.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez une autre recherche',
                              style: TextStyle(
                                color: widget.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: paginated.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: widget.borderColor.withOpacity(0.5),
                          indent: 68,
                        ),
                        itemBuilder: (context, index) {
                          final client = paginated[index];
                          final initials = _getInitials(client.name);
                          final avatarColor = _getAvatarColor(initials);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(client),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: avatarColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            color: avatarColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Infos
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            client.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: widget.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (client.phone != null && client.phone!.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(Icons.phone_outlined,
                                                    size: 12, color: widget.textSecondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  client.phone!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: widget.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (client.email != null && client.email!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.email_outlined,
                                                    size: 12, color: widget.textSecondary),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    client.email!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: widget.textSecondary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    Icon(
                                      Icons.chevron_right,
                                      color: widget.textSecondary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // ── Pagination ──
              if (_hasPagination)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: widget.cardBackground,
                    border: Border(top: BorderSide(color: widget.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton Précédent
                      _PaginationButton(
                        icon: Icons.chevron_left,
                        label: 'Préc.',
                        enabled: _currentPage > 0,
                        primaryColor: widget.primaryColor,
                        borderColor: widget.borderColor,
                        textSecondary: widget.textSecondary,
                        onTap: () => setState(() => _currentPage--),
                      ),

                      // Indicateurs de page
                      Row(
                        children: List.generate(_totalPages, (i) {
                          final isActive = i == _currentPage;
                          return GestureDetector(
                            onTap: () => setState(() => _currentPage = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? widget.primaryColor
                                    : widget.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Bouton Suivant
                      _PaginationButton(
                        icon: Icons.chevron_right,
                        label: 'Suiv.',
                        iconAfter: true,
                        enabled: _currentPage < _totalPages - 1,
                        primaryColor: widget.primaryColor,
                        borderColor: widget.borderColor,
                        textSecondary: widget.textSecondary,
                        onTap: () => setState(() => _currentPage++),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool iconAfter;
  final Color primaryColor;
  final Color borderColor;
  final Color textSecondary;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.primaryColor,
    required this.borderColor,
    required this.textSecondary,
    required this.onTap,
    this.iconAfter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? primaryColor : textSecondary.withOpacity(0.4);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? primaryColor.withOpacity(0.3) : borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconAfter
              ? [
                  Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(icon, size: 18, color: color),
                ]
              : [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
                ],
        ),
      ),
    );
  }
}


class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final Color primaryColor;
  final Color cardBackground;
  final Color backgroundColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;

  const _ProductPickerSheet({
    required this.products,
    required this.primaryColor,
    required this.cardBackground,
    required this.backgroundColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  static const int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    if (_searchQuery.isEmpty) return widget.products;
    final q = _searchQuery.toLowerCase();
    return widget.products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  List<Product> get _paginated {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil();
  bool get _hasPagination => _filtered.length > _pageSize;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final paginated = _paginated;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: widget.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sélectionner un produit',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: widget.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filtered.length} produit${filtered.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: widget.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: TextStyle(color: widget.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: widget.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: widget.textSecondary),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _currentPage = 0;
                              }),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 0;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Divider(height: 1, color: widget.borderColor),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun produit trouvé',
                              style: TextStyle(color: widget.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: paginated.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: widget.borderColor.withOpacity(0.5),
                          indent: 68,
                        ),
                        itemBuilder: (context, index) {
                          final product = paginated[index];
                          final priceTTC = product.unitPrice * (1 + product.vatRate / 100);

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(product),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: widget.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: widget.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: widget.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text(
                                                '${CurrencyFormatter.format(product.unitPrice)} HT',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: widget.textSecondary,
                                                ),
                                              ),
                                              if (product.vatRate > 0) ...[
                                                Text(
                                                  ' • TVA ${product.vatRate.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue.shade600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(priceTTC),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: widget.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'TTC',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: widget.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right, color: widget.textSecondary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (_hasPagination)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: widget.cardBackground,
                    border: Border(top: BorderSide(color: widget.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PaginationButton(
                        icon: Icons.chevron_left,
                        label: 'Préc.',
                        enabled: _currentPage > 0,
                        primaryColor: widget.primaryColor,
                        borderColor: widget.borderColor,
                        textSecondary: widget.textSecondary,
                        onTap: () => setState(() => _currentPage--),
                      ),
                      Row(
                        children: List.generate(_totalPages, (i) {
                          final isActive = i == _currentPage;
                          return GestureDetector(
                            onTap: () => setState(() => _currentPage = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? widget.primaryColor
                                    : widget.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                      _PaginationButton(
                        icon: Icons.chevron_right,
                        label: 'Suiv.',
                        iconAfter: true,
                        enabled: _currentPage < _totalPages - 1,
                        primaryColor: widget.primaryColor,
                        borderColor: widget.borderColor,
                        textSecondary: widget.textSecondary,
                        onTap: () => setState(() => _currentPage++),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
