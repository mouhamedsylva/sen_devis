import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/company_provider.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/mobile_utils.dart';
import '../../core/constants/mobile_constants.dart';
import '../../core/localization/localization_extension.dart';
import '../../widgets/mobile_button.dart';
import '../../widgets/mobile_text_field.dart';

class ProductFormScreen extends StatefulWidget {
  static const String routeName = '/product-form';

  const ProductFormScreen({Key? key}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _taxRateController = TextEditingController();

  int? _productId;
  bool _isLoading = false;
  bool _isTaxable = true;
  Uint8List? _productImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Couleurs du design - dynamiques selon le thème
  static const Color primaryColor = Color(0xFF0D7C7E);

  Color _getLabelColor(bool isDark) => isDark ? Colors.grey.shade300 : const Color(0xFF374151);
  Color _getHintColor(bool isDark) => isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF);
  Color _getBorderColor(bool isDark) => isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
  Color _getBgColor(bool isDark) => isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
  Color _getCardBg(bool isDark) => isDark ? const Color(0xFF2C2C2C) : Colors.white;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _productId = args?['productId'];

    if (_productId != null) {
      _loadProduct();
    } else {
      final company = context.read<CompanyProvider>().company;
      _taxRateController.text = company?.vatRate.toString() ?? '18.0';
    }
  }

  void _loadProduct() {
    final product = context.read<ProductProvider>().getProductById(_productId!);
    if (product != null) {
      _nameController.text = product.name;
      _unitPriceController.text = product.unitPrice.toString();
      _taxRateController.text = product.vatRate.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitPriceController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    MobileUtils.lightHaptic();
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _productImageBytes = bytes;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId == null) return;

    final productProvider = context.read<ProductProvider>();
    bool success;

    final unitPrice = double.parse(_unitPriceController.text.replaceAll(',', '.'));
    final taxRate = _isTaxable ? double.parse(_taxRateController.text.replaceAll(',', '.')) : 0.0;

    if (_productId == null) {
      success = await productProvider.addProduct(
        userId: userId,
        name: _nameController.text.trim(),
        unitPrice: unitPrice,
        vatRate: taxRate,
      );
    } else {
      success = await productProvider.updateProduct(
        id: _productId!,
        name: _nameController.text.trim(),
        unitPrice: unitPrice,
        vatRate: taxRate,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      MobileUtils.showMobileSnackBar(
        context,
        message: context.tr('product_saved'),
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
      Navigator.of(context).pop();
    } else {
      MobileUtils.showMobileSnackBar(
        context,
        message: productProvider.errorMessage ?? context.tr('error_occurred'),
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _productId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getBgColor(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isEdit),
            
            // Contenu du formulaire
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProductNameField(),
                              const SizedBox(height: MobileConstants.spacingL),
                              
                              _buildDescriptionField(),
                              const SizedBox(height: MobileConstants.spacingL),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildUnitPriceField(),
                                  ),
                                  const SizedBox(width: MobileConstants.spacingM),
                                  Expanded(
                                    child: _buildTaxRateField(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MobileConstants.spacingL),
                              
                              _buildTaxableToggle(),
                              const SizedBox(height: MobileConstants.spacingL),
                              
                              _buildImageUpload(),
                              const SizedBox(height: 100), // Espace pour le bouton fixe
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEdit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _getCardBg(isDark);
    final bColor = _getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(color: bColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              MobileUtils.lightHaptic();
              Navigator.of(context).pop();
            },
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isEdit ? context.tr('edit_product') : context.tr('add_product'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A7B7B),
              ),
            ),
          ),
          const SizedBox(width: 70), // Pour équilibrer avec le bouton Annuler
        ],
      ),
    );
  }

  Widget _buildProductNameField() {
    return MobileTextField(
      controller: _nameController,
      label: context.tr('product_name'),
      hint: context.tr('product_name_hint'),
      validator: Validators.required,
    );
  }

  Widget _buildDescriptionField() {
    return MobileTextField(
      controller: _descriptionController,
      label: context.tr('description'),
      hint: context.tr('description_hint'),
      maxLines: 4,
    );
  }

  Widget _buildUnitPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('unit_price'),
          style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getLabelColor(Theme.of(context).brightness == Brightness.dark),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _unitPriceController,
          validator: Validators.positiveNumber,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: _getHintColor(Theme.of(context).brightness == Brightness.dark),
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14, top: 14, bottom: 14),
              child: Text(
                '\$',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: _getCardBg(Theme.of(context).brightness == Brightness.dark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getBorderColor(Theme.of(context).brightness == Brightness.dark), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getBorderColor(Theme.of(context).brightness == Brightness.dark), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxRateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('tax_rate'),
          style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getLabelColor(Theme.of(context).brightness == Brightness.dark),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _taxRateController,
          validator: Validators.vatRate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: _isTaxable,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: _getHintColor(Theme.of(context).brightness == Brightness.dark),
              fontSize: 15,
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 14, top: 14, bottom: 14),
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: _getCardBg(Theme.of(context).brightness == Brightness.dark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getBorderColor(Theme.of(context).brightness == Brightness.dark), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getBorderColor(Theme.of(context).brightness == Brightness.dark), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getBorderColor(Theme.of(context).brightness == Brightness.dark), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxableToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardBg(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(isDark), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('taxable'),
                style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('apply_tax_rate'),
                style: TextStyle(fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
            ],
          ),
          CupertinoSwitch(
            value: _isTaxable,
            activeColor: primaryColor,
            onChanged: (value) {
              MobileUtils.lightHaptic();
              setState(() {
                _isTaxable = value;
                if (!value) {
                  _taxRateController.text = '0';
                } else {
                  final company = context.read<CompanyProvider>().company;
                  _taxRateController.text = company?.vatRate.toString() ?? '18.0';
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('product_image_optional'),
          style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getLabelColor(Theme.of(context).brightness == Brightness.dark),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: _getCardBg(Theme.of(context).brightness == Brightness.dark),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getBorderColor(Theme.of(context).brightness == Brightness.dark),
                width: 2,
                style: _productImageBytes != null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: _productImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _productImageBytes!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              onPressed: () {
                                MobileUtils.lightHaptic();
                                setState(() {
                                  _productImageBytes = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : DottedBorder(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: primaryColor,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('upload_photo'),
                            style: TextStyle(fontSize: 13,
                              color: _getHintColor(Theme.of(context).brightness == Brightness.dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(MobileConstants.spacingM),
      decoration: BoxDecoration(
        color: _getCardBg(isDark),
        border: Border(
          top: BorderSide(
            color: _getBorderColor(isDark),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: MobileButton(
          text: context.tr('save_product'),
          onPressed: _saveProduct,
          isLoading: _isLoading,
          backgroundColor: primaryColor,
          height: MobileConstants.buttonHeight,
        ),
      ),
    );
  }
}

// Widget personnalisé pour les bordures pointillées
class DottedBorder extends StatelessWidget {
  final Widget child;

  const DottedBorder({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(),
      child: child,
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;

    // Top
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX - dashWidth, size.height),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }

    // Left
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY - dashWidth),
        paint,
      );
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}