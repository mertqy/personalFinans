import { Budget, Goal } from '@/types';
import { generateId } from './utils';

const STORAGE_KEYS = {
  BUDGETS: 'personalfinans_budgets',
  GOALS: 'personalfinans_goals',
};

// Varsayılan bütçe limitleri (kullanıcıya ait bir veri yoksa kullanılacak)
export const DEFAULT_BUDGETS: Partial<Budget>[] = [
  { categoryId: 'Market', amount: 3000, period: 'monthly' },
  { categoryId: 'Yemek', amount: 1500, period: 'monthly' },
  { categoryId: 'Ulaşım', amount: 1000, period: 'monthly' },
  { categoryId: 'Fatura', amount: 2000, period: 'monthly' },
  { categoryId: 'Eğlence', amount: 800, period: 'monthly' },
  { categoryId: 'Giyim', amount: 1000, period: 'monthly' },
  { categoryId: 'Sağlık', amount: 500, period: 'monthly' },
  { categoryId: 'Eğitim', amount: 750, period: 'monthly' },
  { categoryId: 'Spor', amount: 500, period: 'monthly' },
];

// Varsayılan hedefler (kullanıcıya ait bir veri yoksa)
export const DEFAULT_GOALS: Goal[] = [
  { 
    id: generateId(), 
    userId: 'local-user', 
    title: 'Acil Durum Fonu', 
    icon: '🛡️', 
    targetAmount: 50000, 
    currentAmount: 0, 
    targetDate: new Date('2025-12-31'), 
    isCompleted: false, 
    level: 'Başlangıç', 
    levelColor: '#3B82F6',
    createdAt: new Date(), 
    updatedAt: new Date() 
  },
  { 
    id: generateId(), 
    userId: 'local-user', 
    title: 'Tatil Biriktirme', 
    icon: '✈️', 
    targetAmount: 15000, 
    currentAmount: 0, 
    targetDate: new Date('2025-06-30'), 
    isCompleted: false, 
    level: 'Başlangıç', 
    levelColor: '#22C55E',
    createdAt: new Date(), 
    updatedAt: new Date() 
  },
];

export const budgetStorage = {
  // --- Bütçe Metotları ---
  getBudgets: (): Budget[] => {
    if (typeof window === 'undefined') return [];
    
    const stored = localStorage.getItem(STORAGE_KEYS.BUDGETS);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        return parsed.map((p: any) => ({
          ...p,
          startDate: new Date(p.startDate),
          endDate: p.endDate ? new Date(p.endDate) : undefined,
          createdAt: new Date(p.createdAt),
          updatedAt: new Date(p.updatedAt)
        }));
      } catch (e) {
        console.error('Failed to parse budgets', e);
      }
    }
    
    // Varsayılan bütçeleri oluştur ve kaydet
    const defaultBudgets: Budget[] = DEFAULT_BUDGETS.map(db => ({
      id: generateId(),
      userId: 'local-user',
      categoryId: db.categoryId!,
      amount: db.amount!,
      period: 'monthly',
      startDate: new Date(),
      createdAt: new Date(),
      updatedAt: new Date()
    }));
    
    budgetStorage.saveBudgets(defaultBudgets);
    return defaultBudgets;
  },

  saveBudgets: (budgets: Budget[]) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEYS.BUDGETS, JSON.stringify(budgets));
    }
  },

  updateBudgetLimit: (categoryId: string, amount: number) => {
    const budgets = budgetStorage.getBudgets();
    const existing = budgets.find(b => b.categoryId === categoryId);
    
    if (existing) {
      existing.amount = amount;
      existing.updatedAt = new Date();
    } else {
      budgets.push({
        id: generateId(),
        userId: 'local-user',
        categoryId,
        amount,
        period: 'monthly',
        startDate: new Date(),
        createdAt: new Date(),
        updatedAt: new Date()
      });
    }
    budgetStorage.saveBudgets(budgets);
  },

  // --- Hedef Metotları ---
  getGoals: (): Goal[] => {
    if (typeof window === 'undefined') return [];
    
    const stored = localStorage.getItem(STORAGE_KEYS.GOALS);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        return parsed.map((p: any) => ({
          ...p,
          targetDate: new Date(p.targetDate),
          createdAt: new Date(p.createdAt),
          updatedAt: new Date(p.updatedAt)
        }));
      } catch (e) {
        console.error('Failed to parse goals', e);
      }
    }
    
    // Varsayılan hedefleri oluştur ve kaydet
    budgetStorage.saveGoals(DEFAULT_GOALS);
    return DEFAULT_GOALS;
  },

  saveGoals: (goals: Goal[]) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEYS.GOALS, JSON.stringify(goals));
    }
  },

  addGoal: (goalData: Partial<Goal>) => {
    const goals = budgetStorage.getGoals();
    const newGoal: Goal = {
      id: generateId(),
      userId: 'local-user',
      title: goalData.title || 'Yeni Hedef',
      icon: goalData.icon || '🎯',
      targetAmount: goalData.targetAmount || 1000,
      currentAmount: goalData.currentAmount || 0,
      targetDate: goalData.targetDate || new Date(),
      isCompleted: false,
      level: 'Başlangıç',
      levelColor: '#6C5CE7',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    goals.push(newGoal);
    budgetStorage.saveGoals(goals);
    return newGoal;
  },

  updateGoalProgress: (goalId: string, amountToAdd: number) => {
    const goals = budgetStorage.getGoals();
    const goal = goals.find(g => g.id === goalId);
    
    if (goal) {
      goal.currentAmount += amountToAdd;
      
      // Update level logic
      const ratio = goal.currentAmount / goal.targetAmount;
      if (ratio >= 1) {
        goal.isCompleted = true;
        goal.level = 'Tamamlandı';
        goal.levelColor = '#EAB308'; // Gold
      } else if (ratio >= 0.75) {
        goal.level = 'Usta';
        goal.levelColor = '#22C55E';
      } else if (ratio >= 0.4) {
        goal.level = 'Gelişiyor';
        goal.levelColor = '#F59E0B';
      } else {
        goal.level = 'Başlangıç';
        goal.levelColor = '#3B82F6';
      }
      
      goal.updatedAt = new Date();
      budgetStorage.saveGoals(goals);
    }
  }
};
