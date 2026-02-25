import 'package:devis/screens/clients/client_form_screen.dart';
import 'package:devis/screens/products/product_form_screen.dart';
import 'package:devis/widgets/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/localization/localization_extension.dart';
import '../../data/database/app_database.dart';
import '../../data/models/model_extensions.dart';
import '../../widgets/connectivity_banner.dart';
import '../auth/login_screen.dart';
import '../company/company_settings_screen.dart';
import '../clients/clients_list_screen.dart';
import '../products/products_list_screen.dart';
import '../quotes/quotes_list_screen.dart';
import '../quotes/quote_form_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    
    // Charger les données après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      await context.read<CompanyProvider>().loadCompany(userId);
      await context.read<QuoteProvider>().loadQuotes(userId);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          context.tr('logout'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(context.tr('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  void _navigateToNewQuote() {
    Navigator.of(context).pushNamed(QuoteFormScreen.routeName);
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Dashboard - déjà sur home
        break;
      case 1:
        Navigator.of(context).pushNamed(ProductsListScreen.routeName);
        break;
      case 2:
        Navigator.of(context).pushNamed(QuotesListScreen.routeName);
        break;
      case 3:
        Navigator.of(context).pushNamed(ClientsListScreen.routeName);
        break;
      case 4:
        Navigator.of(context).pushNamed('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ConnectivityBanner(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar
            _buildSliverAppBar(),
            
            // Content
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF1A7B7B),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      // _buildWelcomeSection(),
                      // const SizedBox(height: 24),

                      // Quick Stats Grid
                      _buildQuickStats(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 28),

                      // Recent Activity
                      _buildRecentActivity(),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // floatingActionButton: _buildModernFAB(),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onNavItemTapped,
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A7B7B),
      automaticallyImplyLeading: false, // Supprime la flèche de retour
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A7B7B),
                Color(0xFF156666),
                Color(0xFF115252),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SenDevis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            context.tr('app_subtitle'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildProfileButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.green.shade300,
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  // Widget _buildWelcomeSection() {
  //   return Consumer<AuthProvider>(
  //     builder: (context, authProvider, child) {
  //       final hour = DateTime.now().hour;
  //       String greeting;
  //       if (hour < 12) {
  //         greeting = 'Bonjour';
  //       } else if (hour < 17) {
  //         greeting = 'Bon après-midi';
  //       } else {
  //         greeting = 'Bonsoir';
  //       }

  //       return Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             greeting,
  //             style: TextStyle(
  //               fontSize: 16,
  //               color: Colors.grey.shade600,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //           const SizedBox(height: 4),
  //           const Text(
  //             'Tableau de bord',
  //             style: TextStyle(
  //               fontSize: 28,
  //               fontWeight: FontWeight.bold,
  //               color: Color(0xFF1A1A1A),
  //               letterSpacing: -0.5,
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildQuickStats() {
    return Consumer<QuoteProvider>(
      builder: (context, quoteProvider, child) {
        final allQuotes = quoteProvider.quotes;
        final totalQuotes = allQuotes.length;
        final draftQuotes = allQuotes.where((q) => q.status == 'draft').length;
        final sentQuotes = allQuotes.where((q) => q.status == 'sent').length;
        final acceptedQuotes = allQuotes.where((q) => q.status == 'accepted').length;
        
        final totalRevenue = allQuotes
            .where((q) => q.status == 'accepted')
            .fold<double>(0, (sum, quote) => sum + quote.totalTTC);

        final growthPercentage = totalQuotes > 0 ? 12 : 0;

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            _buildModernStatCard(
              title: context.tr('total_quotes'),
              value: totalQuotes.toString(),
              icon: Icons.description_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A7B7B), Color(0xFF156666)],
              ),
              showGrowth: true,
              growthPercentage: growthPercentage,
              delay: 0,
            ),
            // _buildModernStatCard(
            //   title: context.tr('pending'),
            //   value: (draftQuotes + sentQuotes).toString(),
            //   icon: Icons.pending_actions_rounded,
            //   gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: [Colors.orange.shade400, Colors.orange.shade600],
            //   ),
            //   delay: 100,
            // ),
            // _buildModernStatCard(
            //   title: context.tr('accepted'),
            //   value: acceptedQuotes.toString(),
            //   icon: Icons.check_circle_rounded,
            //   gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: [Colors.green.shade400, Colors.green.shade600],
            //   ),
            //   delay: 200,
            // ),
            _buildModernStatCard(
              title: context.tr('revenue'),
              value: _formatRevenue(totalRevenue),
              icon: Icons.payments_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A7B7B), Color(0xFF115252)],
              ),
              isRevenue: true,
              delay: 300,
            ),
          ],
        );
      },
    );
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    bool showGrowth = false,
    int growthPercentage = 0,
    bool isRevenue = false,
    int delay = 0,
  }) {
    // Extraire la couleur principale du gradient pour l'icône
    final iconColor = gradient.colors.first;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

        return Transform.scale(
          scale: animValue,
          child: Opacity(
            opacity: animValue,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: iconColor.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    top: -15,
                    right: -15,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withOpacity(0.03),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withOpacity(0.02),
                      ),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (showGrowth)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.green.shade600,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$growthPercentage%',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 0),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(
                                    fontSize: isRevenue ? 22 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('quick_actions'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        // Première ligne : Créer client
        _buildActionButton(
          title: context.tr('add_client'),
          icon: Icons.person_add_rounded,
          color: const Color(0xFF1A7B7B),
          onTap: () {
            Navigator.of(context).pushNamed(ClientFormScreen.routeName);
          },
        ),
        const SizedBox(height: 12),
        // Deuxième ligne : Créer produit
        _buildActionButton(
          title: context.tr('add_product'),
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF1A7B7B),
          onTap: () {
            Navigator.of(context).pushNamed(ProductFormScreen.routeName);
          },
        ),
        const SizedBox(height: 12),
        // Troisième ligne : Générer un devis
        _buildActionButton(
          title: context.tr('generate_quote'), // Vous devrez peut-être ajouter cette clé de traduction
          icon: Icons.receipt_rounded,
          color: const Color(0xFF1A7B7B),
          onTap: _navigateToNewQuote,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      width: double.infinity, // Prend toute la largeur disponible
      height: 70,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Aligné à gauche
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Petite flèche pour indiquer l'action
                Icon(
                  Icons.arrow_forward_rounded,
                  color: color.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<QuoteProvider>(
      builder: (context, quoteProvider, child) {
        final recentQuotes = quoteProvider.quotesWithClients.take(5).toList();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('recent_activity'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(QuotesListScreen.routeName);
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(context.tr('see_all')),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A7B7B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentQuotes.isEmpty)
              _buildEmptyActivity()
            else
              ...recentQuotes.asMap().entries.map((entry) {
                return _buildActivityItem(entry.value, entry.key);
              }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(48.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A7B7B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 56,
                color: const Color(0xFF1A7B7B).withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('no_quotes'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('create_first_quote'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(QuoteWithClient quoteWithClient, int index) {
    final quote = quoteWithClient.quote;
    final client = quoteWithClient.client;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (quote.status) {
      case 'draft':
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.edit_note_rounded;
        statusText = 'Brouillon créé';
        break;
      case 'sent':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.send_rounded;
        statusText = 'Devis envoyé';
        break;
      case 'accepted':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Devis accepté';
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.description_rounded;
        statusText = 'Devis créé';
    }

    final now = DateTime.now();
    final difference = now.difference(quote.createdAt);
    String timeAgo;
    
    if (difference.inDays > 0) {
      timeAgo = difference.inDays == 1 ? 'Hier' : 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      timeAgo = 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      timeAgo = 'Il y a ${difference.inMinutes}m';
    } else {
      timeAgo = 'À l\'instant';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      QuoteFormScreen.routeName,
                      arguments: {'quoteId': quote.id},
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statusColor.withOpacity(0.15),
                                statusColor.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      client?.name ?? 'Client inconnu',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(quote.totalTTC),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A7B7B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${quote.quoteNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildModernFAB() {
  //   return Container(
  //     width: 64,
  //     height: 64,
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Color(0xFF1A7B7B),
  //           Color(0xFF115252),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF1A7B7B).withOpacity(0.4),
  //           blurRadius: 20,
  //           offset: const Offset(0, 10),
  //         ),
  //       ],
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         onTap: _navigateToNewQuote,
  //         borderRadius: BorderRadius.circular(20),
  //         child: const Center(
  //           child: Icon(
  //             Icons.add_rounded,
  //             size: 34,
  //             color: Colors.white,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}