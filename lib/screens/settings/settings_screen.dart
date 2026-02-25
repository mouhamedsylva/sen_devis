import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../widgets/custom_bottom_navbar.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanyData();
    });
  }

  Future<void> _loadCompanyData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId != null) {
      await context.read<CompanyProvider>().loadCompany(userId);
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
        title: Text(
          context.tr('settings'),
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
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
                child: TextButton(
                  onPressed: _showSignOutDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: MobileConstants.spacingM,
                    ),
                  ),
                  child: Text(
                    context.tr('logout'),
                    style: const TextStyle(
                      color: Color(0xFFF44336),
                      fontSize: MobileConstants.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () {
              MobileUtils.lightHaptic();
              Navigator.of(ctx).pop();
            },
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              MobileUtils.mediumHaptic();
              Navigator.of(ctx).pop();
            },
            child: Text(
              context.tr('logout'),
              style: const TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }
}
