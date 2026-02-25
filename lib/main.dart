import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/company_provider.dart';
import 'providers/client_provider.dart';
import 'providers/product_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';

// Theme
import 'core/theme/app_theme.dart';
import 'core/constants/strings.dart';
import 'core/localization/app_localizations.dart';

// Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/company/company_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/clients/clients_list_screen.dart';
import 'screens/clients/client_form_screen.dart';
import 'screens/clients/import_contacts_screen.dart';
import 'screens/products/products_list_screen.dart';
import 'screens/products/product_form_screen.dart';
import 'screens/quotes/quotes_list_screen.dart';
import 'screens/quotes/quote_form_screen.dart';
import 'screens/quotes/quote_preview_screen.dart';
import 'screens/settings/language_selection_screen.dart';
import 'screens/settings/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forcer le mode portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SenDevis());
}

class SenDevis extends StatelessWidget {
  const SenDevis({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) => MaterialApp(
          key: ValueKey(
            '${localeProvider.locale.languageCode}_${themeProvider.isDarkMode}',
          ),
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Localisation
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
            Locale('es', 'ES'),
          ],
          locale: localeProvider.locale,

          // Routes
          initialRoute: SplashScreen.routeName,
          routes: {
            SplashScreen.routeName: (context) => const SplashScreen(),
            LoginScreen.routeName: (context) => const LoginScreen(),
            RegisterScreen.routeName: (context) => const RegisterScreen(),
            HomeScreen.routeName: (context) => const HomeScreen(),
            CompanySettingsScreen.routeName: (context) =>
                const CompanySettingsScreen(),
            SettingsScreen.routeName: (context) => const SettingsScreen(),
            ClientsListScreen.routeName: (context) => const ClientsListScreen(),
            ClientFormScreen.routeName: (context) => const ClientFormScreen(),
            '/import-contacts': (context) => const ImportContactsScreen(),
            ProductsListScreen.routeName: (context) =>
                const ProductsListScreen(),
            ProductFormScreen.routeName: (context) => const ProductFormScreen(),
            QuotesListScreen.routeName: (context) => const QuotesListScreen(),
            QuoteFormScreen.routeName: (context) => const QuoteFormScreen(),
            QuotePreviewScreen.routeName: (context) =>
                const QuotePreviewScreen(),
            LanguageSelectionScreen.routeName: (context) =>
                const LanguageSelectionScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
          },
        ),
      ),
    );
  }
}
