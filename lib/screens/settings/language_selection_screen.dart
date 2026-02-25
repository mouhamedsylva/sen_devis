import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/localization/localization_extension.dart';

class LanguageSelectionScreen extends StatelessWidget {
  static const String routeName = '/language-selection';

  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('language'),
          style: TextStyle(
            color: titleColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return ListView(
            children: [
              const SizedBox(height: 8),
              _buildLanguageOption(context, localeProvider, context.tr('french'), 'French', const Locale('fr', 'FR'), '🇫🇷', cardColor, titleColor, primaryColor, isDark),
              _buildDivider(isDark),
              _buildLanguageOption(context, localeProvider, context.tr('english'), 'Anglais', const Locale('en', 'US'), '🇬🇧', cardColor, titleColor, primaryColor, isDark),
              _buildDivider(isDark),
              _buildLanguageOption(context, localeProvider, context.tr('spanish'), 'Espagnol', const Locale('es', 'ES'), '🇪🇸', cardColor, titleColor, primaryColor, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LocaleProvider localeProvider,
    String title,
    String subtitle,
    Locale locale,
    String flag,
    Color cardColor,
    Color titleColor,
    Color primaryColor,
    bool isDark,
  ) {
    final isSelected = localeProvider.locale == locale;

    return Container(
      color: cardColor,
      child: InkWell(
        onTap: () async {
          await localeProvider.setLocale(locale);
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
    );
  }
}
