// 📁 services/savings_account_service.dart

import '../models/bank.dart';
import '../models/local_database.dart';
import '../models/patrimoine_type.dart';
import '../models/user_savings_account.dart';
import '../repositories/local_database_repository.dart';
import 'bank_service.dart';

class SavingsAccountService {
  final LocalDatabase db;
  final BankService bankService;

  SavingsAccountService(this.db, this.bankService);

  /// Récupère les comptes épargne d'un utilisateur avec les infos complètes
  List<UserSavingsAccountView> getAccountsForUser(int userId) {
    final accounts = db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .toList();

    return accounts.map((usa) {
      // ✅ 1. Récupérer le SavingsAccount
      final savingsAccount = db.savingsAccounts
          .firstWhere((sa) => sa.id == usa.savingsAccountId);

      // ✅ 2. Récupérer le SavingsAccountType via savingsAccountTypeId
      final savingsAccountType = db.savingsAccountTypes
          .firstWhere((sat) => sat.id == savingsAccount.savingsAccountTypeId);

      // ✅ 3. Récupérer la Bank
      final bank = db.banks
          .firstWhere((b) => b.id == savingsAccount.bankId);

      return UserSavingsAccountView(
        id: usa.id,
        balance: usa.balance,
        interestAccrued: usa.interestAccrued,
        savingsAccountName: savingsAccountType.name, // ✅ Nom du type
        bankName: bank.name,
        interestRate: savingsAccountType.interestRate, // ✅ Bonus
        cap: savingsAccountType.cap, // ✅ Bonus
      );
    }).toList();
  }

  /// Calcule le total épargné par un utilisateur
  double getTotalSavingsForUser(int userId) {
    return db.userSavingsAccounts
        .where((usa) => usa.userId == userId)
        .fold(0.0, (total, account) => total + account.balance);
  }

  /// Crée un nouveau compte épargne pour un utilisateur
  Future<bool> createUserSavingsAccount({
    required int userId,
    required int savingsAccountId,
    required double balance,
    required double interestAccrued,
  }) async {
    try {
      // Générer un nouvel ID
      final newId = db.userSavingsAccounts.isEmpty
          ? 1
          : db.userSavingsAccounts.map((usa) => usa.id).reduce((a, b) => a > b ? a : b) + 1;

      // Créer le nouveau compte
      final newAccount = UserSavingsAccount(
        id: newId,
        userId: userId,
        savingsAccountId: savingsAccountId,
        balance: balance,
        interestAccrued: interestAccrued,
      );

      db.userSavingsAccounts.add(newAccount);

      // Sauvegarder
      final repo = LocalDatabaseRepository();
      await repo.save(db);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Met à jour le solde et les intérêts d'un compte épargne
  Future<bool> updateSavingsAccount({
    required int accountId,
    required double balance,
    required double interestAccrued,
  }) async {
    final index = db.userSavingsAccounts
        .indexWhere((usa) => usa.id == accountId);

    if (index != -1) {
      final oldAccount = db.userSavingsAccounts[index];

      // Vérifier si les valeurs ont changé
      if (oldAccount.balance == balance &&
          oldAccount.interestAccrued == interestAccrued) {
        return false; // Pas de changement
      }

      final updatedAccount = UserSavingsAccount(
        id: oldAccount.id,
        userId: oldAccount.userId,
        savingsAccountId: oldAccount.savingsAccountId,
        balance: balance,
        interestAccrued: interestAccrued,
      );

      db.userSavingsAccounts[index] = updatedAccount;

      final repo = LocalDatabaseRepository();
      await repo.save(db);

      return true;
    }

    return false;
  }

  /// Supprime un compte épargne utilisateur
  Future<bool> deleteSavingsAccount(int accountId) async {
    final index = db.userSavingsAccounts
        .indexWhere((usa) => usa.id == accountId);

    if (index != -1) {
      db.userSavingsAccounts.removeAt(index);

      final repo = LocalDatabaseRepository();
      await repo.save(db);

      return true;
    }

    return false;
  }

  List<Bank> getAvailableBanks(PatrimoineType type)
  {
    final savingsAccountType = db.savingsAccountTypes.firstWhere(
          (sat) => sat.name == type.name,
      orElse: () => throw Exception(
        'Type épargne "${type.name}" introuvable',
      ),
    );

    final bankIds = db.savingsAccounts
        .where((sa) => sa.savingsAccountTypeId == savingsAccountType.id)
        .map((sa) => sa.bankId)
        .toSet()
        .toList();

    return bankService.getByIds(bankIds);
  }
}

/// Vue enrichie d'un compte épargne utilisateur
class UserSavingsAccountView {
  final int id;
  final double balance;
  final double interestAccrued;
  final String savingsAccountName;
  final String bankName;
  final double interestRate; // ✅ Nouveau
  final double cap; // ✅ Nouveau

  UserSavingsAccountView({
    required this.id,
    required this.balance,
    required this.interestAccrued,
    required this.savingsAccountName,
    required this.bankName,
    required this.interestRate,
    required this.cap,
  });
}