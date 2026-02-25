import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/senegal_phone_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/localization/localization_extension.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/mobile_button.dart';
import '../../widgets/mobile_text_field.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } else {
      MobileUtils.showMobileSnackBar(
        context,
        message: authProvider.errorMessage ?? AppStrings.errorOccurred,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    }
  }

  void _navigateToRegister() {
    MobileUtils.lightHaptic();
    Navigator.of(context).pushNamed(RegisterScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final scaffoldBg = isDark ? th.scaffoldBackgroundColor : const Color(0xFFF6F8F8);
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final accentColor = const Color(0xFF0D5C63);
    
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

                    return SingleChildScrollView(
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
                              const SizedBox(height: 48),
                              
                              // Logo area
                              _buildLogo(),
                              const SizedBox(height: 40),
                              
                              // Welcome text
                              _buildWelcomeText(),
                              const SizedBox(height: 40),
                              
                              // Login form
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: MobileConstants.spacingL),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildPhoneField(),
                                    SizedBox(height: MobileConstants.spacingM),
                                    _buildPasswordField(),
                                    SizedBox(height: MobileConstants.spacingS),
                                    _buildForgotPassword(),
                                    SizedBox(height: MobileConstants.spacingL),
                                    _buildLoginButton(),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Sign up link
                              _buildSignUpLink(),
                              
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0D5C63).withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Color(0xFF0D5C63),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.appName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D5C63),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            context.tr('welcome'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('login_subtitle'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('phone_number'),
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
              return context.tr('invalid_phone');
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
      label: context.tr('password'),
      hint: context.tr('enter_password'),
      prefixIcon: Icons.lock_rounded,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 22,
        ),
        onPressed: () {
          MobileUtils.lightHaptic();
          setState(() => _obscurePassword = !_obscurePassword);
        },
      ),
      validator: Validators.password,
      onChanged: (_) {},
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implement forgot password
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          minimumSize: const Size(0, 44),
        ),
        child: Text(
          context.tr('forgot_password'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D5C63),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MobileButton(
          text: context.tr('login'),
          icon: Icons.login_rounded,
          onPressed: _handleLogin,
          isLoading: authProvider.isLoading,
          backgroundColor: const Color(0xFF0D5C63),
        );
      },
    );
  }

  Widget _buildSignUpLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.tr('no_account'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          TextButton(
            onPressed: _navigateToRegister,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              context.tr('sign_up'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D5C63),
              ),
            ),
          ),
        ],
      ),
    );
  }
}