import 'package:patrimoine/models/savings_account.dart';
import 'package:patrimoine/models/user.dart';
import 'package:patrimoine/models/user_savings_account.dart';

import 'bank.dart';

class LocalDatabase {
  final List<Bank> banks;
  final List<SavingsAccount> savingsAccounts;
  final List<User> users;
  final List<UserSavingsAccount> userSavingsAccounts;

  LocalDatabase({
    required this.banks,
    required this.savingsAccounts,
    required this.users,
    required this.userSavingsAccounts,
  });

  /// Factory pour retourner une base vide (premier lancement)
  factory LocalDatabase.empty() {
    return LocalDatabase(
      banks: [],
      savingsAccounts: [],
      users: [],
      userSavingsAccounts: [],
    );
  }

  factory LocalDatabase.fromJson(Map<String, dynamic> json) {
    return LocalDatabase(
      banks: (json['banks'] as List)
          .map((e) => Bank.fromJson(e))
          .toList(),
      savingsAccounts: (json['savingsAccounts'] as List)
          .map((e) => SavingsAccount.fromJson(e))
          .toList(),
      users: (json['users'] as List)
          .map((e) => User.fromJson(e))
          .toList(),
      userSavingsAccounts: (json['userSavingsAccounts'] as List)
          .map((e) => UserSavingsAccount.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'banks': banks.map((e) => e.toJson()).toList(),
    'savingsAccounts': savingsAccounts.map((e) => e.toJson()).toList(),
    'users': users.map((e) => e.toJson()).toList(),
    'userSavingsAccounts': userSavingsAccounts.map((e) => e.toJson()).toList(),
  };
}