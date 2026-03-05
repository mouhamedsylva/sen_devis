import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/signature_pad.dart';
import '../../widgets/mobile_button.dart';
import '../../widgets/mobile_text_field.dart';
import '../home/home_screen.dart';

class CompanySettingsScreen extends StatefulWidget {
  static const String routeName = '/company-settings';

  const CompanySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vatRateController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _registrationController = TextEditingController();
  final _taxIdController = TextEditingController();

  final StorageService _storageService = StorageService.instance;
  Uint8List? _logoBytes;
  String? _currentLogoPath;
  Uint8List? _signatureBytes;
  String? _currentSignaturePath;
  bool _isFirstSetup = false;
  bool _dataLoaded = false;
  String? _prefilledCompanyName;
  String? _prefilledCompanyPhone;

  @override
  void initState() {
    super.initState();
    // Ne pas charger les données ici, attendre didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_dataLoaded) {
      _dataLoaded = true;
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _isFirstSetup = args?['isFirstSetup'] ?? false;
      
      // Récupérer les données pré-remplies depuis l'inscription
      if (_isFirstSetup && args != null) {
        _prefilledCompanyName = args['companyName'] as String?;
        _prefilledCompanyPhone = args['companyPhone'] as String?;
      }
      
      // Charger les données après avoir récupéré les arguments
      _loadCompanyData();
    }
  }

  Future<void> _loadCompanyData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    debugPrint('🏢 COMPANY_SETTINGS: Loading data for userId: $userId');
    debugPrint('🏢 COMPANY_SETTINGS: isFirstSetup: $_isFirstSetup');
    debugPrint('🏢 COMPANY_SETTINGS: prefilledCompanyName: $_prefilledCompanyName');
    debugPrint('🏢 COMPANY_SETTINGS: prefilledCompanyPhone: $_prefilledCompanyPhone');

    if (userId != null) {
      await context.read<CompanyProvider>().loadCompany(userId);

      final company = context.read<CompanyProvider>().company;
      debugPrint('🏢 COMPANY_SETTINGS: Company loaded: ${company != null}');
      
      if (company != null) {
        debugPrint('🏢 COMPANY_SETTINGS: Company name: ${company.name}');
        debugPrint('🏢 COMPANY_SETTINGS: Company phone: ${company.phone}');
        
        // Charger les données existantes de l'entreprise
        _nameController.text = company.name;
        _emailController.text = company.email ?? '';
        _phoneController.text = company.phone ?? '';
        _websiteController.text = company.website ?? '';
        _addressController.text = company.address ?? '';
        _cityController.text = company.city ?? '';
        _postalCodeController.text = company.postalCode ?? '';
        _registrationController.text = company.registrationNumber ?? '';
        _taxIdController.text = company.taxId ?? '';
        _vatRateController.text = company.vatRate.toString();
        _currentLogoPath = company.logoPath;
        _currentSignaturePath = company.signaturePath;
        
        debugPrint('🏢 COMPANY_SETTINGS: Controllers filled with company data');
        setState(() {});
      } else {
        debugPrint('🏢 COMPANY_SETTINGS: No company found, using prefilled data');
        
        // Pas d'entreprise existante - utiliser les données d'inscription si disponibles
        if (_prefilledCompanyName != null && _nameController.text.isEmpty) {
          _nameController.text = _prefilledCompanyName!;
          debugPrint('🏢 COMPANY_SETTINGS: Set name from prefilled: $_prefilledCompanyName');
        }
        if (_prefilledCompanyPhone != null && _phoneController.text.isEmpty) {
          _phoneController.text = _prefilledCompanyPhone!;
          debugPrint('🏢 COMPANY_SETTINGS: Set phone from prefilled: $_prefilledCompanyPhone');
        }
        
        // Valeur par défaut pour la TVA
        if (_vatRateController.text.isEmpty) {
          _vatRateController.text = '18.0';
        }
        
        setState(() {});
      }
    } else {
      debugPrint('🏢 COMPANY_SETTINGS: ERROR - userId is null!');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vatRateController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _registrationController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final bytes = await _storageService.pickImageFromGalleryAsBytes();
    if (bytes != null) {
      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  Future<void> _takeLogo() async {
    final bytes = await _storageService.takePhotoAsBytes();
    if (bytes != null) {
      setState(() {
        _logoBytes = bytes;
      });
    }
  }

  Future<void> _showLogoOptions() async {
    MobileUtils.lightHaptic();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const SizedBox(height: MobileConstants.spacingM),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: MobileConstants.spacingL),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text('Galerie'),
                onTap: () {
                  MobileUtils.lightHaptic();
                  Navigator.pop(context);
                  _pickLogo();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('Appareil photo'),
                onTap: () {
                  MobileUtils.lightHaptic();
                  Navigator.pop(context);
                  _takeLogo();
                },
              ),
              if (_currentLogoPath != null || _logoBytes != null)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: Text('Supprimer le logo'),
                  onTap: () {
                    MobileUtils.mediumHaptic();
                    Navigator.pop(context);
                    setState(() {
                      _logoBytes = null;
                      _currentLogoPath = null;
                    });
                  },
                ),
              const SizedBox(height: MobileConstants.spacingM),
            ],
          ),
        ),
      );
      },
    );
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) {
      MobileUtils.showMobileSnackBar(
        context,
        message: 'Veuillez remplir tous les champs obligatoires',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId == null) return;

    final companyProvider = context.read<CompanyProvider>();

    String? logoPath = _currentLogoPath;
    if (_logoBytes != null) {
      logoPath = await _storageService.saveCompanyLogoFromBytes(_logoBytes!);
    }

    String? signaturePath = _currentSignaturePath;
    if (_signatureBytes != null) {
      signaturePath = await _storageService.saveCompanySignatureFromBytes(_signatureBytes!);
    }

    final success = await companyProvider.saveCompany(
      userId: userId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      registrationNumber: _registrationController.text.trim().isEmpty
          ? null
          : _registrationController.text.trim(),
      taxId: _taxIdController.text.trim().isEmpty
          ? null
          : _taxIdController.text.trim(),
      logoPath: logoPath,
      signaturePath: signaturePath,
      vatRate: double.tryParse(_vatRateController.text.replaceAll(',', '.')) ?? 18.0,
    );

    if (!mounted) return;

    if (success) {
      MobileUtils.showMobileSnackBar(
        context,
        message: _isFirstSetup ? 'Configuration terminée !' : 'Modifications enregistrées',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );

      if (_isFirstSetup) {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else {
        Navigator.of(context).pop();
      }
    } else {
      MobileUtils.showMobileSnackBar(
        context,
        message: companyProvider.errorMessage ?? 'Une erreur est survenue',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final scaffoldBg = isDark ? th.scaffoldBackgroundColor : const Color(0xFFF6F8F8);
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final appBarBg = isDark ? const Color(0xFF1E1E1E).withOpacity(0.8) : Colors.white.withOpacity(0.8);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1A1A);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Consumer<CompanyProvider>(
        builder: (context, companyProvider, child) {
          if (companyProvider.isLoading) {
            return Center(child: LoadingIndicator());
          }

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // iOS-Style App Bar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: appBarBg,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        _isFirstSetup ? Icons.close : Icons.arrow_back_ios,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () {
                        MobileUtils.lightHaptic();
                        if (_isFirstSetup) {
                          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    title: Text(
                      'Paramètres de l\'entreprise',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      SizedBox(width: 48), // For symmetry
                    ],
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo Section
                          _buildLogoSection(),

                          const SizedBox(height: 24),

                          // Informations générales
                          _buildSection(
                            title: 'INFORMATIONS GÉNÉRALES',
                            children: [
                              _buildModernTextField(
                                controller: _nameController,
                                label: 'Nom de l\'entreprise',
                                hint: 'Mon Entreprise',
                                validator: Validators.required,
                              ),
                              const SizedBox(height: 16),
                              // _buildModernTextField(
                              //   controller: _registrationController,
                              //   label: 'Numéro SIRET',
                              //   hint: '123 456 789 00001',
                              // ),
                              // const SizedBox(height: 16),
                              // _buildModernTextField(
                              //   controller: _taxIdController,
                              //   label: 'Numéro de TVA',
                              //   hint: 'FR 12 345678901',
                              // ),
                            ],
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

                          const SizedBox(height: 32),

                          // Coordonnées
                          _buildSection(
                            title: 'COORDONNÉES',
                            children: [
                              _buildModernTextField(
                                controller: _emailController,
                                label: 'Email professionnel',
                                hint: 'contact@entreprise.com',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _phoneController,
                                label: 'Numéro de téléphone',
                                hint: '+33 6 12 34 56 78',
                                prefixIcon: Icons.call_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _websiteController,
                                label: 'Site web',
                                hint: 'https://www.entreprise.com',
                                prefixIcon: Icons.language,
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          ).animate().fadeIn(
                            delay: 700.ms,
                            duration: 500.ms,
                          ).slideY(
                            begin: 0.2,
                            end: 0,
                            delay: 700.ms,
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          ),

                          const SizedBox(height: 32),

                          // Adresse
                          _buildSection(
                            title: 'ADRESSE',
                            children: [
                              _buildModernTextField(
                                controller: _addressController,
                                label: 'Rue',
                                hint: '123 Avenue du Commerce',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _cityController,
                                      label: 'Ville',
                                      hint: 'Paris',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _postalCodeController,
                                      label: 'Code postal',
                                      hint: '75001',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _vatRateController,
                                label: 'Taux de TVA (%)',
                                hint: '18.0',
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: Validators.vatRate,
                              ),
                            ],
                          ).animate().fadeIn(
                            delay: 800.ms,
                            duration: 500.ms,
                          ).slideY(
                            begin: 0.2,
                            end: 0,
                            delay: 800.ms,
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          ),

                          const SizedBox(height: 32),

                          // Signature électronique
                          _buildSection(
                            title: 'SIGNATURE ÉLECTRONIQUE',
                            children: [
                              _buildSignatureSection(),
                            ],
                          ).animate().fadeIn(
                            delay: 900.ms,
                            duration: 500.ms,
                          ).slideY(
                            begin: 0.2,
                            end: 0,
                            delay: 900.ms,
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          ),

                          const SizedBox(height: 120), // Space for fixed button
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Fixed Bottom Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E).withOpacity(0.9) : Colors.white.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: _saveCompany,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              shadowColor: AppColors.primary.withOpacity(0.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Enregistrer les modifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(
                            delay: 1000.ms,
                            duration: 500.ms,
                          ).slideY(
                            begin: 0.3,
                            end: 0,
                            delay: 1000.ms,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1A1A);

    return Container(
      color: cardBg,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              MobileUtils.lightHaptic();
              _showLogoOptions();
            },
            child: Stack(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    image: _logoBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_logoBytes!),
                            fit: BoxFit.cover,
                          )
                        : _currentLogoPath != null
                            ? DecorationImage(
                                image: NetworkImage(_currentLogoPath!),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: _logoBytes == null && _currentLogoPath == null
                      ? Icon(
                          Icons.business_center_outlined,
                          size: 40,
                          color: AppColors.primary.withOpacity(0.4),
                        )
                      : null,
                ).animate().scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ).fadeIn(
                  duration: 400.ms,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    delay: 300.ms,
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ).fadeIn(
                    delay: 300.ms,
                    duration: 300.ms,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Logo de l\'entreprise',
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 4),
          Text(
            'PNG ou JPG, max 5Mo',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.6),
              fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSignaturePad() async {
    MobileUtils.lightHaptic();
    await showDialog(
      context: context,
      builder: (context) => SignaturePad(
        onSignatureSaved: (bytes) {
          if (bytes != null) {
            setState(() {
              _signatureBytes = bytes;
            });
          }
        },
      ),
    );
  }

  Widget _buildSignatureSection() {
    final hasSignature = _signatureBytes != null || _currentSignaturePath != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1A1A);
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F8F8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature de l\'entreprise',
          style: TextStyle(
            color: titleColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        if (hasSignature)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _signatureBytes != null
                  ? Image.memory(
                      _signatureBytes!,
                      fit: BoxFit.contain,
                    )
                  : _currentSignaturePath != null
                      ? Image.network(
                          _currentSignaturePath!,
                          fit: BoxFit.contain,
                        )
                      : null,
            ),
          ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openSignaturePad,
                icon: Icon(
                  hasSignature ? Icons.edit : Icons.draw,
                  size: 18,
                ),
                label: Text(
                  hasSignature ? 'Modifier la signature' : 'Ajouter une signature',
                  style: TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (hasSignature) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  MobileUtils.mediumHaptic();
                  setState(() {
                    _signatureBytes = null;
                    _currentSignaturePath = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(
                    horizontal: MobileConstants.spacingM,
                    vertical: MobileConstants.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        Text(
          'Cette signature apparaîtra sur tous vos devis générés',
          style: TextStyle(
            color: AppColors.primary.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return MobileTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}