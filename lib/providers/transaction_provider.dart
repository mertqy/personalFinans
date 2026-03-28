import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import 'package:collection/collection.dart';
import '../services/storage_service.dart';
import '../core/utils.dart';
import 'account_provider.dart';
import 'credit_card_provider.dart';
import 'budget_provider.dart';

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
      return TransactionNotifier(ref);
    });

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final Ref _ref;

  TransactionNotifier(this._ref) : super([]) {
    loadTransactions();
    Future.microtask(() => processRecurring());
  }

  void loadTransactions() {
    state = StorageService.getTransactions()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _getAccountCurrency(String accountId) {
    try {
      final acc = _ref
          .read(accountProvider)
          .firstWhere((a) => a.id == accountId);
      return acc.currency;
    } catch (_) {
      return 'TRY';
    }
  }

  String _getCardAccountCurrency(String cardId) {
    try {
      final card = _ref
          .read(creditCardProvider)
          .firstWhere((c) => c.id == cardId);
      final acc = _ref
          .read(accountProvider)
          .firstWhere((a) => a.id == card.accountId);
      return acc.currency;
    } catch (_) {
      return 'TRY';
    }
  }

  void _applyEffect(Transaction tx) {
    if (tx.isPlanned) return;

    final sourceCurrency = tx.creditCardId != null
        ? _getCardAccountCurrency(tx.creditCardId!)
        : _getAccountCurrency(tx.accountId);

    if (tx.type == 'expense') {
      if (tx.creditCardId != null) {
        _ref
            .read(creditCardProvider.notifier)
            .adjustDebt(tx.creditCardId!, tx.amount);
      } else {
        _ref
            .read(accountProvider.notifier)
            .adjustBalance(tx.accountId, -tx.amount);
      }
    } else if (tx.type == 'income') {
      _ref
          .read(accountProvider.notifier)
          .adjustBalance(tx.accountId, tx.amount);
    } else if (tx.type == 'transfer') {
      // Çıkan taraftan parayı çıkar
      if (tx.creditCardId != null) {
        _ref
            .read(creditCardProvider.notifier)
            .adjustDebt(tx.creditCardId!, tx.amount);
      } else {
        _ref
            .read(accountProvider.notifier)
            .adjustBalance(tx.accountId, -tx.amount);
      }

      // Giren hesap veya hedef
      if (tx.toAccountId != null) {
        final destCurrency = _getAccountCurrency(tx.toAccountId!);
        final convertedAmount = AppUtils.convertToBaseCurrency(
          tx.amount,
          sourceCurrency,
          destCurrency,
        );
        _ref
            .read(accountProvider.notifier)
            .adjustBalance(tx.toAccountId!, convertedAmount);
      } else if (tx.toGoalId != null) {
        // Hedefler TRY bazında
        final convertedAmount = AppUtils.convertToBaseCurrency(
          tx.amount,
          sourceCurrency,
          'TRY',
        );
        _ref
            .read(goalProvider.notifier)
            .adjustGoalAmount(tx.toGoalId!, convertedAmount);
      }
    }
  }

  void _revertEffect(Transaction tx) {
    if (tx.isPlanned) return;

    final sourceCurrency = tx.creditCardId != null
        ? _getCardAccountCurrency(tx.creditCardId!)
        : _getAccountCurrency(tx.accountId);

    if (tx.type == 'expense') {
      if (tx.creditCardId != null) {
        _ref
            .read(creditCardProvider.notifier)
            .adjustDebt(tx.creditCardId!, -tx.amount);
      } else {
        _ref
            .read(accountProvider.notifier)
            .adjustBalance(tx.accountId, tx.amount);
      }
    } else if (tx.type == 'income') {
      _ref
          .read(accountProvider.notifier)
          .adjustBalance(tx.accountId, -tx.amount);
    } else if (tx.type == 'transfer') {
      // Revert çıkan taraf
      if (tx.creditCardId != null) {
        _ref
            .read(creditCardProvider.notifier)
            .adjustDebt(tx.creditCardId!, -tx.amount);
      } else {
        _ref
            .read(accountProvider.notifier)
            .adjustBalance(tx.accountId, tx.amount);
      }

      // Revert giren taraf
      if (tx.toAccountId != null) {
        final destCurrency = _getAccountCurrency(tx.toAccountId!);
        final convertedAmount = AppUtils.convertToBaseCurrency(
          tx.amount,
          sourceCurrency,
          destCurrency,
        );
        _ref
            .read(accountProvider.notifier)
            .adjustBalance(tx.toAccountId!, -convertedAmount);
      } else if (tx.toGoalId != null) {
        final convertedAmount = AppUtils.convertToBaseCurrency(
          tx.amount,
          sourceCurrency,
          'TRY',
        );
        _ref
            .read(goalProvider.notifier)
            .adjustGoalAmount(tx.toGoalId!, -convertedAmount);
      }
    }
  }

  bool _canApply(Transaction tx) {
    if (tx.isPlanned) return true;
    if (tx.type == 'expense' || tx.type == 'transfer') {
      if (tx.creditCardId != null) return true; // Cards support negative
      final accList = _ref.read(accountProvider);
      final acc = accList.where((a) => a.id == tx.accountId).firstOrNull;
      if (acc != null && acc.balance < tx.amount) return false;
    }
    return true;
  }

  void addTransaction(Transaction transaction) {
    if (!_canApply(transaction)) {
      // Manual creation is mostly protected by UI, but this is a safety.
      // throw Exception('Yetersiz Bakiye!');
    }
    StorageService.addTransaction(transaction);
    _applyEffect(transaction);
    loadTransactions();
  }

  void updateTransaction(Transaction newTx) {
    final oldTx = StorageService.getTransactions().firstWhere(
      (tx) => tx.id == newTx.id,
      orElse: () => newTx,
    );

    // Check if updated transaction is valid
    // Note: Revert makes it safer to check.
    // In update, it's better to check AFTER revert.

    _revertEffect(oldTx);

    if (!_canApply(newTx)) {
      // Re-apply old because new failed
      _applyEffect(oldTx);
      return;
    }

    StorageService.updateTransaction(newTx);
    _applyEffect(newTx);
    loadTransactions();
  }

  void deleteTransaction(Transaction transaction) {
    _revertEffect(transaction);
    StorageService.deleteTransaction(transaction.id);
    loadTransactions();
  }

  void completePlannedTransaction(Transaction tx) {
    if (!_canApply(tx)) return;
    tx.isPlanned = false;
    tx.updatedAt = DateTime.now();
    StorageService.updateTransaction(tx);
    _applyEffect(tx);
    loadTransactions();
  }

  void processRecurring() {
    final now = DateTime.now();
    bool hasNew = false;

    // 1. İşlem bazlı tekrarlananlar (Transaction Templates)
    final transactions = StorageService.getTransactions();
    final recurringMap = <String, Transaction>{};
    for (var tx in transactions) {
      if (tx.isRecurring == true &&
          tx.isPlanned == false &&
          tx.recurringFrequency != null) {
        final key =
            '${tx.category}_${tx.description}_${tx.accountId}_${tx.creditCardId ?? ''}';
        if (!recurringMap.containsKey(key) ||
            tx.date.isAfter(recurringMap[key]!.date)) {
          recurringMap[key] = tx;
        }
      }
    }

    recurringMap.forEach((key, lastTx) {
      DateTime nextOccur = _calculateNextDate(
        lastTx.date,
        lastTx.recurringFrequency!,
      );

      while (nextOccur.isBefore(now) || _isSameDay(nextOccur, now)) {
        final newTx = Transaction(
          id: AppUtils.generateId(),
          userId: lastTx.userId,
          type: lastTx.type,
          amount: lastTx.amount,
          category: lastTx.category,
          description: lastTx.description,
          date: nextOccur,
          isPlanned: false,
          isRecurring: true,
          recurringFrequency: lastTx.recurringFrequency,
          accountId: lastTx.accountId,
          creditCardId: lastTx.creditCardId,
          toAccountId: lastTx.toAccountId,
          toGoalId: lastTx.toGoalId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (_canApply(newTx)) {
          StorageService.addTransaction(newTx);
          _applyEffect(newTx);
          hasNew = true;
          // Templateler için en son işleme göre bir sonrakini hesapla
          nextOccur = _calculateNextDate(nextOccur, lastTx.recurringFrequency!);
        } else {
          break; // Yetersiz bakiye durumunda silsileyi durdur
        }
        if (nextOccur.isAfter(now.add(const Duration(days: 365)))) break;
      }
    });

    // 2. Abonelik bazlı tekrarlananlar (Subscription Entities)
    final subscriptions = StorageService.getSubscriptions();
    for (var sub in subscriptions) {
      if (!sub.isActive) continue;

      DateTime checkDate;
      if (sub.lastProcessedAt == null) {
        // İlk işlem: Oluşturulma tarihindeki ayın billingDay'ini kontrol et
        checkDate = DateTime(
          sub.createdAt.year,
          sub.createdAt.month,
          sub.billingDay,
        );
        // Eğer billingDay oluşturulma gününden önceyse, o ayı atla (abonelik yeni başladı)
        if (checkDate.isBefore(sub.createdAt) &&
            !_isSameDay(checkDate, sub.createdAt)) {
          checkDate = _calculateNextSubscriptionDate(
            checkDate,
            sub.billingDay,
            sub.frequency,
          );
        }
      } else {
        checkDate = _calculateNextSubscriptionDate(
          sub.lastProcessedAt!,
          sub.billingDay,
          sub.frequency,
        );
      }

      while (checkDate.isBefore(now) || _isSameDay(checkDate, now)) {
        final newTx = Transaction(
          id: AppUtils.generateId(),
          userId: sub.userId,
          type: 'expense',
          amount: sub.amount,
          category: sub.category,
          description: sub.name,
          date: checkDate,
          accountId: sub.accountId,
          isPlanned: false,
          isRecurring: true,
          recurringFrequency: sub.frequency,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (_canApply(newTx)) {
          StorageService.addTransaction(newTx);
          _applyEffect(newTx);
          sub.lastProcessedAt = checkDate;
          sub.save();
          hasNew = true;
          checkDate = _calculateNextSubscriptionDate(
            checkDate,
            sub.billingDay,
            sub.frequency,
          );
        } else {
          break; // Bakiye yetersizse dur
        }
        if (checkDate.isAfter(now.add(const Duration(days: 365)))) break;
      }
    }

    if (hasNew) {
      loadTransactions();
    }
  }

  DateTime _calculateNextSubscriptionDate(
    DateTime lastDate,
    int billingDay,
    String frequency,
  ) {
    if (frequency == 'yearly') {
      return DateTime(lastDate.year + 1, lastDate.month, billingDay);
    } else {
      // Aylık: Bir sonraki ayı bul
      int nextMonth = lastDate.month + 1;
      int nextYear = lastDate.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }

      // Ayın günü validasyonu (örn: 31 çekmeyen aylar)
      int lastDayOfMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      int day = billingDay > lastDayOfMonth ? lastDayOfMonth : billingDay;

      return DateTime(nextYear, nextMonth, day);
    }
  }

  DateTime _calculateNextDate(DateTime date, String frequency) {
    switch (frequency) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        int nextMonth = date.month + 1;
        int nextYear = date.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        int lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        return DateTime(
          nextYear,
          nextMonth,
          date.day > lastDay ? lastDay : date.day,
        );
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(const Duration(days: 30)); // fallback
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
