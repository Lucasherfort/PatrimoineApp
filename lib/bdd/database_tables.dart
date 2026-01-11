// lib/constants/database_tables.dart
class DatabaseTables {
  // Tables principales
  static const String patrimoines = 'patrimoines';
  static const String patrimoineCategory = 'patrimoine_category';

  // Tables sources par catégorie
  static const String liquiditySource = 'liquidity_source';
  static const String savingsSource = 'savings_source';

  // Tables users
  static const String userLiquidityAccounts = 'user_liquidity_account';
  static const String userSavingsAccounts = 'user_savings_account';

  // Autres tables
  static const String banks = 'banks';
  static const String restaurantVouchers = 'restaurant_vouchers';
  static const String cashAccounts = 'cash_accounts';
  static const String savingsAccounts = 'savings_accounts';

  DatabaseTables._();
}