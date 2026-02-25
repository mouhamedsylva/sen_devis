import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';

/// Connexion native pour mobile et desktop (utilise FFI)
Future<QueryExecutor> createDatabaseConnection() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, '${AppConstants.databaseName}.db'));
  return NativeDatabase(file);
}
