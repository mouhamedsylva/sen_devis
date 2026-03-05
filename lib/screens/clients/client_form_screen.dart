import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../data/database/app_database.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/mobile_button.dart';
import '../../widgets/mobile_text_field.dart';

class ClientFormScreen extends StatefulWidget {
  static const String routeName = '/client-form';

  const ClientFormScreen({Key? key}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _registrationController = TextEditingController();

  int? _clientId;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _clientId = args?['clientId'];

    if (_clientId != null) {
      _loadClient();
    }
  }

  void _loadClient() {
    final client = context.read<ClientProvider>().getClientById(_clientId!);
    if (client != null) {
      _nameController.text = client.name;
      _phoneController.text = client.phone ?? '';
      _emailController.text = client.email ?? ''; // ✅ AJOUTER L'EMAIL
      _addressController.text = client.address ?? '';
      // Si vous avez d'autres champs, chargez-les ici
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId == null) return;

    final clientProvider = context.read<ClientProvider>();
    bool success;
    Client? createdOrUpdatedClient;

    if (_clientId == null) {
      // Ajouter un nouveau client - INCLURE L'EMAIL
      success = await clientProvider.addClient(
        userId: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(), // ✅ AJOUTER L'EMAIL
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );
      
      // Récupérer le client créé
      if (success) {
        await clientProvider.loadClients(userId);
        // Trouver le client qui vient d'être créé (le dernier avec ce nom)
        createdOrUpdatedClient = clientProvider.clients.lastWhere(
          (c) => c.name == _nameController.text.trim(),
          orElse: () => clientProvider.clients.last,
        );
      }
    } else {
      // Mettre à jour le client existant - INCLURE L'EMAIL
      success = await clientProvider.updateClient(
        id: _clientId!,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(), // ✅ AJOUTER L'EMAIL
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );
      
      // Récupérer le client mis à jour
      if (success) {
        createdOrUpdatedClient = clientProvider.getClientById(_clientId!);
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      MobileUtils.showMobileSnackBar(
        context,
        message: AppStrings.saveSuccess,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );
      // Retourner le client créé ou mis à jour
      Navigator.of(context).pop(createdOrUpdatedClient);
    } else {
      MobileUtils.showMobileSnackBar(
        context,
        message: clientProvider.errorMessage ?? AppStrings.errorOccurred,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _clientId != null;
    final th = Theme.of(context);
    final isDark = th.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final txtColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? th.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: txtColor),
          onPressed: () {
            MobileUtils.lightHaptic();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          isEdit ? context.tr('edit_client') : context.tr('new_client'),
          style: TextStyle(
            color: txtColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            onPressed: () {
              MobileUtils.lightHaptic();
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // INFORMATIONS ENTREPRISE
                    // _buildSectionHeader(
                    //   icon: Icons.business,
                    //   title: 'INFORMATIONS ENTREPRISE',
                    // ),
                    // _buildTextField(
                    //   controller: _companyNameController,
                    //   label: 'Nom de l\'entreprise',
                    //   hint: 'ex. Acme Global Ltd.',
                    //   icon: Icons.business_outlined,
                    //   validator: Validators.required,
                    // ),
                    // _buildTextField(
                    //   controller: _registrationController,
                    //   label: 'Numéro d\'enregistrement (NINEA/NIF)',
                    //   hint: 'ex. 123 456 789 00012',
                    //   icon: Icons.badge_outlined,
                    // ),

                    const SizedBox(height: MobileConstants.spacingL),

                    // CONTACT PRINCIPAL
                    _buildSectionHeader(
                      icon: Icons.person,
                      title: context.tr('main_contact_section'),
                    ),
                    _buildTextField(
                      controller: _nameController,
                      label: context.tr('contact_person_name'),
                      hint: context.tr('contact_person_hint'),
                      icon: Icons.person_outline,
                      validator: Validators.required,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: context.tr('email_address'),
                      hint: context.tr('email_hint'),
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: context.tr('client_phone'),
                      hint: context.tr('phone_hint'),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: MobileConstants.spacingL),

                    // ADRESSE PROFESSIONNELLE
                    _buildSectionHeader(
                      icon: Icons.location_on,
                      title: context.tr('business_address'),
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: context.tr('full_address'),
                      hint: context.tr('address_hint'),
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: MobileConstants.spacingXl),

                    // Bouton de sauvegarde
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MobileConstants.spacingM,
                      ),
                      child: _buildSaveButton(),
                    ),
                    const SizedBox(height: MobileConstants.spacingL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MobileConstants.spacingM,
        MobileConstants.spacingS,
        MobileConstants.spacingM,
        MobileConstants.spacingM,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF1A7B7B),
          ),
          const SizedBox(width: MobileConstants.spacingS),
          Text(
            title,
            style: const TextStyle(
              fontSize: MobileConstants.fontSizeS,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A7B7B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MobileConstants.spacingM,
        vertical: MobileConstants.spacingS,
      ),
      child: MobileTextField(
        controller: controller,
        label: label,
        hint: hint,
        prefixIcon: icon,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildSaveButton() {
    return MobileButton(
      text: context.tr('save_client'),
      onPressed: _saveClient,
      icon: Icons.person_add,
      backgroundColor: const Color(0xFF1A7B7B),
      height: MobileConstants.recommendedTouchTarget,
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1A7B7B)),
            const SizedBox(width: 12),
            Text(context.tr('information')),
          ],
        ),
        content: Text(
          context.tr('client_info_message'),
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              MobileUtils.lightHaptic();
              Navigator.of(context).pop();
            },
            child: Text(
              context.tr('understood'),
              style: const TextStyle(
                color: Color(0xFF1A7B7B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}