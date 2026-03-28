import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt.dart';
import '../services/storage_service.dart';

final debtProvider = StateNotifierProvider<DebtNotifier, List<Debt>>((ref) {
  return DebtNotifier();
});

class DebtNotifier extends StateNotifier<List<Debt>> {
  DebtNotifier() : super([]) {
    loadDebts();
  }

  void loadDebts() {
    state = StorageService.getDebts();
  }

  void addDebt(Debt debt) {
    StorageService.addDebt(debt);
    loadDebts();
  }

  void updateDebt(Debt debt) {
    StorageService.updateDebt(debt);
    loadDebts();
  }

  void deleteDebt(String id) {
    StorageService.deleteDebt(id);
    loadDebts();
  }
}
