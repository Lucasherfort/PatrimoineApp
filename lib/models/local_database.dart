import 'Bank.dart';
import 'savings_account.dart';
import 'user_savings_account.dart';
import 'investment_account.dart';
import 'user_investment_account.dart';
import 'investment_position.dart';

class LocalDatabase {
  final List<Bank> banks;
  final List<SavingsAccount> savingsAccounts;
  final List<UserSavingsAccount> userSavingsAccounts;
  final List<InvestmentAccount> investmentAccounts;
  final List<UserInvestmentAccount> userInvestmentAccounts;
  final List<InvestmentPosition> investmentPositions;

  LocalDatabase({
    required this.banks,
    required this.savingsAccounts,
    required this.userSavingsAccounts,
    required this.investmentAccounts,
    required this.userInvestmentAccounts,
    required this.investmentPositions,
  });

  factory LocalDatabase.fromJson(Map<String, dynamic> json) {
    return LocalDatabase(
      banks: (json['banks'] as List)
          .map((b) => Bank.fromJson(b))
          .toList(),
      savingsAccounts: (json['savingsAccounts'] as List)
          .map((sa) => SavingsAccount.fromJson(sa))
          .toList(),
      userSavingsAccounts: (json['userSavingsAccounts'] as List)
          .map((usa) => UserSavingsAccount.fromJson(usa))
          .toList(),
      investmentAccounts: (json['investmentAccounts'] as List)
          .map((ia) => InvestmentAccount.fromJson(ia))
          .toList(),
      userInvestmentAccounts: (json['userInvestmentAccounts'] as List)
          .map((uia) => UserInvestmentAccount.fromJson(uia))
          .toList(),
      investmentPositions: (json['investmentPositions'] as List)
          .map((ip) => InvestmentPosition.fromJson(ip))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'banks': banks.whereType<Bank>().map((b) => b.toJson()).toList(),
    'savingsAccounts': savingsAccounts.whereType<SavingsAccount>().map((sa) => sa.toJson()).toList(),
    'userSavingsAccounts': userSavingsAccounts.whereType<UserSavingsAccount>().map((usa) => usa.toJson()).toList(),
    'investmentAccounts': investmentAccounts.whereType<InvestmentAccount>().map((ia) => ia.toJson()).toList(),
    'userInvestmentAccounts': userInvestmentAccounts.whereType<UserInvestmentAccount>().map((uia) => uia.toJson()).toList(),
    'investmentPositions': investmentPositions.whereType<InvestmentPosition>().map((ip) => ip.toJson()).toList(),
  };

  /// Factory pour retourner une base vide (premier lancement)
  factory LocalDatabase.empty() {
    return LocalDatabase(
      banks: [],
      savingsAccounts: [],
      userSavingsAccounts: [],
      investmentAccounts: [],
      userInvestmentAccounts: [],
      investmentPositions: [],
    );
  }
}