import 'package:devis/screens/clients/client_form_screen.dart';
import 'package:devis/screens/products/product_form_screen.dart';
import 'package:devis/widgets/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/localization/localization_extension.dart';
import '../../core/mixins/route_aware_mixin.dart';
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

class _HomeScreenState extends State<HomeScreen> 
    with SingleTickerProviderStateMixin, RouteAwareMixin {
  @override
  String get routeName => HomeScreen.routeName;
  
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    // Animation en boucle avec effet de pulsation
    _animationController.repeat(reverse: true);
    
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    
    // Obtenir la largeur de l'écran pour adapter le design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    final confirm = await showDialog<bool>(
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
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: const Color(0xFFEF4444),
                    size: isSmallScreen ? 28 : 32,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Titre
                Text(
                  context.tr('logout'),
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
                  context.tr('confirm_logout'),
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
                          // Bouton Déconnexion (en premier pour l'action principale)
                          ElevatedButton(
                            onPressed: () {
                              MobileUtils.mediumHaptic();
                              Navigator.of(context).pop(true);
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
                              context.tr('logout'),
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
                              AppStrings.cancel,
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
                              AppStrings.cancel,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Bouton Déconnexion
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              MobileUtils.mediumHaptic();
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
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
                              context.tr('logout'),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
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
      onTap: () {
        MobileUtils.lightHaptic();
        _handleLogout();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Animation de pulsation (scale)
          final scale = 1.0 + (0.05 * (0.5 + 0.5 * _animationController.value));
          
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3 + (0.2 * _animationController.value)),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12 + (4 * _animationController.value),
                    offset: const Offset(0, 4),
                  ),
                  // Glow effect
                  BoxShadow(
                    color: Colors.green.shade300.withOpacity(0.3 * _animationController.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1A7B7B),
                  size: 26,
                ),
              ),
            ),
          );
        },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
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
                    ).animate().scale(
                      delay: Duration(milliseconds: delay),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ).shimmer(
                      delay: Duration(milliseconds: delay + 300),
                      duration: 1200.ms,
                      color: Colors.white.withOpacity(0.3),
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
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: delay + 400),
                        duration: 400.ms,
                      ).slideX(
                        begin: 0.3,
                        end: 0,
                        delay: Duration(milliseconds: delay + 400),
                        duration: 400.ms,
                        curve: Curves.easeOut,
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
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: delay + 200),
                        duration: 400.ms,
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
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: delay + 300),
                        duration: 600.ms,
                      ).slideY(
                        begin: 0.5,
                        end: 0,
                        delay: Duration(milliseconds: delay + 300),
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(
      delay: Duration(milliseconds: delay),
      duration: 600.ms,
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.0, 1.0),
      curve: Curves.easeOutCubic,
    ).fadeIn(
      delay: Duration(milliseconds: delay),
      duration: 400.ms,
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
        ).animate().fadeIn(
          duration: 400.ms,
        ).slideX(
          begin: -0.2,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 16),
        // Première ligne : Créer client
        _buildActionButton(
          title: context.tr('add_client'),
          icon: Icons.person_add_rounded,
          color: const Color(0xFF1A7B7B),
          onTap: () async {
            // Attendre le retour du formulaire de création
            await Navigator.of(context).pushNamed(ClientFormScreen.routeName);
            // Après création, rediriger vers la liste des clients
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(ClientsListScreen.routeName);
            }
          },
        ),
        const SizedBox(height: 12),
        // Deuxième ligne : Créer produit
        _buildActionButton(
          title: context.tr('add_product'),
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF1A7B7B),
          onTap: () async {
            await Navigator.of(context).pushNamed(ProductFormScreen.routeName);

            if (mounted) {
              Navigator.of(context).pushReplacementNamed(ProductsListScreen.routeName);
            }
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

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      closedColor: cardBg,
      openColor: cardBg,
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (context, action) => Container(
        width: double.infinity,
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
            onTap: () {
              MobileUtils.lightHaptic();
              onTap();
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).shimmer(
                    delay: 2000.ms,
                    duration: 1500.ms,
                    color: color.withOpacity(0.3),
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
      ).animate().fadeIn(
        duration: 400.ms,
      ).slideX(
        begin: -0.2,
        end: 0,
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      ),
      openBuilder: (context, action) => const SizedBox.shrink(),
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
                ).animate().fadeIn(
                  duration: 400.ms,
                ).slideX(
                  begin: -0.2,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
                // Bouton "Voir tout" amélioré
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      MobileUtils.lightHaptic();
                      Navigator.of(context).pushNamed(QuotesListScreen.routeName);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A7B7B),
                            const Color(0xFF156666),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A7B7B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('see_all'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(
                  delay: 200.ms,
                  duration: 400.ms,
                ).scale(
                  delay: 200.ms,
                  duration: 400.ms,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
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
    String actionDescription;
    
    switch (quote.status) {
      case 'draft':
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.edit_note_rounded;
        statusText = 'Brouillon';
        actionDescription = 'Devis en cours de rédaction';
        break;
      case 'sent':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.send_rounded;
        statusText = 'Envoyé';
        actionDescription = 'Devis envoyé au client';
        break;
      case 'accepted':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Accepté';
        actionDescription = 'Devis accepté par le client';
        break;
      case 'rejected':
        statusColor = const Color(0xFFF44336);
        statusIcon = Icons.cancel_rounded;
        statusText = 'Refusé';
        actionDescription = 'Devis refusé par le client';
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.description_rounded;
        statusText = 'Créé';
        actionDescription = 'Nouveau devis créé';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
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
            MobileUtils.lightHaptic();
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
                ).animate().scale(
                  delay: Duration(milliseconds: 100 * index),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ).shimmer(
                  delay: Duration(milliseconds: 100 * index + 300),
                  duration: 1000.ms,
                  color: statusColor.withOpacity(0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre principal avec le nom du client
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Devis pour ${client?.name ?? 'Client inconnu'}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Description de l'action
                      Text(
                        actionDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Ligne avec statut, montant et temps
                      Row(
                        children: [
                          // Badge de statut
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Séparateur
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Montant
                          Text(
                            CurrencyFormatter.format(quote.totalTTC),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A7B7B),
                            ),
                          ),
                          const Spacer(),
                          // Temps
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Numéro de devis à droite
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${quote.quoteNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: 500.ms,
    ).slideY(
      begin: 0.3,
      end: 0,
      delay: Duration(milliseconds: 100 * index),
      duration: 500.ms,
      curve: Curves.easeOutCubic,
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