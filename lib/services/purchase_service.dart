import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  // TODO: Replace with your actual RevenueCat API keys
  static const String _androidApiKey = 'goog_YOUR_ANDROID_API_KEY';
  static const String _iosApiKey = 'appl_YOUR_IOS_API_KEY';

  bool _initialized = false;

  Future<void> init(String userId) async {
    if (_initialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    String apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;
    final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(configuration);

    _initialized = true;
  }

  Future<bool> get isPremium async {
    // Suspend check: Always return true
    return true;
  }

  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages;
    } catch (_) {
      return [];
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }
}
