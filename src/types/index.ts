export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Transaction {
  id: string;
  userId: string;
  type: 'income' | 'expense';
  amount: number;
  category: string;
  description: string;
  date: Date;
  isRecurring?: boolean;
  recurringFrequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  recurrenceId?: string;
  location?: {
    lat: number;
    lng: number;
    address?: string;
  };
  isPlanned?: boolean;
  accountId?: string;
  creditCardId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Account {
  id: string;
  name: string;
  type: 'cash' | 'bank' | 'savings' | 'investment';
  balance: number;
  currency: string;
  color: string;
  icon: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreditCard {
  id: string;
  name: string;
  bank: string;
  accountId: string; // Linked bank account
  limit: number;
  currentDebt: number;
  statementDay: number;
  dueDay: number;
  color: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Loan {
  id: string;
  name: string;
  bank: string;
  type: 'personal' | 'mortgage' | 'auto' | 'other';
  accountId: string; // Linked bank account for payments
  totalAmount: number;
  remainingAmount: number;
  monthlyPayment: number;
  interestRate: number;
  startDate: Date;
  endDate: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface Transfer {
  id: string;
  fromAccountId: string;
  toAccountId: string;
  amount: number;
  date: Date;
  description?: string;
  createdAt: Date;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  type: 'income' | 'expense';
}

export interface Budget {
  id: string;
  userId: string;
  categoryId: string;
  amount: number;
  period: 'monthly' | 'yearly';
  startDate: Date;
  endDate?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface Goal {
  id: string;
  userId: string;
  title: string;
  description?: string;
  targetAmount: number;
  currentAmount: number;
  targetDate: Date;
  isCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface DashboardStats {
  totalIncome: number;
  totalExpenses: number;
  balance: number;
  monthlyIncome: number;
  monthlyExpenses: number;
  savingsRate: number;
}

export interface TransactionFilters {
  dateFrom?: Date;
  dateTo?: Date;
  type?: 'income' | 'expense';
  category?: string;
  minAmount?: number;
  maxAmount?: number;
}

export interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    backgroundColor?: string[];
    borderColor?: string[];
  }[];
}