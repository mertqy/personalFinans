import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/storage_service.dart';

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, List<Subscription>>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<List<Subscription>> {
  SubscriptionNotifier() : super([]) {
    loadSubscriptions();
  }

  void loadSubscriptions() {
    state = StorageService.getSubscriptions();
  }

  void addSubscription(Subscription subscription) {
    StorageService.addSubscription(subscription);
    loadSubscriptions();
  }

  void updateSubscription(Subscription subscription) {
    StorageService.updateSubscription(subscription);
    loadSubscriptions();
  }

  void deleteSubscription(String id) {
    StorageService.deleteSubscription(id);
    loadSubscriptions();
  }

  void toggleActive(String id) {
    final sub = state.firstWhere((s) => s.id == id);
    sub.isActive = !sub.isActive;
    sub.updatedAt = DateTime.now();
    StorageService.updateSubscription(sub);
    loadSubscriptions();
  }
}
