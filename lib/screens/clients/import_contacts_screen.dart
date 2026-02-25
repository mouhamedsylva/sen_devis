import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/contact_import_service.dart';
import '../../models/imported_contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/constants/colors.dart';

class ImportContactsScreen extends StatefulWidget {
  static const String routeName = '/import-contacts';

  const ImportContactsScreen({Key? key}) : super(key: key);

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  final _importService = ContactImportService.instance;
  List<ImportedContact> _contacts = [];
  Set<int> _selectedIndices = {};
  bool _isLoading = false;
  bool _selectAll = false;
  String? _errorMessage;

  Future<void> _importFromPhone() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await _importService.importFromPhone();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });

      if (contacts.isEmpty) {
        _showMessage('Aucun contact trouvé');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showMessage('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _importFromCSV() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await _importService.importFromCSV();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });

      if (contacts.isEmpty) {
        _showMessage('Aucun contact trouvé dans le fichier');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showMessage('Erreur: ${e.toString()}', isError: true);
    }
  }

  Future<void> _saveSelectedContacts() async {
    if (_selectedIndices.isEmpty) {
      _showMessage('Veuillez sélectionner au moins un contact');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final clientProvider = context.read<ClientProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      int successCount = 0;
      int errorCount = 0;

      for (final index in _selectedIndices) {
        final contact = _contacts[index];
        
        try {
          await clientProvider.addClient(
            userId: userId,
            name: contact.name,
            phone: contact.phone,
            address: contact.address,
          );
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (errorCount == 0) {
        _showMessage('$successCount contact(s) importé(s) avec succès');
        Navigator.of(context).pop(true);
      } else {
        _showMessage(
          '$successCount contact(s) importé(s), $errorCount erreur(s)',
          isError: errorCount > successCount,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Erreur lors de l\'import: ${e.toString()}', isError: true);
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      _selectAll = _selectedIndices.length == _contacts.length;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedIndices = Set.from(List.generate(_contacts.length, (i) => i));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('Importer des contacts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_contacts.isNotEmpty && !_isLoading)
            TextButton.icon(
              onPressed: _saveSelectedContacts,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Importer (${_selectedIndices.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _contacts.isEmpty
              ? _buildEmptyState()
              : _buildContactsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.contacts_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Importer des contacts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choisissez une méthode d\'import',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Bouton Import depuis téléphone
            _buildImportButton(
              icon: Icons.phone_android_rounded,
              title: 'Depuis le téléphone',
              subtitle: 'Importer depuis vos contacts',
              onTap: _importFromPhone,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A7B7B), Color(0xFF156666)],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bouton Import depuis CSV
            _buildImportButton(
              icon: Icons.file_upload_outlined,
              title: 'Depuis un fichier CSV',
              subtitle: 'Importer depuis un fichier',
              onTap: _importFromCSV,
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
              ),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderClr = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Column(
      children: [
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _selectAll ? 'Tout désélectionner' : 'Tout sélectionner',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedIndices.length}/${_contacts.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Liste des contacts
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _contacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              final isSelected = _selectedIndices.contains(index);
              
              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : borderClr,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleSelection(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(index),
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                contact.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (contact.phone != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        contact.phone!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (contact.address != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          contact.address!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
