import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../core/utils.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]) {
    processRecurring();
    loadTransactions();
  }

  void loadTransactions() {
    state = StorageService.getTransactions()..sort((a, b) => b.date.compareTo(a.date));
  }

  void addTransaction(Transaction transaction) {
    StorageService.addTransaction(transaction);
    loadTransactions();
  }

  void updateTransaction(Transaction transaction) {
    StorageService.updateTransaction(transaction);
    loadTransactions();
  }

  void deleteTransaction(String id) {
    StorageService.deleteTransaction(id);
    loadTransactions();
  }

  void processRecurring() {
    // Tüm tekrarlayan giderleri tarihe göre kontrol et
    final now = DateTime.now();
    final transactions = StorageService.getTransactions();
    
    // İşlenenleri tutmak için map
    final recurringMap = <String, Transaction>{};
    for (var tx in transactions) {
      if (tx.isRecurring == true && tx.isPlanned == false) {
        final key = '${tx.category}_${tx.description}';
        if (!recurringMap.containsKey(key) || tx.date.isAfter(recurringMap[key]!.date)) {
          recurringMap[key] = tx; // En son ekleneni tut
        }
      }
    }

    bool hasNew = false;
    recurringMap.forEach((key, lastTx) {
      DateTime nextDate;
      switch (lastTx.recurringFrequency) {
        case 'daily':
          nextDate = lastTx.date.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = lastTx.date.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(lastTx.date.year, lastTx.date.month + 1, lastTx.date.day);
          break;
        case 'yearly':
          nextDate = DateTime(lastTx.date.year + 1, lastTx.date.month, lastTx.date.day);
          break;
        default:
          return;
      }

      // Eğer sonraki tarih geçmişte kaldıysa yeni bir işlem oluştur
      if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
        final newTx = Transaction(
          id: AppUtils.generateId(),
          userId: lastTx.userId,
          type: lastTx.type,
          amount: lastTx.amount,
          category: lastTx.category,
          description: lastTx.description,
          date: nextDate,
          isPlanned: false,
          isRecurring: true,
          recurringFrequency: lastTx.recurringFrequency,
          accountId: lastTx.accountId,
          creditCardId: lastTx.creditCardId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        StorageService.addTransaction(newTx);
        
        // Bakiyeden düş
        if (newTx.type == 'expense') {
           if (newTx.creditCardId != null) {
              StorageService.adjustCreditCardDebt(newTx.creditCardId!, newTx.amount);
           } else {
              StorageService.adjustAccountBalance(newTx.accountId, -newTx.amount);
           }
        } else if (newTx.type == 'income') {
           StorageService.adjustAccountBalance(newTx.accountId, newTx.amount);
        }

        hasNew = true;
      }
    });

    if (hasNew) {
      loadTransactions();
    }
  }
}
