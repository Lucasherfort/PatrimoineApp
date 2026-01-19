import 'package:patrimoine360/models/savings/savings_source.dart';

class UserSavingsAccount {
  final int id;
  final int userId;
  final SavingsSource source;
  final double principal;
  final double interest;

  UserSavingsAccount({
    required this.id,
    required this.userId,
    required this.source,
    required this.principal,
    required this.interest,
  });
}