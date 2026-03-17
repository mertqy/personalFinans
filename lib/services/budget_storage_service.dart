import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../models/goal.dart';

class BudgetStorageService {
  static Box<Budget> get budgetBox => Hive.box<Budget>('budgets');
  static Box<Goal> get goalBox => Hive.box<Goal>('goals');

  // ==== BUDGET OPERATIONS ====
  static List<Budget> getBudgets() => budgetBox.values.toList();
  
  static void addBudget(Budget budget) {
    budgetBox.put(budget.id, budget);
  }

  static void updateBudget(Budget budget) {
    budgetBox.put(budget.id, budget);
  }
  
  static void deleteBudget(String id) {
    budgetBox.delete(id);
  }

  // ==== GOAL OPERATIONS ====
  static List<Goal> getGoals() => goalBox.values.toList();
  
  static void addGoal(Goal goal) {
    goalBox.put(goal.id, goal);
  }

  static void updateGoal(Goal goal) {
    goalBox.put(goal.id, goal);
  }

  static void deleteGoal(String id) {
    goalBox.delete(id);
  }
}
