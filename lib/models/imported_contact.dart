// Modèle pour un contact importé
class ImportedContact {
  final String name;
  final String? phone;
  final String? address;

  ImportedContact({
    required this.name,
    this.phone,
    this.address,
  });

  bool get isValid => name.isNotEmpty;
}
