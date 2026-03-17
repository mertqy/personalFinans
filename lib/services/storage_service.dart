import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/transaction.dart' as trx;
import '../models/credit_card.dart';
import '../models/loan.dart';
import '../models/transfer.dart';
import '../models/budget.dart';
import '../models/goal.dart';

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    Hive.registerAdapter(AccountAdapter()); // 0
    Hive.registerAdapter(trx.TransactionAdapter()); // 1
    Hive.registerAdapter(CreditCardAdapter()); // 2
    Hive.registerAdapter(LoanAdapter()); // 3
    Hive.registerAdapter(TransferAdapter()); // 4
    Hive.registerAdapter(BudgetAdapter()); // 5
    Hive.registerAdapter(GoalAdapter()); // 6
    
    // Open Boxes
    await Hive.openBox<Account>('accounts');
    await Hive.openBox<trx.Transaction>('transactions');
    await Hive.openBox<CreditCard>('credit_cards');
    await Hive.openBox<Loan>('loans');
    await Hive.openBox<Transfer>('transfers');
    await Hive.openBox<Budget>('budgets');
    await Hive.openBox<Goal>('goals');
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
}
