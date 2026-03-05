import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../core/mixins/route_aware_mixin.dart';
import '../../widgets/custom_bottom_navbar.dart';
import 'product_form_screen.dart';

class ProductsListScreen extends StatefulWidget {
  static const String routeName = '/products';

  const ProductsListScreen({Key? key}) : super(key: key);

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> with RouteAwareMixin {
  @override
  String get routeName => ProductsListScreen.routeName;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 1; // Products tab

  String? _filterTax; // null = tous, 'taxable', 'non_taxable'
  String _sortBy = 'name_az'; // 'name_az', 'name_za', 'price_asc', 'price_desc'

  // Couleurs du design
  static const Color primaryColor = Color(0xFF0D7C7E);

  Color _getTextPrimary(bool isDark) => isDark ? Colors.white : const Color(0xFF1F2937);
  Color _getTextSecondary(bool isDark) => isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
  Color _getCardBg(bool isDark) => isDark ? const Color(0xFF2C2C2C) : Colors.white;
  Color _getBorderColor(bool isDark) => isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
  Color _getBgColor(bool isDark) => isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final productProvider = context.read<ProductProvider>();

      final userId = authProvider.userId;

      if (userId != null) {
        productProvider.loadProducts(userId);
      }
    });
  }



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      await context.read<ProductProvider>().loadProducts(userId);
    }
  }

  void _navigateToAddProduct() {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(ProductFormScreen.routeName);
  }

  void _navigateToEditProduct(int productId) {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(
      ProductFormScreen.routeName,
      arguments: {'productId': productId},
    );
  }

  Future<void> _deleteProduct(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<ProductProvider>().deleteProduct(productId);

      if (!mounted) return;

      if (success) {
        MobileUtils.showMobileSnackBar(
          context,
          message: 'Produit supprimé avec succès',
          backgroundColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
      } else {
        final errorMessage = context.read<ProductProvider>().errorMessage;
        MobileUtils.showMobileSnackBar(
          context,
          message: errorMessage ?? 'Une erreur s\'est produite',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<dynamic> _getFilteredProducts(ProductProvider provider) {
    var products = _searchQuery.isEmpty
        ? provider.products
        : provider.searchProducts(_searchQuery);

    // Filtre TVA
    if (_filterTax == 'taxable') {
      products = products.where((p) => p.vatRate > 0).toList();
    } else if (_filterTax == 'non_taxable') {
      products = products.where((p) => p.vatRate == 0).toList();
    }

    // Tri
    final sorted = List.from(products);
    switch (_sortBy) {
      case 'name_az':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_za':
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'price_asc':
        sorted.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
        break;
    }

    return sorted;
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
      case 1: // Products - already here
        break;
      case 2: // Quotes
        Navigator.of(context).pushReplacementNamed('/quotes');
        break;
      case 3: // Clients
        Navigator.of(context).pushReplacementNamed('/clients');
        break;
      case 4: // Settings
        Navigator.of(context).pushReplacementNamed('/settings');
        break;
    }
  }

  void _showFilterSheet() {
    MobileUtils.lightHaptic();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = _getCardBg(isDark);
    final txtPrimary = _getTextPrimary(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
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
                          const Icon(Icons.tune, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Filtres & Tri',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: txtPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setSheet(() {});
                          setState(() {
                            _filterTax = null;
                            _sortBy = 'name_az';
                          });
                        },
                        child: const Text(
                          'Réinitialiser',
                          style: TextStyle(color: primaryColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Tri ──
                  Text(
                    'TRIER PAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'Nom A → Z',
                        icon: Icons.sort_by_alpha,
                        selected: _sortBy == 'name_az',
                        onTap: () => setSheet(() {
                          setState(() => _sortBy = 'name_az');
                        }),
                      ),
                      _buildChip(
                        label: 'Nom Z → A',
                        icon: Icons.sort_by_alpha,
                        selected: _sortBy == 'name_za',
                        onTap: () => setSheet(() {
                          setState(() => _sortBy = 'name_za');
                        }),
                      ),
                      _buildChip(
                        label: 'Prix croissant',
                        icon: Icons.arrow_upward,
                        selected: _sortBy == 'price_asc',
                        onTap: () => setSheet(() {
                          setState(() => _sortBy = 'price_asc');
                        }),
                      ),
                      _buildChip(
                        label: 'Prix décroissant',
                        icon: Icons.arrow_downward,
                        selected: _sortBy == 'price_desc',
                        onTap: () => setSheet(() {
                          setState(() => _sortBy = 'price_desc');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── TVA ──
                  Text(
                    'FILTRER PAR TVA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip(
                        label: 'Tous',
                        icon: Icons.all_inclusive,
                        selected: _filterTax == null,
                        onTap: () => setSheet(() {
                          setState(() => _filterTax = null);
                        }),
                      ),
                      _buildChip(
                        label: 'Avec TVA',
                        icon: Icons.check_circle_outline,
                        selected: _filterTax == 'taxable',
                        onTap: () => setSheet(() {
                          setState(() => _filterTax = 'taxable');
                        }),
                      ),
                      _buildChip(
                        label: 'Sans TVA',
                        icon: Icons.remove_circle_outline,
                        selected: _filterTax == 'non_taxable',
                        onTap: () => setSheet(() {
                          setState(() => _filterTax = 'non_taxable');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton Appliquer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Appliquer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        MobileUtils.lightHaptic();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primaryColor : primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : primaryColor,
              ),
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
    final bgColor = th.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Barre de recherche
            _buildSearchBar(),

            // Section titre
            _buildSectionHeader(),

            // Liste des produits
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = _getFilteredProducts(productProvider);

                  if (products.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(product, index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  Widget _buildHeader() {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: cardColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: primaryColor,
              size: 20,
            ),
            onPressed: () {
              MobileUtils.lightHaptic();
              // Vérifier s'il y a une page précédente dans la pile
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // Si pas de page précédente, aller à l'accueil
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
          ),
          Expanded(
            child: Text(
              context.tr('products'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 22),
              onPressed: _navigateToAddProduct,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = _getCardBg(isDark);
    final inputBg = _getBgColor(isDark);
    final bColor = _getBorderColor(isDark);
    final txtSecondary = _getTextSecondary(isDark);
    final txtPrimary = _getTextPrimary(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      color: cardColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bColor),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.tr('search_products'),
                  hintStyle: TextStyle(
                    color: txtSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: txtSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Remplacer le Container statique de l'icône filtre par :
          GestureDetector(
            onTap: _showFilterSheet,
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    // ✅ Change de couleur si un filtre est actif
                    color: (_filterTax != null || _sortBy != 'name_az')
                        ? primaryColor
                        : _getBgColor(isDark),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bColor),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: (_filterTax != null || _sortBy != 'name_az')
                        ? Colors.white
                        : txtPrimary,
                    size: 20,
                  ),
                ),
                // Badge point rouge si filtre actif
                if (_filterTax != null || _sortBy != 'name_az')
                  Positioned(
                    right: 6, top: 6,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtSecondary = _getTextSecondary(isDark);

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final count = _getFilteredProducts(productProvider).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('recent_entries'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: txtSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                count > 1 
                  ? context.tr('showing_items_plural').replaceAll('{0}', count.toString())
                  : context.tr('showing_items').replaceAll('{0}', count.toString()),
                style: const TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(product, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _getCardBg(isDark);
    final txtPrimary = _getTextPrimary(isDark);
    final txtSecondary = _getTextSecondary(isDark);
    // Calculer le prix TTC
    final priceTTC = product.unitPrice * (1 + product.vatRate / 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEditProduct(product.id!),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: primaryColor,
                    size: 24,
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
                          color: txtPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 11, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'PRODUIT',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.vatRate > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 11, color: Colors.blue[700]),
                                  const SizedBox(width: 3),
                                  Text(
                                    'TVA ${product.vatRate.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.blue[700]),
                                  ),
                                ],
                              ),
                            ),
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
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: txtPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PAR UNITÉ',
                      style: TextStyle(fontSize: 10, color: txtSecondary, letterSpacing: 0.3),
                    ),
                  ],
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: txtSecondary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: txtPrimary),
                          const SizedBox(width: 12),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditProduct(product.id!);
                    } else if (value == 'delete') {
                      _deleteProduct(product.id!);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 50 * index),
      duration: 500.ms,
    ).slideY(
      begin: 0.2,
      end: 0,
      delay: Duration(milliseconds: 50 * index),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtPrimary = _getTextPrimary(isDark);
    final txtSecondary = _getTextSecondary(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.inventory_2_outlined, size: 60, color: primaryColor),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ).fadeIn(
            duration: 400.ms,
          ).shimmer(
            delay: 600.ms,
            duration: 1200.ms,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? context.tr('no_products') : context.tr('no_product_found'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: txtPrimary),
          ).animate().fadeIn(
            delay: 200.ms,
            duration: 400.ms,
          ).slideY(
            begin: 0.2,
            end: 0,
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('add_first_product'),
            style: TextStyle(fontSize: 14, color: txtSecondary),
          ).animate().fadeIn(
            delay: 400.ms,
            duration: 400.ms,
          ).slideY(
            begin: 0.2,
            end: 0,
            delay: 400.ms,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add),
              label: Text(context.tr('add_product')),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ).animate().fadeIn(
              delay: 600.ms,
              duration: 500.ms,
            ).scale(
              delay: 600.ms,
              duration: 500.ms,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          ],
        ],
      ),
    );
  }
}