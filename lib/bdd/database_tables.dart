// lib/constants/database_tables.dart
class DatabaseTables {
  // Tables principales
  static const String patrimoines = 'patrimoines';
  static const String patrimoineCategory = 'patrimoine_category';

  // Tables catégorie
  static const String liquiditySource = 'liquidity_source';
  static const String savingsCategory = 'savings_category';
  static const String investmentCategory = 'investment_category';

  // Tables source
  static const String savingsSource = 'savings_source';
  static const String investmentSource = 'investment_source';

  // Tables users
  static const String userLiquidityAccounts = 'user_liquidity_account';
  static const String userSavingsAccounts = 'user_savings_account';
  static const String userInvestmentAccount = 'user_investment_account';
  static const String userInvestmentPosition = 'user_investment_position';

  // Autres tables
  static const String banks = 'banks';
  static const String restaurantVouchers = 'restaurant_vouchers';
  static const String cashAccounts = 'cash_accounts';
  static const String savingsAccounts = 'savings_accounts';

  DatabaseTables._();
}