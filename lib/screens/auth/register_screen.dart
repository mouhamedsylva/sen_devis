import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/senegal_phone_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/mobile_button.dart';
import '../../widgets/mobile_text_field.dart';
import '../company/company_settings_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.register(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      companyName: _companyController.text.trim(), // ✅ Passer le nom de l'entreprise
    );

    if (!mounted) return;

    if (success) {
      // Afficher le dialogue de succès avec fermeture automatique
      await SuccessDialog.show(
        context: context,
        title: 'Inscription réussie !',
        message: 'Votre compte a été créé avec succès. Vous pouvez maintenant compléter les informations de votre entreprise.',
        autoDismiss: true,
        autoDismissDuration: const Duration(seconds: 2),
        onConfirm: () {
          // Navigation vers la configuration de l'entreprise avec les données pré-remplies
          Navigator.of(context).pushReplacementNamed(
            CompanySettingsScreen.routeName,
            arguments: {
              'isFirstSetup': true,
              'companyName': _companyController.text.trim(),
              'companyPhone': _phoneController.text.trim(),
            },
          );
        },
      );
    } else {
      // Afficher l'erreur
      MobileUtils.showMobileSnackBar(
        context,
        message: authProvider.errorMessage ?? AppStrings.errorOccurred,
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
      );
    }
  }

  void _navigateBack() {
    MobileUtils.lightHaptic();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final scaffoldBg = isDark ? th.scaffoldBackgroundColor : const Color(0xFFF6F8F8);
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Decorative background circles
          if (!isDark) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5C63).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5C63).withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          // Main content
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return const Center(child: LoadingIndicator());
                    }

                    return Column(
                      children: [
                        // Top App Bar
                        _buildAppBar(),
                        
                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom: keyboardVisible ? 20 : 0,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 40),
                                    
                                    // Logo and title
                                    _buildHeader(),
                                    const SizedBox(height: 40),
                                    
                                    // Registration form
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _buildCompanyField().animate().fadeIn(
                                            delay: 500.ms,
                                            duration: 500.ms,
                                          ).slideY(
                                            begin: 0.2,
                                            end: 0,
                                            delay: 500.ms,
                                            duration: 500.ms,
                                            curve: Curves.easeOutCubic,
                                          ),
                                          const SizedBox(height: MobileConstants.spacingL),
                                          _buildPhoneField().animate().fadeIn(
                                            delay: 600.ms,
                                            duration: 500.ms,
                                          ).slideY(
                                            begin: 0.2,
                                            end: 0,
                                            delay: 600.ms,
                                            duration: 500.ms,
                                            curve: Curves.easeOutCubic,
                                          ),
                                          const SizedBox(height: MobileConstants.spacingL),
                                          _buildPasswordField().animate().fadeIn(
                                            delay: 700.ms,
                                            duration: 500.ms,
                                          ).slideY(
                                            begin: 0.2,
                                            end: 0,
                                            delay: 700.ms,
                                            duration: 500.ms,
                                            curve: Curves.easeOutCubic,
                                          ),
                                          const SizedBox(height: MobileConstants.spacingL),
                                          _buildConfirmPasswordField().animate().fadeIn(
                                            delay: 800.ms,
                                            duration: 500.ms,
                                          ).slideY(
                                            begin: 0.2,
                                            end: 0,
                                            delay: 800.ms,
                                            duration: 500.ms,
                                            curve: Curves.easeOutCubic,
                                          ),
                                          const SizedBox(height: MobileConstants.spacingXl),
                                          _buildRegisterButton().animate().fadeIn(
                                            delay: 900.ms,
                                            duration: 500.ms,
                                          ).scale(
                                            delay: 900.ms,
                                            duration: 500.ms,
                                            begin: const Offset(0.9, 0.9),
                                            end: const Offset(1.0, 1.0),
                                            curve: Curves.easeOutBack,
                                          ),
                                          const SizedBox(height: 16),
                                          _buildTermsText().animate().fadeIn(
                                            delay: 1000.ms,
                                            duration: 500.ms,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Login link
                                    _buildLoginLink(),
                                    
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _navigateBack,
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
            ),
          ),
          Expanded(
            child: Text(
              'Inscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0D5C63).withOpacity(0.20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Color(0xFF0D5C63),
          ),
        ).animate().scale(
          duration: 600.ms,
          curve: Curves.elasticOut,
        ).shimmer(
          delay: 400.ms,
          duration: 1200.ms,
          color: const Color(0xFF0D5C63).withOpacity(0.3),
        ),
        const SizedBox(height: 24),
        Text(
          'Développez votre entreprise',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          delay: 200.ms,
          duration: 600.ms,
        ).slideY(
          begin: 0.3,
          end: 0,
          delay: 200.ms,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Gérez vos devis, factures et dépenses en quelques minutes.',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF0D5C63).withOpacity(0.70),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(
          delay: 400.ms,
          duration: 600.ms,
        ).slideY(
          begin: 0.3,
          end: 0,
          delay: 400.ms,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  Widget _buildCompanyField() {
    return MobileTextField(
      controller: _companyController,
      label: 'Nom de l\'entreprise',
      hint: 'ex. Acme Corp',
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer le nom de votre entreprise';
        }
        return null;
      },
    );
  }

  // Widget _buildNameField() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Padding(
  //         padding: EdgeInsets.only(left: 4, bottom: 8),
  //         child: Text(
  //           'Nom complet',
  //           style: TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w600,
  //             color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : const Color(0xFF334155),
  //           ),
  //         ),
  //       ),
  //       SizedBox(
  //         height: 56,
  //         child: TextFormField(
  //           controller: _nameController,
  //           cursorColor: const Color(0xFF0D5C63),
  //           style: const TextStyle(
  //             fontSize: 16,
  //             color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
  //           ),
  //           decoration: InputDecoration(
  //             hintText: 'ex. Jane Smith',
  //             hintStyle: TextStyle(
  //               color: Colors.grey.shade400,
  //               fontSize: 15,
  //             ),
  //             filled: true,
  //             fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
  //             contentPadding: const EdgeInsets.symmetric(
  //               horizontal: 16,
  //               vertical: 16,
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(
  //                 color: Colors.grey.shade300,
  //                 width: 1.5,
  //               ),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: const BorderSide(
  //                 color: Color(0xFF0D5C63),
  //                 width: 2,
  //               ),
  //             ),
  //             errorBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: const BorderSide(
  //                 color: Color(0xFFEF4444),
  //                 width: 1.5,
  //               ),
  //             ),
  //             focusedErrorBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: const BorderSide(
  //                 color: Color(0xFFEF4444),
  //                 width: 2,
  //               ),
  //             ),
  //             errorStyle: const TextStyle(
  //               color: Color(0xFFEF4444),
  //               fontSize: 12,
  //               height: 1.5,
  //             ),
  //           ),
  //           validator: (value) {
  //             if (value == null || value.isEmpty) {
  //               return 'Veuillez entrer votre nom complet';
  //             }
  //             return null;
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildPhoneField() {
    // Note: MobileTextField ne supporte pas inputFormatters directement
    // On garde le TextFormField pour le formatter mais on utilise le style mobile
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: MobileConstants.fontSizeS,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: MobileConstants.spacingS),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [SenegalPhoneFormatter()],
          style: TextStyle(fontSize: MobileConstants.fontSizeM),
          decoration: InputDecoration(
            hintText: 'XX XXX XX XX',
            hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade600 
                  : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade900 
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MobileConstants.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MobileConstants.radiusM),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MobileConstants.radiusM),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MobileConstants.radiusM),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MobileConstants.spacingM,
              vertical: MobileConstants.spacingM,
            ),
          ),
          validator: (value) {
            if (!SenegalPhoneFormatter.isValid(value)) {
              return 'Numéro de téléphone invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return MobileTextField(
      controller: _passwordController,
      label: 'Mot de passe',
      hint: '••••••••',
      obscureText: _obscurePassword,
      validator: Validators.password,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          size: 22,
        ),
        onPressed: () {
          MobileUtils.lightHaptic();
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return MobileTextField(
      controller: _confirmPasswordController,
      label: 'Confirmer le mot de passe',
      hint: '••••••••',
      obscureText: _obscureConfirmPassword,
      validator: (value) => Validators.confirmPassword(
        value,
        _passwordController.text,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          size: 22,
        ),
        onPressed: () {
          MobileUtils.lightHaptic();
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
      ),
    );
  }

  Widget _buildRegisterButton() {
    return MobileButton(
      text: 'Créer mon compte',
      onPressed: _handleRegister,
      icon: Icons.arrow_forward,
      backgroundColor: const Color(0xFF0D5C63),
      height: MobileConstants.recommendedTouchTarget,
    );
  }

  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          children: const [
            TextSpan(text: 'En vous inscrivant, vous acceptez nos '),
            TextSpan(
              text: 'Conditions d\'utilisation',
              style: TextStyle(
                color: Color(0xFF0D5C63),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: ' et notre '),
            TextSpan(
              text: 'Politique de confidentialité',
              style: TextStyle(
                color: Color(0xFF0D5C63),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Vous avez déjà un compte ? ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          TextButton(
            onPressed: () {
              MobileUtils.lightHaptic();
              _navigateBack();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: MobileConstants.spacingM, 
                horizontal: MobileConstants.spacingS,
              ),
              minimumSize: const Size(0, MobileConstants.minTouchTarget),
            ),
            child: const Text(
              'Se connecter',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D5C63),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: 1100.ms,
      duration: 500.ms,
    ).slideY(
      begin: 0.2,
      end: 0,
      delay: 1100.ms,
      duration: 500.ms,
      curve: Curves.easeOutCubic,
    );
  }
}