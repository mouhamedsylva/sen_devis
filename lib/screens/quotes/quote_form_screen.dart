import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  int? _quoteId;
  Client? _selectedClient;
  DateTime _selectedDate = DateTime.now();
  List<QuoteItem> _items = [];
  bool _isLoading = false;
  String _quoteNumber = '';

  double _totalHT = 0.0;
  double _totalVAT = 0.0;
  double _totalTTC = 0.0;

  // Couleurs dynamiques (initialisées dans build)
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
    _generateQuoteNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _quoteId = args?['quoteId'];
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

      if (_quoteId != null) {
        await _loadQuote();
      }
    }
  }

  Future<void> _loadQuote() async {
    final quoteDetails = await context.read<QuoteProvider>().loadQuoteWithItems(_quoteId!);
    if (quoteDetails != null) {
      setState(() {
        _selectedClient = quoteDetails.client;
        _selectedDate = quoteDetails.quote.quoteDate;
        _items = quoteDetails.items;
        _notesController.text = quoteDetails.quote.notes ?? '';
        _quoteNumber = quoteDetails.quote.quoteNumber;
      });
      _calculateTotals();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double ht = 0.0;
    double vat = 0.0;
    double ttc = 0.0;

    for (var item in _items) {
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

  Future<void> _selectClient() async {
    MobileUtils.lightHaptic();
    final clients = context.read<ClientProvider>().clients;

    if (clients.isEmpty) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('no_client')),
          content: Text(context.tr('must_create_client')),
          actions: [
            TextButton(
              onPressed: () {
                MobileUtils.lightHaptic();
                Navigator.of(context).pop(false);
              },
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                MobileUtils.lightHaptic();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(context.tr('create_client')),
            ),
          ],
        ),
      );

      if (create == true) {
        await Navigator.of(context).pushNamed(ClientFormScreen.routeName);
        await context.read<ClientProvider>().loadClients(
              context.read<AuthProvider>().userId!,
            );
      }
      return;
    }

    final selected = await showDialog<Client>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('select_a_client')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor,
                  child: Text(
                    client.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(client.name),
                subtitle: client.phone != null ? Text(client.phone!) : null,
                onTap: () {
                  MobileUtils.lightHaptic();
                  Navigator.of(context).pop(client);
                },
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedClient = selected;
      });
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

    final selected = await showDialog<Product>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('select_product')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(CurrencyFormatter.format(product.unitPrice)),
                onTap: () {
                  MobileUtils.lightHaptic();
                  Navigator.of(context).pop(product);
                },
              );
            },
          ),
        ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('new_product_dialog')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.tr('product_name'),
                  hintText: context.tr('product_name_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: _backgroundColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.tr('unit_price'),
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: _backgroundColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: taxRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.tr('tax_rate'),
                  hintText: '18.0',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: _backgroundColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(context.tr('create')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (nameController.text.trim().isEmpty) {
        MobileUtils.showMobileSnackBar(
          context,
          message: context.tr('enter_product_name'),
          backgroundColor: Colors.orange,
          icon: Icons.warning_outlined,
        );
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
        return;
      }

      final taxRate = double.tryParse(taxRateController.text.replaceAll(',', '.')) ?? 18.0;

      // Créer le produit
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId == null) return;

      final productProvider = context.read<ProductProvider>();
      final success = await productProvider.addProduct(
        userId: userId,
        name: nameController.text.trim(),
        unitPrice: price,
        vatRate: taxRate,
      );

      if (success) {
        MobileUtils.showMobileSnackBar(
          context,
          message: context.tr('product_created'),
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );

        // Recharger les produits
        await productProvider.loadProducts(userId);

        // Récupérer le produit créé et l'ajouter directement
        final products = productProvider.products;
        if (products.isNotEmpty) {
          final newProduct = products.last;
          await _showQuantityDialog(newProduct);
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
  }

  Future<void> _showQuantityDialog(Product product) async {
    final quantityController = TextEditingController(text: '1');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: quantityController,
              labelText: context.tr('quantity'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.positiveNumber,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(context.tr('add')),
          ),
        ],
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

      setState(() {
        _items.add(item);
      });
      _calculateTotals();
    }

    quantityController.dispose();
  }

  void _removeItem(int index) {
    MobileUtils.mediumHaptic();
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotals();
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
        items: _items,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      success = quote != null;
    } else {
      success = await quoteProvider.updateQuote(
        quoteId: _quoteId!,
        clientId: _selectedClient!.id!,
        quoteDate: _selectedDate,
        items: _items,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
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
                              _buildQuoteDetailsSection(),
                              const SizedBox(height: 24),
                              
                              _buildClientDetailsSection(),
                              const SizedBox(height: 24),
                              
                              _buildLineItemsSection(),
                              const SizedBox(height: 24),
                              
                              _buildTotalsSection(),
                              const SizedBox(height: 24),
                              
                              _buildNotesSection(),
                              const SizedBox(height: 24),
                              
                              _buildSaveButton(),
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
          TextButton(
            onPressed: () {},
            child: Text(
              context.tr('draft'),
              style: TextStyle(
                color: _primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                  await Navigator.of(context).pushNamed(ClientFormScreen.routeName);
                  await context.read<ClientProvider>().loadClients(
                        context.read<AuthProvider>().userId!,
                      );
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
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: _textSecondary,
                onPressed: () => _removeItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                    Text(
                      CurrencyFormatter.format(item.unitPrice),
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
                    Text(
                      CurrencyFormatter.format(item.totalHT),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
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
          _buildTotalRow(context.tr('subtotal'), _totalHT),
          const SizedBox(height: 12),
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
              Text(
                CurrencyFormatter.format(_totalVAT),
                style: TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: _borderColor),
          ),
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
              Text(
                CurrencyFormatter.format(_totalTTC),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: _textPrimary,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 14,
            color: _textPrimary,
          ),
        ),
      ],
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
