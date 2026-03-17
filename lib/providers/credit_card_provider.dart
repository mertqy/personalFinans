import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_card.dart';
import '../services/storage_service.dart';

final creditCardProvider = StateNotifierProvider<CreditCardNotifier, List<CreditCard>>((ref) {
  return CreditCardNotifier();
});

class CreditCardNotifier extends StateNotifier<List<CreditCard>> {
  CreditCardNotifier() : super([]) {
    loadCards();
  }

  void loadCards() {
    state = StorageService.getCreditCards();
  }

  void addCard(CreditCard card) {
    StorageService.addCreditCard(card);
    loadCards();
  }

  void updateCard(CreditCard card) {
    StorageService.updateCreditCard(card);
    loadCards();
  }

  void deleteCard(String id) {
    StorageService.deleteCreditCard(id);
    loadCards();
  }

  void adjustDebt(String id, double amount) {
    StorageService.adjustCreditCardDebt(id, amount);
    loadCards();
  }
}
