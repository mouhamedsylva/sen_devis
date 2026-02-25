import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import '../../core/constants/app_constants.dart';

/// Connexion web (utilise sql.js - SQLite compilé en WebAssembly)
Future<QueryExecutor> createDatabaseConnection() async {
  return WebDatabase(
    AppConstants.databaseName,
    logStatements: false,
  );
}
