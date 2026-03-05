import 'package:devis/widgets/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../core/mixins/route_aware_mixin.dart';
import '../../widgets/loading_indicator.dart';
import 'client_form_screen.dart';
import 'client_detail_screen.dart';

class ClientsListScreen extends StatefulWidget {
  static const String routeName = '/clients';

  const ClientsListScreen({Key? key}) : super(key: key);

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> with RouteAwareMixin {
  @override
  String get routeName => ClientsListScreen.routeName;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 3; // Clients tab

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<ClientProvider>().loadClients(userId);
      }
    });
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      await context.read<ClientProvider>().loadClients(userId);
    }
  }

  void _navigateToAddClient() {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(ClientFormScreen.routeName);
  }

  void _navigateToEditClient(int clientId) {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(
      ClientFormScreen.routeName,
      arguments: {'clientId': clientId},
    );
  }

  Future<void> _deleteClient(int clientId) async {
    MobileUtils.mediumHaptic();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(context.tr('confirm')),
        content: Text(context.tr('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () {
              MobileUtils.lightHaptic();
              Navigator.of(context).pop(false);
            },
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              MobileUtils.mediumHaptic();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await context.read<ClientProvider>().deleteClient(clientId);

      if (!mounted) return;

      if (success) {
        MobileUtils.showMobileSnackBar(
          context,
          message: AppStrings.deleteSuccess,
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      } else {
        final errorMessage = context.read<ClientProvider>().errorMessage;
        MobileUtils.showMobileSnackBar(
          context,
          message: errorMessage ?? AppStrings.errorOccurred,
          backgroundColor: AppColors.error,
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

  void _showSortOptions() {
    MobileUtils.lightHaptic();
    final clientProvider = context.read<ClientProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Trier par',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSortTile(
                      context: context,
                      icon: Icons.sort_by_alpha,
                      label: 'Nom A → Z',
                      option: SortOption.nameAZ,
                      current: clientProvider.sortOption,
                      isDark: isDark,
                      onTap: () {
                        clientProvider.setSortOption(SortOption.nameAZ);
                        setState(() {});
                        Navigator.pop(context);
                      },
                    ),
                    _buildSortTile(
                      context: context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Date d\'ajout (plus récent)',
                      option: SortOption.dateAdded,
                      current: clientProvider.sortOption,
                      isDark: isDark,
                      onTap: () {
                        clientProvider.setSortOption(SortOption.dateAdded);
                        setState(() {});
                        Navigator.pop(context);
                      },
                    ),
                    _buildSortTile(
                      context: context,
                      icon: Icons.description_outlined,
                      label: 'Nombre de devis (décroissant)',
                      option: SortOption.quoteCount,
                      current: clientProvider.sortOption,
                      isDark: isDark,
                      onTap: () {
                        clientProvider.setSortOption(SortOption.quoteCount);
                        setState(() {});
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required SortOption option,
    required SortOption current,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = current == option;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white : Colors.black87),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    MobileUtils.lightHaptic();
    setState(() {
      _selectedIndex = index;
    });

    // Navigation based on bottom nav selection
    switch (index) {
      case 0: // Dashboard
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // Products
        Navigator.of(context).pushReplacementNamed('/products');
        break;
      case 2: // Quotes
        Navigator.of(context).pushReplacementNamed('/quotes');
        break;
      case 3: // Clients - already here
        break;
      case 4: // Settings
        Navigator.of(context).pushReplacementNamed('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A3B5D);
    final primaryColor = th.primaryColor;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: th.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0D7C7E),
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
        centerTitle: true,
        title: Text(
          context.tr('clients'),
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Bouton tri
          IconButton(
            onPressed: () {
              MobileUtils.lightHaptic();
              _showSortOptions();
            },
            icon: Icon(Icons.filter_list_rounded, color: primaryColor),
            tooltip: 'Trier',
          ),
          IconButton(
            onPressed: () async {
              MobileUtils.lightHaptic();
              final result = await Navigator.of(context).pushNamed(
                '/import-contacts',
              );
              if (result == true) {
                final authProvider = context.read<AuthProvider>();
                final userId = authProvider.userId;
                if (userId != null) {
                  context.read<ClientProvider>().loadClients(userId);
                }
              }
            },
            icon: const Icon(Icons.file_upload_outlined),
            color: primaryColor,
            tooltip: context.tr('import_contacts'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),

          // Compteur de clients
          Consumer<ClientProvider>(
            builder: (context, clientProvider, child) {
              final count = _searchQuery.isEmpty
                  ? clientProvider.clients.length
                  : clientProvider.searchClients(_searchQuery).length;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: surfaceColor,
                child: Text(
                  '$count client(s)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),

          // Liste des clients
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, clientProvider, child) {
                if (clientProvider.isLoading) {
                  return const Center(child: LoadingIndicator());
                }

                final clients = _searchQuery.isEmpty
                    ? clientProvider.clients
                    : clientProvider.searchClients(_searchQuery);

                if (clients.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _loadClients,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return _buildClientCard(client, index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          // Masquer le bouton flottant s'il n'y a pas de clients
          if (clientProvider.clients.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: _navigateToAddClient,
            backgroundColor: primaryColor,
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  Widget _buildSearchBar() {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA);
    final primaryColor = th.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: cardColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.tr('search_client'),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ).fadeIn(
            duration: 400.ms,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? context.tr('no_clients')
                : context.tr('no_client_found'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
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
            _searchQuery.isEmpty
                ? context.tr('add_first_client')
                : context.tr('try_another_search'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddClient,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                context.tr('add_client'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A7B7B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ).animate().fadeIn(
              delay: 600.ms,
              duration: 400.ms,
            ).scale(
              delay: 600.ms,
              duration: 400.ms,
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              curve: Curves.easeOutBack,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(client, int index) {
    // Générer les initiales
    final nameParts = client.name.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : client.name.substring(0, 2).toUpperCase();

    // Générer une couleur basée sur les initiales
    final colors = [
      const Color(0xFF1A7B7B),
      const Color(0xFF2E7D32),
      const Color(0xFF1976D2),
      const Color(0xFF7B1FA2),
      const Color(0xFFC62828),
      const Color(0xFFEF6C00),
    ];
    final colorIndex = (initials.codeUnitAt(0) + initials.codeUnitAt(1)) % colors.length;

    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec avatar et nom
            Row(
              children: [
                // Avatar avec initiales
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors[colorIndex].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: colors[colorIndex],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ).animate().scale(
                  delay: Duration(milliseconds: 50 * index),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ).shimmer(
                  delay: Duration(milliseconds: 50 * index + 200),
                  duration: 800.ms,
                  color: colors[colorIndex].withOpacity(0.3),
                ),
                const SizedBox(width: 12),
                
                // Nom et rôle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('main_contact'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Email
            if (client.email != null && client.email!.isNotEmpty)
              _buildInfoRow(
                Icons.email_outlined,
                client.email!,
              ),

            // Téléphone
            if (client.phone != null && client.phone!.isNotEmpty)
              _buildInfoRow(
                Icons.phone_outlined,
                client.phone!,
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  label: context.tr('view'),
                  color: const Color(0xFF1A7B7B),
                  onTap: () {
                    MobileUtils.lightHaptic();
                    Navigator.of(context).pushNamed(
                      ClientDetailScreen.routeName,
                      arguments: {'clientId': client.id},
                    ).then((_) => _loadClients());
                  },
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey.shade300,
                ),
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: context.tr('edit'),
                  color: const Color(0xFF1A7B7B),
                  onTap: () => _navigateToEditClient(client.id!),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color.fromARGB(255, 106, 60, 60),
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: context.tr('delete'),
                  color: AppColors.error,
                  onTap: () => _deleteClient(client.id!),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 50 * index),
      duration: 400.ms,
    ).slideY(
      begin: 0.2,
      end: 0,
      delay: Duration(milliseconds: 50 * index),
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildInfoRow(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}