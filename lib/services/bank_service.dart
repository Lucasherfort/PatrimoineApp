import '../models/bank.dart';

class BankService {
  final List<Bank> _banks;

  BankService(this._banks);

  /// Toutes les banques
  List<Bank> getAll() {
    return List.unmodifiable(_banks);
  }

  /// Banques correspondant à une liste d'IDs
  List<Bank> getByIds(List<int> bankIds) {
    return _banks
        .where((b) => bankIds.contains(b.id))
        .toList();
  }
}