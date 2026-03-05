import 'package:flutter/material.dart';
import '../data/database/app_database.dart';

/// Widget simplifié qui notifie juste les changements de texte
class ProductAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final List<Product> products;
  final String hint;
  final Color primaryColor;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Function(List<Product>)? onSuggestionsChanged;

  const ProductAutocompleteField({
    Key? key,
    required this.controller,
    required this.products,
    required this.hint,
    required this.primaryColor,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    this.onSuggestionsChanged,
  }) : super(key: key);

  @override
  State<ProductAutocompleteField> createState() => _ProductAutocompleteFieldState();
}

class _ProductAutocompleteFieldState extends State<ProductAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim().toLowerCase();

    if (query.isEmpty) {
      widget.onSuggestionsChanged?.call([]);
      return;
    }

    final filteredProducts = widget.products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).take(5).toList();

    widget.onSuggestionsChanged?.call(filteredProducts);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: widget.textSecondary.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search, color: widget.textSecondary),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: widget.textSecondary),
                onPressed: () {
                  widget.controller.clear();
                  widget.onSuggestionsChanged?.call([]);
                },
              )
            : null,
        filled: true,
        fillColor: widget.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: TextStyle(
        fontSize: 14,
        color: widget.textPrimary,
      ),
    );
  }
}
