import 'bank.dart';
import 'savings_account.dart';
import 'user_savings_account.dart';
import 'investment_account.dart';
import 'user_investment_account.dart';
import 'investment_position.dart';
import 'restaurant_voucher.dart';
import 'user_restaurant_voucher.dart';

class LocalDatabase {
  final List<Bank> banks;
  final List<SavingsAccount> savingsAccounts;
  final List<UserSavingsAccount> userSavingsAccounts;
  final List<InvestmentAccount> investmentAccounts;
  final List<UserInvestmentAccount> userInvestmentAccounts;
  final List<InvestmentPosition> investmentPositions;
  final List<RestaurantVoucher> restaurantVouchers;
  final List<UserRestaurantVoucher> userRestaurantVouchers;

  LocalDatabase({
    required this.banks,
    required this.savingsAccounts,
    required this.userSavingsAccounts,
    required this.investmentAccounts,
    required this.userInvestmentAccounts,
    required this.investmentPositions,
    required this.restaurantVouchers,
    required this.userRestaurantVouchers,
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
      restaurantVouchers: (json['restaurantVouchers'] as List)
          .map((rv) => RestaurantVoucher.fromJson(rv))
          .toList(),
      userRestaurantVouchers: (json['userRestaurantVouchers'] as List)
          .map((urv) => UserRestaurantVoucher.fromJson(urv))
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
    'restaurantVouchers': restaurantVouchers.whereType<RestaurantVoucher>().map((rv) => rv.toJson()).toList(),
    'userRestaurantVouchers': userRestaurantVouchers.whereType<UserRestaurantVoucher>().map((urv) => urv.toJson()).toList(),
  };

  factory LocalDatabase.empty() {
    return LocalDatabase(
      banks: [],
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