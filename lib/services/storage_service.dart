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

class StorageService {
  static late HiveAesCipher _cipher;

  static Future<void> init() async {
    await Hive.initFlutter();

    // 1. Setup Encryption Key
    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hive_key');
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_key',
        value: base64UrlEncode(key),
      );
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
        final secureBox = await Hive.openBox<E>(boxName, encryptionCipher: _cipher);
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

  // ==== ACCOUNT OPERATIONS ====
  static Box<Account> get accountBox => Hive.box<Account>('accounts');
  
  static List<Account> getAccounts() => accountBox.values.toList();
  
  static void addAccount(Account account) => accountBox.put(account.id, account);
  
  static void updateAccount(Account account) => accountBox.put(account.id, account);
  
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
  static Box<trx.Transaction> get transactionBox => Hive.box<trx.Transaction>('transactions');
  
  static List<trx.Transaction> getTransactions() => transactionBox.values.toList();
  
  static void addTransaction(trx.Transaction transaction) => transactionBox.put(transaction.id, transaction);
  
  static void updateTransaction(trx.Transaction transaction) => transactionBox.put(transaction.id, transaction);
  
  static void deleteTransaction(String id) => transactionBox.delete(id);

  // ==== CREDIT CARD OPERATIONS ====
  static Box<CreditCard> get creditCardBox => Hive.box<CreditCard>('credit_cards');
  
  static List<CreditCard> getCreditCards() => creditCardBox.values.toList();
  
  static void addCreditCard(CreditCard card) => creditCardBox.put(card.id, card);
  
  static void updateCreditCard(CreditCard card) => creditCardBox.put(card.id, card);
  
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

  // ==== TRANSFER OPERATIONS ====
  static Box<Transfer> get transferBox => Hive.box<Transfer>('transfers');
  
  static List<Transfer> getTransfers() => transferBox.values.toList();
  
  static void addTransfer(Transfer transfer) => transferBox.put(transfer.id, transfer);

  // ==== SUBSCRIPTION OPERATIONS ====
  static Box<Subscription> get subscriptionBox => Hive.box<Subscription>('subscriptions');
  
  static List<Subscription> getSubscriptions() => subscriptionBox.values.toList();
  
  static void addSubscription(Subscription subscription) => subscriptionBox.put(subscription.id, subscription);
  
  static void updateSubscription(Subscription subscription) => subscriptionBox.put(subscription.id, subscription);
  
  static void deleteSubscription(String id) => subscriptionBox.delete(id);

  // ==== EXCHANGE RATE OPERATIONS ====
  static Box<ExchangeRate> get exchangeRateBox => Hive.box<ExchangeRate>('exchange_rates');
  
  static List<ExchangeRate> getExchangeRates() => exchangeRateBox.values.toList();
  
  static void updateExchangeRate(ExchangeRate rate) => exchangeRateBox.put(rate.code, rate);
}

