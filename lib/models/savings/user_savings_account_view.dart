import 'package:patrimoine/models/savings/savings_source.dart';

class UserSavingsAccountView {
  final int id;
  final double principal;
  final double interestAccrued;
  final SavingsSource source;

  UserSavingsAccountView({
    required this.id,
    required this.principal,
    required this.interestAccrued,
    required this.source,
  });
}