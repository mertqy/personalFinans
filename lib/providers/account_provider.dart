import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

final accountProvider = StateNotifierProvider<AccountNotifier, List<Account>>((
  ref,
) {
  return AccountNotifier();
});

class AccountNotifier extends StateNotifier<List<Account>> {
  AccountNotifier() : super([]) {
    loadAccounts();
  }

  void loadAccounts() {
    state = StorageService.getAccounts();
  }

  void addAccount(Account account) {
    StorageService.addAccount(account);
    loadAccounts();
  }

  void updateAccount(Account account) {
    StorageService.updateAccount(account);
    loadAccounts();
  }

  void deleteAccount(String id) {
    StorageService.deleteAccount(id);
    loadAccounts();
  }

  void adjustBalance(String accountId, double amount) {
    StorageService.adjustAccountBalance(accountId, amount);
    loadAccounts();
  }
}
