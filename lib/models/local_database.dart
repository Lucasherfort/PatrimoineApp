// 📁 models/local_database.dart

import 'package:patrimoine/models/restaurant_voucher.dart';

import 'bank.dart';
import 'cash_account.dart';
import 'user_cash_account.dart';
import 'savings_account_type.dart'; // ✅ AJOUTÉ
import 'savings_account.dart';
import 'user_savings_account.dart';
import 'investment_account.dart';
import 'user_investment_account.dart';
import 'investment_position.dart';
import 'user_restaurant_voucher.dart';

class LocalDatabase {
  final List<Bank> banks;
  final List<CashAccount> cashAccounts;
  final List<UserCashAccount> userCashAccounts;
  final List<SavingsAccountType> savingsAccountTypes; // ✅ AJOUTÉ
  final List<SavingsAccount> savingsAccounts;
  final List<UserSavingsAccount> userSavingsAccounts;
  final List<InvestmentAccount> investmentAccounts;
  final List<UserInvestmentAccount> userInvestmentAccounts;
  final List<InvestmentPosition> investmentPositions;
  final List<RestaurantVoucher> restaurantVouchers;
  final List<UserRestaurantVoucher> userRestaurantVouchers;

  LocalDatabase({
    required this.banks,
    required this.cashAccounts,
    required this.userCashAccounts,
    required this.savingsAccountTypes, // ✅ AJOUTÉ
    required this.savingsAccounts,
    required this.userSavingsAccounts,
    required this.investmentAccounts,
    required this.userInvestmentAccounts,
    required this.investmentPositions,
    required this.restaurantVouchers,
    required this.userRestaurantVouchers,
  });

  /// 🔹 Crée un LocalDatabase à partir d'un JSON
  factory LocalDatabase.fromJson(Map<String, dynamic> json) {
    return LocalDatabase(
      banks: (json['banks'] as List<dynamic>?)
          ?.map((b) => Bank.fromJson(b))
          .toList() ??
          [],
      cashAccounts: (json['cashAccounts'] as List<dynamic>?)
          ?.map((ca) => CashAccount.fromJson(ca))
          .toList() ??
          [],
      userCashAccounts: (json['userCashAccounts'] as List<dynamic>?)
          ?.map((uca) => UserCashAccount.fromJson(uca))
          .toList() ??
          [],
      // ✅ AJOUTÉ
      savingsAccountTypes: (json['savingsAccountTypes'] as List<dynamic>?)
          ?.map((sat) => SavingsAccountType.fromJson(sat))
          .toList() ??
          [],
      savingsAccounts: (json['savingsAccounts'] as List<dynamic>?)
          ?.map((sa) => SavingsAccount.fromJson(sa))
          .toList() ??
          [],
      userSavingsAccounts: (json['userSavingsAccounts'] as List<dynamic>?)
          ?.map((usa) => UserSavingsAccount.fromJson(usa))
          .toList() ??
          [],
      investmentAccounts: (json['investmentAccounts'] as List<dynamic>?)
          ?.map((ia) => InvestmentAccount.fromJson(ia))
          .toList() ??
          [],
      userInvestmentAccounts: (json['userInvestmentAccounts'] as List<dynamic>?)
          ?.map((uia) => UserInvestmentAccount.fromJson(uia))
          .toList() ??
          [],
      investmentPositions: (json['investmentPositions'] as List<dynamic>?)
          ?.map((ip) => InvestmentPosition.fromJson(ip))
          .toList() ??
          [],
      restaurantVouchers: (json['restaurantVouchers'] as List<dynamic>?)
          ?.map((rv) => RestaurantVoucher.fromJson(rv))
          .toList() ??
          [],
      userRestaurantVouchers:
      (json['userRestaurantVouchers'] as List<dynamic>?)
          ?.map((urv) => UserRestaurantVoucher.fromJson(urv))
          .toList() ??
          [],
    );
  }

  /// 🔹 Convertit LocalDatabase en JSON
  Map<String, dynamic> toJson() => {
    'banks': banks.map((b) => b.toJson()).toList(),
    'cashAccounts': cashAccounts.map((ca) => ca.toJson()).toList(),
    'userCashAccounts': userCashAccounts.map((uca) => uca.toJson()).toList(),
    'savingsAccountTypes': savingsAccountTypes.map((sat) => sat.toJson()).toList(), // ✅ AJOUTÉ
    'savingsAccounts': savingsAccounts.map((sa) => sa.toJson()).toList(),
    'userSavingsAccounts':
    userSavingsAccounts.map((usa) => usa.toJson()).toList(),
    'investmentAccounts':
    investmentAccounts.map((ia) => ia.toJson()).toList(),
    'userInvestmentAccounts':
    userInvestmentAccounts.map((uia) => uia.toJson()).toList(),
    'investmentPositions':
    investmentPositions.map((ip) => ip.toJson()).toList(),
    'restaurantVouchers':
    restaurantVouchers.map((rv) => rv.toJson()).toList(),
    'userRestaurantVouchers':
    userRestaurantVouchers.map((urv) => urv.toJson()).toList(),
  };

  /// 🔹 Crée un LocalDatabase vide
  factory LocalDatabase.empty() {
    return LocalDatabase(
      banks: [],
      cashAccounts: [],
      userCashAccounts: [],
      savingsAccountTypes: [], // ✅ AJOUTÉ
      savingsAccounts: [],
      userSavingsAccounts: [],
      investmentAccounts: [],
      userInvestmentAccounts: [],
      investmentPositions: [],
      restaurantVouchers: [],
      userRestaurantVouchers: [],
    );
  }
}