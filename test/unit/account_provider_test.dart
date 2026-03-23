import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finans/providers/account_provider.dart';
import 'package:personal_finans/models/account.dart';
import 'package:personal_finans/services/storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import 'package:flutter/services.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (methodCall) async {
        return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (methodCall) async {
        return '.';
    });

    // Initialize Hive for tests in a temporary directory
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() {
    container = ProviderContainer();
    // Clear all boxes before each test
    StorageService.clearAll();
  });

  tearDown(() {
    container.dispose();
  });

  group('AccountNotifier Tests', () {
    test('Initial state should be empty', () {
      final accounts = container.read(accountProvider);
      expect(accounts, isEmpty);
    });

    test('addAccount should add an account and update state', () {
      final account = Account(
        id: '1',
        userId: 'test_user',
        name: 'Test Account',
        type: 'Banka',
        balance: 1000.0,
        currency: 'TRY',
        icon: 'bank',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(accountProvider.notifier).addAccount(account);
      
      final accounts = container.read(accountProvider);
      expect(accounts.length, 1);
      expect(accounts.first.name, 'Test Account');
      expect(accounts.first.balance, 1000.0);
    });

    test('updateAccount should update an account and update state', () {
      final account = Account(
        id: '1',
        userId: 'test_user',
        name: 'Test Account',
        type: 'Banka',
        balance: 1000.0,
        currency: 'TRY',
        icon: 'bank',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(accountProvider.notifier).addAccount(account);
      
      account.name = 'Updated Account';
      account.balance = 2000.0;
      container.read(accountProvider.notifier).updateAccount(account);
      
      final accounts = container.read(accountProvider);
      expect(accounts.first.name, 'Updated Account');
      expect(accounts.first.balance, 2000.0);
    });

    test('deleteAccount should remove an account and update state', () {
      final account = Account(
        id: '1',
        userId: 'test_user',
        name: 'Test Account',
        type: 'Banka',
        balance: 1000.0,
        currency: 'TRY',
        icon: 'bank',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(accountProvider.notifier).addAccount(account);
      expect(container.read(accountProvider).length, 1);
      
      container.read(accountProvider.notifier).deleteAccount('1');
      expect(container.read(accountProvider), isEmpty);
    });

    test('adjustBalance should update account balance correctly', () {
      final account = Account(
        id: '1',
        userId: 'test_user',
        name: 'Test Account',
        type: 'Banka',
        balance: 1000.0,
        currency: 'TRY',
        icon: 'bank',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      container.read(accountProvider.notifier).addAccount(account);
      
      // Add balance
      container.read(accountProvider.notifier).adjustBalance('1', 500.0);
      expect(container.read(accountProvider).first.balance, 1500.0);
      
      // Subtract balance
      container.read(accountProvider.notifier).adjustBalance('1', -200.0);
      expect(container.read(accountProvider).first.balance, 1300.0);
    });
  });
}
