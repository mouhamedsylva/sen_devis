class AppConstants {
  // Database
  static const String databaseName = 'devis_app.db';
  static const int databaseVersion = 1;
  
  // Default values
  static const double defaultVatRate = 18.0; // TVA standard en Afrique de l'Ouest
  static const String defaultCurrency = 'FCFA';
  static const String defaultPhonePrefix = '+221'; // Sénégal par défaut
  
  // Quote number format
  static const String quoteNumberPrefix = 'DEV';
  static const int quoteNumberLength = 6;
  
  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxCompanyNameLength = 100;
  static const int maxClientNameLength = 100;
  static const int maxProductNameLength = 200;
  
  // Phone validation
  static const String phoneRegex = r'^[+]?[0-9]{8,15}$';
  
  // PDF settings
  static const String pdfDefaultFileName = 'devis';
  static const double pdfMargin = 20.0;
  
  // Share settings
  static const String shareSubject = 'Devis - ';
  static const String shareMessage = 'Veuillez trouver ci-joint votre devis.';
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Image
  static const int maxImageSize = 2 * 1024 * 1024; // 2MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
}