import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../services/budget_storage_service.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier();
});

final goalProvider = StateNotifierProvider<GoalNotifier, List<Goal>>((ref) {
  return GoalNotifier();
});

class BudgetNotifier extends StateNotifier<List<Budget>> {
  BudgetNotifier() : super([]) {
    loadBudgets();
  }

  void loadBudgets() {
    state = BudgetStorageService.getBudgets();
  }

  void addBudget(Budget budget) {
    BudgetStorageService.addBudget(budget);
    loadBudgets();
  }

  void updateBudget(Budget budget) {
    BudgetStorageService.updateBudget(budget);
    loadBudgets();
  }

  void deleteBudget(String id) {
    BudgetStorageService.deleteBudget(id);
    loadBudgets();
  }
}

class GoalNotifier extends StateNotifier<List<Goal>> {
  GoalNotifier() : super([]) {
    loadGoals();
  }

  void loadGoals() {
    state = BudgetStorageService.getGoals();
  }

  void addGoal(Goal goal) {
    BudgetStorageService.addGoal(goal);
    loadGoals();
  }

  void updateGoal(Goal goal) {
    BudgetStorageService.updateGoal(goal);
    loadGoals();
  }

  void deleteGoal(String id) {
    BudgetStorageService.deleteGoal(id);
    loadGoals();
  }

  void adjustGoalAmount(String goalId, double amount) {
    final goal = state.where((g) => g.id == goalId).firstOrNull;
    if (goal != null) {
      goal.currentAmount += amount;
      if (goal.currentAmount < 0) goal.currentAmount = 0;
      goal.isCompleted = goal.currentAmount >= goal.targetAmount;
      goal.updatedAt = DateTime.now();
      BudgetStorageService.updateGoal(goal);
      loadGoals();
    }
  }
}
