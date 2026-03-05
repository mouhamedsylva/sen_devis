import 'package:drift/drift.dart';

// Table utilisateurs
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phone => text().unique()();
  TextColumn get password => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

// Table entreprise
class Companies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id').references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get postalCode => text().named('postal_code').nullable()();
  TextColumn get registrationNumber => text().named('registration_number').nullable()();
  TextColumn get taxId => text().named('tax_id').nullable()();
  TextColumn get logoPath => text().named('logo_path').nullable()();
  TextColumn get signaturePath => text().named('signature_path').nullable()();
  RealColumn get vatRate => real().named('vat_rate').withDefault(const Constant(18.0))();
  TextColumn get currency => text().withDefault(const Constant('FCFA'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

// Table clients
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id').references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

// Table produits/services
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id').references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get unitPrice => real().named('unit_price')();
  RealColumn get vatRate => real().named('vat_rate').withDefault(const Constant(18.0))();
  
  // Soft delete
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

// Table devis
class Quotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().named('user_id').references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get quoteNumber => text().named('quote_number').unique()();
  IntColumn get clientId => integer().named('client_id').references(Clients, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get quoteDate => dateTime().named('quote_date')();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  RealColumn get totalHT => real().named('total_ht').withDefault(const Constant(0.0))();
  RealColumn get totalVAT => real().named('total_vat').withDefault(const Constant(0.0))();
  RealColumn get totalTTC => real().named('total_ttc').withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  
  // Nouvelles conditions du devis
  BoolColumn get depositRequired => boolean().named('deposit_required').withDefault(const Constant(true))();
  TextColumn get depositType => text().named('deposit_type').withDefault(const Constant('percentage'))(); // 'percentage' ou 'amount'
  RealColumn get depositPercentage => real().named('deposit_percentage').withDefault(const Constant(40.0))();
  RealColumn get depositAmount => real().named('deposit_amount').withDefault(const Constant(0.0))();
  IntColumn get validityDays => integer().named('validity_days').withDefault(const Constant(30))();
  TextColumn get deliveryDelay => text().named('delivery_delay').nullable()();
  
  // Soft delete
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

// Table articles de devis
class QuoteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quoteId => integer().named('quote_id').references(Quotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().named('product_id').nullable().references(Products, #id, onDelete: KeyAction.setNull)();
  TextColumn get productName => text().named('product_name')();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real().named('unit_price')();
  RealColumn get vatRate => real().named('vat_rate')();
  RealColumn get totalHT => real().named('total_ht')();
  RealColumn get totalVAT => real().named('total_vat')();
  RealColumn get totalTTC => real().named('total_ttc')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
}
