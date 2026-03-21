import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../services/storage_service.dart';

final loanProvider = StateNotifierProvider<LoanNotifier, List<Loan>>((ref) {
  return LoanNotifier();
});

class LoanNotifier extends StateNotifier<List<Loan>> {
  LoanNotifier() : super([]) {
    loadLoans();
  }

  void loadLoans() {
    state = StorageService.getLoans();
  }

  void addLoan(Loan loan) {
    StorageService.addLoan(loan);
    loadLoans();
  }

  void updateLoan(Loan loan) {
    StorageService.updateLoan(loan);
    loadLoans();
  }

  void deleteLoan(String id) {
    StorageService.deleteLoan(id);
    loadLoans();
  }
}
