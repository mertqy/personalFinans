class PremiumLimits {
  static const int freeAccountLimit = 2;
  static const int freeCreditCardLimit = 1;
  static const int freeLoanLimit = 1;
  static const int freeSubscriptionLimit = 3;
  static const int freeBudgetLimit = 1;
  static const int freeGoalLimit = 1;

  /// Check if adding one more item would exceed the free limit.
  /// Returns true if the action is allowed.
  static bool canAdd({
    required int currentCount,
    required int freeLimit,
    required bool isPremium,
  }) {
    if (isPremium) return true;
    return currentCount < freeLimit;
  }
}
