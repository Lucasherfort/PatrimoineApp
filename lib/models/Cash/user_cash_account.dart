import '../liquidity/liquidity_source.dart';

class UserCashAccount {
  final int id;
  final int userId;
  final LiquiditySource source;
  final double amount;

  UserCashAccount({
    required this.id,
    required this.userId,
    required this.source,
    required this.amount,
  });
}