export const DEFAULT_CATEGORIES = [
  // Gelir Kategorileri
  {
    id: 'income-salary',
    name: 'Maaş',
    icon: '💼',
    type: 'income',
  },
  {
    id: 'income-freelance',
    name: 'Serbest Çalışma',
    icon: '💻',
    type: 'income',
  },
  {
    id: 'income-investment',
    name: 'Yatırım',
    icon: '📈',
    type: 'income',
  },
  {
    id: 'income-other',
    name: 'Diğer Gelir',
    icon: '💰',
    type: 'income',
  },

  // Gider Kategorileri
  {
    id: 'expense-food',
    name: 'Yiyecek',
    icon: '🍽️',
    type: 'expense',
  },
  {
    id: 'expense-transport',
    name: 'Ulaşım',
    icon: '🚗',
    type: 'expense',
  },
  {
    id: 'expense-housing',
    name: 'Barınma',
    icon: '🏠',
    type: 'expense',
  },
  {
    id: 'expense-healthcare',
    name: 'Sağlık',
    icon: '🏥',
    type: 'expense',
  },
  {
    id: 'expense-entertainment',
    name: 'Eğlence',
    icon: '🎬',
    type: 'expense',
  },
  {
    id: 'expense-shopping',
    name: 'Alışveriş',
    icon: '🛍️',
    type: 'expense',
  },
  {
    id: 'expense-utilities',
    name: 'Faturalar',
    icon: '⚡',
    type: 'expense',
  },
  {
    id: 'expense-education',
    name: 'Eğitim',
    icon: '📚',
    type: 'expense',
  },
  {
    id: 'expense-other',
    name: 'Diğer Giderler',
    icon: '💸',
    type: 'expense',
  },
];

export const CURRENCIES = {
  TRY: { symbol: '₺', name: 'Türk Lirası' },
  USD: { symbol: '$', name: 'US Dollar' },
  EUR: { symbol: '€', name: 'Euro' },
  GBP: { symbol: '£', name: 'British Pound' },
};

export const DEFAULT_CURRENCY = 'TRY';

export const DATE_FORMATS = {
  SHORT: 'dd/MM/yyyy',
  LONG: 'dd MMMM yyyy',
  MONTH_YEAR: 'MMMM yyyy',
  CHART: 'MMM yyyy',
};

export const CHART_COLORS = {
  PRIMARY: '#3B82F6',
  SUCCESS: '#10B981',
  WARNING: '#F59E0B',
  DANGER: '#EF4444',
  INFO: '#06B6D4',
  PURPLE: '#8B5CF6',
  PINK: '#EC4899',
  GRAY: '#6B7280',
};

export const RECURRING_FREQUENCIES = [
  { value: 'weekly', label: 'Haftalık' },
  { value: 'monthly', label: 'Aylık' },
  { value: 'yearly', label: 'Yıllık' },
];

export const BUDGET_PERIODS = [
  { value: 'monthly', label: 'Aylık' },
  { value: 'yearly', label: 'Yıllık' },
];

export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/api/auth/login',
    REGISTER: '/api/auth/register',
    LOGOUT: '/api/auth/logout',
    PROFILE: '/api/auth/profile',
  },
  TRANSACTIONS: {
    LIST: '/api/transactions',
    CREATE: '/api/transactions',
    UPDATE: '/api/transactions',
    DELETE: '/api/transactions',
    STATS: '/api/transactions/stats',
  },
  CATEGORIES: {
    LIST: '/api/categories',
    CREATE: '/api/categories',
    UPDATE: '/api/categories',
    DELETE: '/api/categories',
  },
  BUDGETS: {
    LIST: '/api/budgets',
    CREATE: '/api/budgets',
    UPDATE: '/api/budgets',
    DELETE: '/api/budgets',
  },
  GOALS: {
    LIST: '/api/goals',
    CREATE: '/api/goals',
    UPDATE: '/api/goals',
    DELETE: '/api/goals',
  },
}; 