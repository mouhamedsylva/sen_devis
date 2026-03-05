import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trash_provider.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../core/mixins/route_aware_mixin.dart';
import '../../widgets/custom_bottom_navbar.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RouteAwareMixin {
  @override
  String get routeName => SettingsScreen.routeName;
  
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId != null) {
      await Future.wait([
        context.read<CompanyProvider>().loadCompany(userId),
        context.read<TrashProvider>().loadTrash(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardTheme.color ?? const Color(0xFF2C2C2C) : Colors.white;
    final bgColor = theme.scaffoldBackgroundColor;
    final titleColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF1A3B5D));
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
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
            // Vérifier s'il y a une page précédente dans la pile
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Si pas de page précédente, aller à l'accueil
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: Text(
          context.tr('settings'),
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section profil
            Consumer<CompanyProvider>(
              builder: (context, companyProvider, child) {
                final companyName = companyProvider.company?.name ?? 'Mon Entreprise';
                return Container(
                  color: cardColor,
                  padding: const EdgeInsets.all(MobileConstants.spacingM),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.business, color: primaryColor, size: 30),
                      ),
                      const SizedBox(width: MobileConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: MobileConstants.fontSizeM,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('manage_account'),
                              style: TextStyle(
                                fontSize: MobileConstants.fontSizeS,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                  delay: 200.ms,
                  duration: 500.ms,
                ).slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 200.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                );
              },
            ),

            const SizedBox(height: MobileConstants.spacingS),

            _buildSectionHeader(context.tr('company_management'), bgColor, subtitleColor),
            Container(
              color: cardColor,
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.business_outlined,
                    title: context.tr('company_profile'),
                    primaryColor: primaryColor,
                    titleColor: titleColor,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pushNamed('/company-settings'),
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: 300.ms,
              duration: 500.ms,
            ).slideY(
              begin: 0.2,
              end: 0,
              delay: 300.ms,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

            const SizedBox(height: MobileConstants.spacingS),

            _buildSectionHeader(context.tr('preferences'), bgColor, subtitleColor),
            Container(
              color: cardColor,
              child: Column(
                children: [
                  Consumer<LocaleProvider>(
                    builder: (context, localeProvider, child) {
                      String languageName = context.tr('french');
                      if (localeProvider.locale.languageCode == 'en') {
                        languageName = context.tr('english');
                      } else if (localeProvider.locale.languageCode == 'es') {
                        languageName = context.tr('spanish');
                      }
                      return _buildMenuItem(
                        icon: Icons.language_outlined,
                        title: context.tr('language'),
                        primaryColor: primaryColor,
                        titleColor: titleColor,
                        isDark: isDark,
                        trailing: Text(
                          languageName,
                          style: TextStyle(
                            fontSize: MobileConstants.fontSizeS,
                            color: subtitleColor,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pushNamed(LanguageSelectionScreen.routeName),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildMenuItem(
                        icon: Icons.dark_mode_outlined,
                        title: context.tr('dark_mode'),
                        primaryColor: primaryColor,
                        titleColor: titleColor,
                        isDark: isDark,
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            MobileUtils.lightHaptic();
                            themeProvider.setDarkMode(value);
                          },
                          activeColor: primaryColor,
                        ),
                        onTap: null,
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: 400.ms,
              duration: 500.ms,
            ).slideY(
              begin: 0.2,
              end: 0,
              delay: 400.ms,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

            const SizedBox(height: MobileConstants.spacingS),

            _buildSectionHeader(context.tr('data_management'), bgColor, subtitleColor),
            Container(
              color: cardColor,
              child: Column(
                children: [
                  Consumer<TrashProvider>(
                    builder: (context, trashProvider, child) {
                      return _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: context.tr('trash'),
                        primaryColor: primaryColor,
                        titleColor: titleColor,
                        isDark: isDark,
                        trailing: trashProvider.count > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${trashProvider.count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pushNamed('/trash'),
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: 500.ms,
              duration: 500.ms,
            ).slideY(
              begin: 0.2,
              end: 0,
              delay: 500.ms,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

            const SizedBox(height: MobileConstants.spacingS),

            _buildSectionHeader(context.tr('security'), bgColor, subtitleColor),
            Container(
              color: cardColor,
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: context.tr('change_password'),
                    primaryColor: primaryColor,
                    titleColor: titleColor,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pushNamed('/change-password'),
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: 600.ms,
              duration: 500.ms,
            ).slideY(
              begin: 0.2,
              end: 0,
              delay: 600.ms,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

            const SizedBox(height: MobileConstants.spacingXl),

            // Bouton de déconnexion
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MobileConstants.spacingM,
              ),
              child: SizedBox(
                width: double.infinity,
                height: MobileConstants.minTouchTarget,
                child: TextButton.icon(
                  onPressed: _showSignOutDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: MobileConstants.spacingM,
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout,
                    color: Color(0xFFF44336),
                    size: 20,
                  ),
                  label: Text(
                    context.tr('logout'),
                    style: const TextStyle(
                      color: Color(0xFFF44336),
                      fontSize: MobileConstants.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(
              delay: 700.ms,
              duration: 500.ms,
            ).slideY(
              begin: 0.3,
              end: 0,
              delay: 700.ms,
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    MobileUtils.lightHaptic();
    setState(() { _selectedIndex = index; });
    switch (index) {
      case 0: Navigator.of(context).pushReplacementNamed('/home'); break;
      case 1: Navigator.of(context).pushReplacementNamed('/products'); break;
      case 2: Navigator.of(context).pushReplacementNamed('/quotes'); break;
      case 3: Navigator.of(context).pushReplacementNamed('/clients'); break;
      case 4: break;
    }
  }

  Widget _buildSectionHeader(String title, Color bgColor, Color? textColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(
        MobileConstants.spacingM,
        MobileConstants.spacingM,
        MobileConstants.spacingM,
        MobileConstants.spacingS,
      ),
      width: double.infinity,
      child: Text(
        title,
        style: TextStyle(
          fontSize: MobileConstants.fontSizeXs,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color primaryColor,
    required Color titleColor,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap != null ? () {
        MobileUtils.lightHaptic();
        onTap();
      } : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MobileConstants.spacingM,
          vertical: MobileConstants.spacingM,
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: MobileConstants.spacingM),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: MobileConstants.fontSizeM,
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
    );
  }

  void _showSignOutDialog() {
    MobileUtils.lightHaptic();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);
    
    // Obtenir la largeur de l'écran pour adapter le design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
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
                            onPressed: () async {
                              MobileUtils.mediumHaptic();
                              Navigator.of(ctx).pop();
                              
                              // Déconnexion
                              await context.read<AuthProvider>().logout();
                              
                              // Redirection vers l'écran de connexion
                              if (mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
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
                              Navigator.of(ctx).pop();
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
                        
                        // Bouton Déconnexion
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              MobileUtils.mediumHaptic();
                              Navigator.of(ctx).pop();
                              
                              // Déconnexion
                              await context.read<AuthProvider>().logout();
                              
                              // Redirection vers l'écran de connexion
                              if (mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
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
  }
}
