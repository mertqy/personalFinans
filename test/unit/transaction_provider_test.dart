import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finans/providers/transaction_provider.dart';
import 'package:personal_finans/providers/account_provider.dart';
import 'package:personal_finans/models/transaction.dart';
import 'package:personal_finans/models/account.dart';
import 'package:personal_finans/models/subscription.dart';
import 'package:personal_finans/services/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (methodCall) async {
            return null;
          },
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async {
            return '.';
          },
        );

    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    // StorageService.init() calls Hive.initFlutter(), so we should be careful.
    // In unit tests, initFlutter might not work perfectly without a real app environment.
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() {
    container = ProviderContainer();
    StorageService.clearAll();

    // Setup initial account for transaction tests
    final account = Account(
      id: 'acc1',
      userId: 'user1',
      name: 'Test Account',
      type: 'Banka',
      balance: 1000.0,
      currency: 'TRY',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    container.read(accountProvider.notifier).addAccount(account);
  });

  tearDown(() {
    container.dispose();
  });

  group('TransactionNotifier Tests', () {
    test('addTransaction (Expense) should update account balance', () {
      final tx = Transaction(
        id: 'tx1',
        userId: 'user1',
        type: 'expense',
        amount: 200.0,
        category: 'Food',
        description: 'Lunch',
        date: DateTime.now(),
        isPlanned: false,
        accountId: 'acc1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(transactionProvider.notifier).addTransaction(tx);

      final transactions = container.read(transactionProvider);
      expect(transactions.length, 1);

      final account = container.read(accountProvider).first;
      expect(account.balance, 800.0);
    });

    test('addTransaction (Income) should update account balance', () {
      final tx = Transaction(
        id: 'tx2',
        userId: 'user1',
        type: 'income',
        amount: 500.0,
        category: 'Salary',
        description: 'Salary payment',
        date: DateTime.now(),
        isPlanned: false,
        accountId: 'acc1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(transactionProvider.notifier).addTransaction(tx);

      final account = container.read(accountProvider).first;
      expect(account.balance, 1500.0);
    });

    test('deleteTransaction should revert account balance', () {
      final tx = Transaction(
        id: 'tx3',
        userId: 'user1',
        type: 'expense',
        amount: 100.0,
        category: 'Other',
        description: 'Desc',
        date: DateTime.now(),
        isPlanned: false,
        accountId: 'acc1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(transactionProvider.notifier).addTransaction(tx);
      expect(container.read(accountProvider).first.balance, 900.0);

      container.read(transactionProvider.notifier).deleteTransaction(tx);

      expect(container.read(transactionProvider), isEmpty);
      expect(container.read(accountProvider).first.balance, 1000.0);
    });

    test('updateTransaction should adjust original and apply new effect', () {
      final tx = Transaction(
        id: 'tx4',
        userId: 'user1',
        type: 'expense',
        amount: 100.0,
        category: 'Other',
        description: 'Desc',
        date: DateTime.now(),
        isPlanned: false,
        accountId: 'acc1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(transactionProvider.notifier).addTransaction(tx);
      expect(container.read(accountProvider).first.balance, 900.0);

      // CREATE A NEW OBJECT for update (simulating UI behavior)
      final updatedTx = Transaction(
        id: tx.id,
        userId: tx.userId,
        type: tx.type,
        amount: 150.0, // New amount
        category: tx.category,
        description: tx.description,
        date: tx.date,
        isPlanned: tx.isPlanned,
        accountId: tx.accountId,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );

      container.read(transactionProvider.notifier).updateTransaction(updatedTx);

      // Expected balance: 1000 (initial) - 150 (final) = 850
      expect(container.read(accountProvider).first.balance, 850.0);
    });

    test('Transfer between accounts should update both balances', () {
      final acc2 = Account(
        id: 'acc2',
        userId: 'user1',
        name: 'Second Account',
        type: 'Banka',
        balance: 500.0,
        currency: 'TRY',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      container.read(accountProvider.notifier).addAccount(acc2);

      final transferTx = Transaction(
        id: 'transfer1',
        userId: 'user1',
        type: 'transfer',
        amount: 300.0,
        category: 'Transfer',
        description: 'Transfer Desc',
        date: DateTime.now(),
        isPlanned: false,
        accountId: 'acc1',
        toAccountId: 'acc2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(transactionProvider.notifier).addTransaction(transferTx);

      final accounts = container.read(accountProvider);
      final sourceAcc = accounts.firstWhere((a) => a.id == 'acc1');
      final destAcc = accounts.firstWhere((a) => a.id == 'acc2');

      expect(sourceAcc.balance, 700.0);
      expect(destAcc.balance, 800.0);
    });

    test(
      'processRecurring should create transactions for due subscriptions',
      () async {
        final sub = Subscription(
          id: 'sub1',
          userId: 'user1',
          name: 'Netflix',
          amount: 50.0,
          category: 'Entertainment',
          billingDay: DateTime.now().day,
          frequency: 'monthly',
          accountId: 'acc1',
          isActive: true,
          icon: '🎬',
          color: '#E50914',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        );

        StorageService.addSubscription(sub);

        // Before processing
        expect(container.read(transactionProvider).length, 0);
        // Trigger provider initialization
        final notifier = container.read(transactionProvider.notifier);

        // Wait for any deferred processing (like processRecurring in constructor)
        await Future.microtask(() {});
        await Future.delayed(Duration.zero);

        // Also call it manually to be sure (current tests call it manually)
        notifier.processRecurring();

        // Wait again for stability
        await Future.microtask(() {});

        final txs = container.read(transactionProvider);
        // check results
        expect(txs.any((t) => t.description == 'Netflix'), isTrue);

        // Balance should be reduced by 50
        expect(container.read(accountProvider).first.balance, 950.0);
      },
    );
  });
}
