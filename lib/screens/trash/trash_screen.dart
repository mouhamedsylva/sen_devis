import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/trash_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';

class TrashScreen extends StatefulWidget {
  static const String routeName = '/trash';
  
  const TrashScreen({Key? key}) : super(key: key);

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterType = 'all'; // 'all', 'quote', 'product'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _filterType = 'all';
            break;
          case 1:
            _filterType = 'quote';
            break;
          case 2:
            _filterType = 'product';
            break;
        }
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrash();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrash() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId != null) {
      await context.read<TrashProvider>().loadTrash(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardTheme.color ?? const Color(0xFF2C2C2C) : Colors.white;
    final bgColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0D7C7E),
            size: 20,
          ),
          onPressed: () {
            MobileUtils.lightHaptic();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          context.tr('trash'),
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<TrashProvider>(
            builder: (context, trashProvider, child) {
              if (trashProvider.isEmpty) return const SizedBox.shrink();
              
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: primaryColor),
                onSelected: (value) {
                  if (value == 'empty') {
                    _showEmptyTrashDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'empty',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text(context.tr('empty_trash')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: [
            Tab(text: context.tr('all')),
            Tab(text: context.tr('quotes')),
            Tab(text: context.tr('products')),
          ],
        ),
      ),
      body: Consumer<TrashProvider>(
        builder: (context, trashProvider, child) {
          if (trashProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (trashProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    trashProvider.errorMessage!,
                    style: TextStyle(color: Colors.red[300]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTrash,
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            );
          }

          final items = _filterType == 'all'
              ? trashProvider.trashItems
              : trashProvider.filterByType(_filterType);

          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.delete_outline,
              message: '${context.tr('trash_empty')}\n${context.tr('trash_empty_subtitle')}',
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            ).fadeIn(
              duration: 400.ms,
            ).shimmer(
              delay: 600.ms,
              duration: 1200.ms,
              color: Colors.grey.shade300.withOpacity(0.3),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadTrash,
            child: ListView.builder(
              padding: const EdgeInsets.all(MobileConstants.spacingM),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildTrashItem(item, isDark, cardColor, primaryColor, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrashItem(TrashItem item, bool isDark, Color cardColor, Color primaryColor, int index) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A3B5D);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    
    IconData icon;
    Color iconColor;
    
    if (item.type == 'quote') {
      icon = Icons.description_outlined;
      iconColor = Colors.blue;
    } else {
      icon = Icons.inventory_2_outlined;
      iconColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: MobileConstants.spacingM),
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MobileConstants.spacingM),
        child: Row(
          children: [
            // Icône
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: MobileConstants.spacingM),
            
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: MobileConstants.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: MobileConstants.fontSizeS,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Restaurer
                IconButton(
                  icon: const Icon(Icons.restore, size: 20),
                  color: Colors.green,
                  onPressed: () => _showRestoreDialog(item),
                  tooltip: context.tr('restore'),
                ),
                
                // Supprimer définitivement
                IconButton(
                  icon: const Icon(Icons.delete_forever, size: 20),
                  color: Colors.red,
                  onPressed: () => _showPermanentDeleteDialog(item),
                  tooltip: context.tr('delete_permanently'),
                ),
              ],
            ),
          ],
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

  void _showRestoreDialog(TrashItem item) {
    MobileUtils.lightHaptic();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restore, color: Color(0xFF16A34A), size: 32),
              ),
              const SizedBox(height: 20),
              
              Text(
                context.tr('restore_item'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                context.tr('restore_item_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        MobileUtils.lightHaptic();
                        Navigator.of(ctx).pop();
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
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        MobileUtils.mediumHaptic();
                        Navigator.of(ctx).pop();
                        
                        final success = await context.read<TrashProvider>().restoreItem(item);
                        
                        if (success && context.mounted) {
                          // Recharger les données dans les providers concernés
                          final authProvider = context.read<AuthProvider>();
                          final userId = authProvider.userId;
                          if (userId != null) {
                            if (item.type == 'quote') {
                              await context.read<QuoteProvider>().loadQuotes(userId);
                            } else if (item.type == 'product') {
                              await context.read<ProductProvider>().loadProducts(userId);
                            }
                          }
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('item_restored')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('restore'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }

  void _showPermanentDeleteDialog(TrashItem item) {
    MobileUtils.lightHaptic();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 20),
              
              Text(
                context.tr('delete_permanently'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                context.tr('delete_permanently_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        MobileUtils.lightHaptic();
                        Navigator.of(ctx).pop();
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
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        MobileUtils.mediumHaptic();
                        Navigator.of(ctx).pop();
                        
                        final success = await context.read<TrashProvider>().permanentlyDeleteItem(item);
                        
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('item_deleted_permanently')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('delete'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }

  void _showEmptyTrashDialog() {
    MobileUtils.lightHaptic();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 20),
              
              Text(
                context.tr('empty_trash'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                context.tr('empty_trash_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        MobileUtils.lightHaptic();
                        Navigator.of(ctx).pop();
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
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        MobileUtils.mediumHaptic();
                        Navigator.of(ctx).pop();
                        
                        final success = await context.read<TrashProvider>().emptyTrash();
                        
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('trash_emptied')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('empty'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }
}
