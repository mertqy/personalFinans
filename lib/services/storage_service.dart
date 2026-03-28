import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/transaction.dart' as trx;
import '../models/credit_card.dart';
import '../models/loan.dart';
import '../models/transfer.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/subscription.dart';
import '../models/exchange_rate.dart';
import '../models/debt.dart';

class StorageService {
  static late HiveAesCipher _cipher;

  static Future<void> init() async {
    await Hive.initFlutter();

    // 1. Setup Encryption Key
    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hive_key');
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }

    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);
    _cipher = HiveAesCipher(encryptionKeyUint8List);

    // 2. Register Adapters
    Hive.registerAdapter(AccountAdapter()); // 0
    Hive.registerAdapter(trx.TransactionAdapter()); // 1
    Hive.registerAdapter(CreditCardAdapter()); // 2
    Hive.registerAdapter(LoanAdapter()); // 3
    Hive.registerAdapter(TransferAdapter()); // 4
    Hive.registerAdapter(BudgetAdapter()); // 5
    Hive.registerAdapter(GoalAdapter()); // 6
    Hive.registerAdapter(SubscriptionAdapter()); // 7
    Hive.registerAdapter(ExchangeRateAdapter()); // 8
    Hive.registerAdapter(DebtAdapter()); // 9

    // 3. Open Boxes (Settings remains unencrypted for general app access)
    await Hive.openBox('settings');

    // Sensitive financial data is encrypted with automatic migration
    await _openSecureBox<Account>('accounts');
    await _openSecureBox<trx.Transaction>('transactions');
    await _openSecureBox<CreditCard>('credit_cards');
    await _openSecureBox<Loan>('loans');
    await _openSecureBox<Transfer>('transfers');
    await _openSecureBox<Budget>('budgets');
    await _openSecureBox<Goal>('goals');
    await _openSecureBox<Subscription>('subscriptions');
    await _openSecureBox<ExchangeRate>('exchange_rates');
    await _openSecureBox<Debt>('debts');
  }

  static Future<Box<E>> _openSecureBox<E>(String boxName) async {
    try {
      // Attempt to open securely first
      return await Hive.openBox<E>(boxName, encryptionCipher: _cipher);
    } catch (e) {
      // Catch exceptions due to existing unencrypted box
      // If it throws, we attempt a data migration from unencrypted to encrypted
      try {
        // Open unencrypted
        final unencryptedBox = await Hive.openBox<E>(boxName);
        final unencryptedData = Map<dynamic, E>.from(unencryptedBox.toMap());
        await unencryptedBox.close();

        // Wipe old unencrypted DB file
        await Hive.deleteBoxFromDisk(boxName);

        // Re-open with encryption enabled
        final secureBox = await Hive.openBox<E>(
          boxName,
          encryptionCipher: _cipher,
        );
        if (unencryptedData.isNotEmpty) {
          await secureBox.putAll(unencryptedData);
        }
        return secureBox;
      } catch (migrationError) {
        // Fallback: If even reading unencrypted fails, the box might be corrupted.
        // Best effort: Nuke and recreate securely.
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<E>(boxName, encryptionCipher: _cipher);
      }
    }
  }

  // ==== SETTINGS OPERATIONS ====
  static Box get settingsBox => Hive.box('settings');

  static bool isOnboardingCompleted() {
    return settingsBox.get('onboarding_completed', defaultValue: false);
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    await settingsBox.put('onboarding_completed', value);
  }

  static bool isSkipLogin() {
    return settingsBox.get('skip_login', defaultValue: false);
  }

  static Future<void> setSkipLogin(bool value) async {
    await settingsBox.put('skip_login', value);
  }

  // ==== ACCOUNT OPERATIONS ====
  static Box<Account> get accountBox => Hive.box<Account>('accounts');

  static List<Account> getAccounts() => accountBox.values.toList();

  static void addAccount(Account account) =>
      accountBox.put(account.id, account);

  static void updateAccount(Account account) =>
      accountBox.put(account.id, account);

  static void deleteAccount(String id) => accountBox.delete(id);

  static void adjustAccountBalance(String accountId, double amount) {
    final account = accountBox.get(accountId);
    if (account != null) {
      account.balance += amount;
      account.updatedAt = DateTime.now();
      account.save();
    }
  }

  // ==== TRANSACTION OPERATIONS ====
  static Box<trx.Transaction> get transactionBox =>
      Hive.box<trx.Transaction>('transactions');

  static List<trx.Transaction> getTransactions() =>
      transactionBox.values.toList();

  static void addTransaction(trx.Transaction transaction) =>
      transactionBox.put(transaction.id, transaction);

  static void updateTransaction(trx.Transaction transaction) =>
      transactionBox.put(transaction.id, transaction);

  static void deleteTransaction(String id) => transactionBox.delete(id);

  // ==== CREDIT CARD OPERATIONS ====
  static Box<CreditCard> get creditCardBox =>
      Hive.box<CreditCard>('credit_cards');

  static List<CreditCard> getCreditCards() => creditCardBox.values.toList();

  static void addCreditCard(CreditCard card) =>
      creditCardBox.put(card.id, card);

  static void updateCreditCard(CreditCard card) =>
      creditCardBox.put(card.id, card);

  static void deleteCreditCard(String id) => creditCardBox.delete(id);

  static void adjustCreditCardDebt(String cardId, double amount) {
    final card = creditCardBox.get(cardId);
    if (card != null) {
      card.currentDebt += amount;
      card.updatedAt = DateTime.now();
      card.save();
    }
  }

  // ==== LOAN OPERATIONS ====
  static Box<Loan> get loanBox => Hive.box<Loan>('loans');

  static List<Loan> getLoans() => loanBox.values.toList();

  static void addLoan(Loan loan) => loanBox.put(loan.id, loan);

  static void updateLoan(Loan loan) => loanBox.put(loan.id, loan);

  static void deleteLoan(String id) => loanBox.delete(id);

  // ==== DEBT OPERATIONS ====
  static Box<Debt> get debtBox => Hive.box<Debt>('debts');

  static List<Debt> getDebts() => debtBox.values.toList();

  static void addDebt(Debt debt) => debtBox.put(debt.id, debt);

  static void updateDebt(Debt debt) => debtBox.put(debt.id, debt);

  static void deleteDebt(String id) => debtBox.delete(id);

  // ==== TRANSFER OPERATIONS ====
  static Box<Transfer> get transferBox => Hive.box<Transfer>('transfers');

  static List<Transfer> getTransfers() => transferBox.values.toList();

  static void addTransfer(Transfer transfer) =>
      transferBox.put(transfer.id, transfer);

  // ==== BUDGET OPERATIONS ====
  static Box<Budget> get budgetBox => Hive.box<Budget>('budgets');

  static List<Budget> getBudgets() => budgetBox.values.toList();

  static void addBudget(Budget budget) => budgetBox.put(budget.id, budget);

  static void updateBudget(Budget budget) => budgetBox.put(budget.id, budget);

  static void deleteBudget(String id) => budgetBox.delete(id);

  // ==== GOAL OPERATIONS ====
  static Box<Goal> get goalBox => Hive.box<Goal>('goals');

  static List<Goal> getGoals() => goalBox.values.toList();

  static void addGoal(Goal goal) => goalBox.put(goal.id, goal);

  static void updateGoal(Goal goal) => goalBox.put(goal.id, goal);

  static void deleteGoal(String id) => goalBox.delete(id);

  static void adjustGoalAmount(String goalId, double amount) {
    final goal = goalBox.get(goalId);
    if (goal != null) {
      goal.currentAmount += amount;
      goal.updatedAt = DateTime.now();
      goal.save();
    }
  }

  // ==== SUBSCRIPTION OPERATIONS ====
  static Box<Subscription> get subscriptionBox =>
      Hive.box<Subscription>('subscriptions');

  static List<Subscription> getSubscriptions() =>
      subscriptionBox.values.toList();

  static void addSubscription(Subscription subscription) =>
      subscriptionBox.put(subscription.id, subscription);

  static void updateSubscription(Subscription subscription) =>
      subscriptionBox.put(subscription.id, subscription);

  static void deleteSubscription(String id) => subscriptionBox.delete(id);

  // ==== EXCHANGE RATE OPERATIONS ====
  static Box<ExchangeRate> get exchangeRateBox =>
      Hive.box<ExchangeRate>('exchange_rates');

  static List<ExchangeRate> getExchangeRates() =>
      exchangeRateBox.values.toList();

  static void updateExchangeRate(ExchangeRate rate) =>
      exchangeRateBox.put(rate.code, rate);

  /// Clears all boxes. Useful for testing.
  static void clearAll() {
    Hive.box('settings').clear();
    Hive.box<Account>('accounts').clear();
    Hive.box<trx.Transaction>('transactions').clear();
    Hive.box<CreditCard>('credit_cards').clear();
    Hive.box<Loan>('loans').clear();
    Hive.box<Transfer>('transfers').clear();
    Hive.box<Budget>('budgets').clear();
    Hive.box<Goal>('goals').clear();
    Hive.box<Subscription>('subscriptions').clear();
    Hive.box<ExchangeRate>('exchange_rates').clear();
  }

  // ==== DATA MIGRATION ====
  static Future<void> migrateUserData(
    String oldUserId,
    String newUserId,
  ) async {
    if (oldUserId == newUserId) return;

    // Migrate Accounts
    final accounts = accountBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var acc in accounts) {
      acc.userId = newUserId;
      await acc.save();
    }

    // Migrate Transactions
    final transactions = transactionBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var tx in transactions) {
      tx.userId = newUserId;
      await tx.save();
    }

    // Migrate Credit Cards
    final cards = creditCardBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var card in cards) {
      card.userId = newUserId;
      await card.save();
    }

    // Migrate Transfers
    final transfers = transferBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var trf in transfers) {
      trf.userId = newUserId;
      await trf.save();
    }

    // Migrate Budgets
    final budgets = budgetBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var budget in budgets) {
      budget.userId = newUserId;
      await budget.save();
    }

    // Migrate Goals
    final goals = goalBox.values.where((e) => e.userId == oldUserId).toList();
    for (var goal in goals) {
      goal.userId = newUserId;
      await goal.save();
    }

    // Migrate Subscriptions
    final subscriptions = subscriptionBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var sub in subscriptions) {
      sub.userId = newUserId;
      await sub.save();
    }

    // Migrate Loans
    final loans = loanBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var loan in loans) {
      loan.userId = newUserId;
      await loan.save();
    }

    // Migrate Debts
    final debts = debtBox.values
        .where((e) => e.userId == oldUserId)
        .toList();
    for (var debt in debts) {
      debt.userId = newUserId;
      await debt.save();
    }
  }
}
