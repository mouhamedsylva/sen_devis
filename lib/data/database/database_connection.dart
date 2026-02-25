import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/app_constants.dart';

// Imports conditionnels selon la plateforme
import 'database_connection_stub.dart'
    if (dart.library.io) 'database_connection_native.dart'
    if (dart.library.html) 'database_connection_web.dart';

/// Crée une connexion à la base de données adaptée à la plateforme
/// - Web : utilise sql.js (SQLite compilé en WebAssembly)
/// - Mobile/Desktop : utilise SQLite natif avec FFI
QueryExecutor connect() {
  return LazyDatabase(() async {
    return await createDatabaseConnection();
  });
}
