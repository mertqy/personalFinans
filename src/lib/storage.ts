import { Transaction, Account, CreditCard, Loan, Transfer } from '@/types';

// ─── Keys ───────────────────────────────────────────────────────────────────
const KEYS = {
  TRANSACTIONS: 'transactions',
  ACCOUNTS: 'accounts',
  CREDIT_CARDS: 'creditCards',
  LOANS: 'loans',
  TRANSFERS: 'transfers',
} as const;

// ─── Generic helpers ─────────────────────────────────────────────────────────
function load<T>(key: string, reviveDates: (obj: T) => T = (o) => o): T[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = localStorage.getItem(key);
    if (!raw || raw === 'undefined' || raw === 'null') return [];
    const parsed = JSON.parse(raw) as T[];
    return parsed.map(reviveDates);
  } catch (err) {
    console.error(`Storage error for key ${key}:`, err);
    return [];
  }
}

function save<T>(key: string, items: T[]): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(key, JSON.stringify(items));
}

// ─── Date revivers ────────────────────────────────────────────────────────────
function reviveTransaction(t: Transaction): Transaction {
  return {
    ...t,
    date: new Date(t.date),
    createdAt: new Date(t.createdAt),
    updatedAt: new Date(t.updatedAt),
  };
}

function reviveAccount(a: Account): Account {
  return {
    ...a,
    createdAt: new Date(a.createdAt),
    updatedAt: new Date(a.updatedAt),
  };
}

function reviveCreditCard(c: CreditCard): CreditCard {
  return {
    ...c,
    createdAt: new Date(c.createdAt),
    updatedAt: new Date(c.updatedAt),
  };
}

function reviveLoan(l: Loan): Loan {
  return {
    ...l,
    startDate: new Date(l.startDate),
    endDate: new Date(l.endDate),
    createdAt: new Date(l.createdAt),
    updatedAt: new Date(l.updatedAt),
  };
}

function reviveTransfer(t: Transfer): Transfer {
  return {
    ...t,
    date: new Date(t.date),
    createdAt: new Date(t.createdAt),
  };
}

// ─── Transactions ─────────────────────────────────────────────────────────────
export const transactionStorage = {
  getAll: (): Transaction[] => load<Transaction>(KEYS.TRANSACTIONS, reviveTransaction),
  save: (items: Transaction[]): void => save(KEYS.TRANSACTIONS, items),
  add: (item: Transaction): Transaction[] => {
    const items = [item, ...transactionStorage.getAll()];
    save(KEYS.TRANSACTIONS, items);
    return items;
  },
  delete: (id: string): Transaction[] => {
    const items = transactionStorage.getAll().filter((t) => t.id !== id);
    save(KEYS.TRANSACTIONS, items);
    return items;
  },
  processRecurring: (): { updatedTransactions: Transaction[]; updatedAccounts: boolean; updatedCards: boolean } => {
    const transactions = transactionStorage.getAll();
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    
    let currentTransactions = [...transactions];
    let updated = false;
    let balanceUpdated = false;
    let debtUpdated = false;

    // Sadece isRecurring işaretli olan 'ana' veya en güncel işlemleri bulalım
    const recurringTemplates = transactions.filter(t => t.isRecurring);

    recurringTemplates.forEach(template => {
      // Bu seriye ait tüm işlemleri bulup en sonuncusunu belirleyelim
      const series = currentTransactions.filter(t => t.recurrenceId === (template.recurrenceId || template.id) || t.id === (template.recurrenceId || template.id));
      const latest = series.reduce((prev, curr) => new Date(curr.date) > new Date(prev.date) ? curr : prev, template);
      
      let nextDate = new Date(latest.date);
      const frequency = latest.recurringFrequency || 'monthly';

      while (true) {
        // Bir sonraki tarihi hesapla
        if (frequency === 'daily') nextDate.setDate(nextDate.getDate() + 1);
        else if (frequency === 'weekly') nextDate.setDate(nextDate.getDate() + 7);
        else if (frequency === 'monthly') nextDate.setMonth(nextDate.getMonth() + 1);
        else if (frequency === 'yearly') nextDate.setFullYear(nextDate.getFullYear() + 1);

        // Eğer gelecek bir tarihteysek dur
        if (nextDate > now) break;

        // Yeni işlemi oluştur
        const newId = Math.random().toString(36).substr(2, 9);
        const newInstance: Transaction = {
          ...latest,
          id: newId,
          recurrenceId: template.recurrenceId || template.id,
          date: new Date(nextDate),
          createdAt: new Date(),
          updatedAt: new Date(),
          isRecurring: true // Yeni işlem de tekrarlayan olarak kalsın ki bir sonraki döngüde kontrol edilebilsin
        };

        currentTransactions = [newInstance, ...currentTransactions];
        updated = true;

        // Hesap bakiyesini veya kredi kartı borcunu güncelle
        if (newInstance.type === 'expense') {
          if (newInstance.creditCardId) {
            creditCardStorage.adjustDebt(newInstance.creditCardId, newInstance.amount);
            debtUpdated = true;
          } else if (newInstance.accountId) {
            accountStorage.adjustBalance(newInstance.accountId, -newInstance.amount);
            balanceUpdated = true;
          }
        } else if (newInstance.type === 'income' && newInstance.accountId) {
          accountStorage.adjustBalance(newInstance.accountId, newInstance.amount);
          balanceUpdated = true;
        }
      }
    });

    if (updated) {
      save(KEYS.TRANSACTIONS, currentTransactions);
    }

    return { 
      updatedTransactions: currentTransactions, 
      updatedAccounts: balanceUpdated, 
      updatedCards: debtUpdated 
    };
  }
};

// ─── Accounts ─────────────────────────────────────────────────────────────────
export const accountStorage = {
  getAll: (): Account[] => load<Account>(KEYS.ACCOUNTS, reviveAccount),
  save: (items: Account[]): void => save(KEYS.ACCOUNTS, items),
  add: (item: Account): Account[] => {
    const items = [...accountStorage.getAll(), item];
    save(KEYS.ACCOUNTS, items);
    return items;
  },
  update: (updated: Account): Account[] => {
    const items = accountStorage.getAll().map((a) => (a.id === updated.id ? updated : a));
    save(KEYS.ACCOUNTS, items);
    return items;
  },
  delete: (id: string): Account[] => {
    const items = accountStorage.getAll().filter((a) => a.id !== id);
    save(KEYS.ACCOUNTS, items);
    return items;
  },
  adjustBalance: (id: string, delta: number): void => {
    const items = accountStorage.getAll().map((a) =>
      a.id === id ? { ...a, balance: a.balance + delta, updatedAt: new Date() } : a
    );
    save(KEYS.ACCOUNTS, items);
  },
};

// ─── Credit Cards ─────────────────────────────────────────────────────────────
export const creditCardStorage = {
  getAll: (): CreditCard[] => load<CreditCard>(KEYS.CREDIT_CARDS, reviveCreditCard),
  save: (items: CreditCard[]): void => save(KEYS.CREDIT_CARDS, items),
  add: (item: CreditCard): CreditCard[] => {
    const items = [...creditCardStorage.getAll(), item];
    save(KEYS.CREDIT_CARDS, items);
    return items;
  },
  update: (updated: CreditCard): CreditCard[] => {
    const items = creditCardStorage.getAll().map((c) => (c.id === updated.id ? updated : c));
    save(KEYS.CREDIT_CARDS, items);
    return items;
  },
  delete: (id: string): CreditCard[] => {
    const items = creditCardStorage.getAll().filter((c) => c.id !== id);
    save(KEYS.CREDIT_CARDS, items);
    return items;
  },
  adjustDebt: (id: string, delta: number): void => {
    const items = creditCardStorage.getAll().map((c) =>
      c.id === id
        ? { ...c, currentDebt: Math.max(0, c.currentDebt + delta), updatedAt: new Date() }
        : c
    );
    save(KEYS.CREDIT_CARDS, items);
  },
};

// ─── Loans ────────────────────────────────────────────────────────────────────
export const loanStorage = {
  getAll: (): Loan[] => load<Loan>(KEYS.LOANS, reviveLoan),
  save: (items: Loan[]): void => save(KEYS.LOANS, items),
  add: (item: Loan): Loan[] => {
    const items = [...loanStorage.getAll(), item];
    save(KEYS.LOANS, items);
    return items;
  },
  update: (updated: Loan): Loan[] => {
    const items = loanStorage.getAll().map((l) => (l.id === updated.id ? updated : l));
    save(KEYS.LOANS, items);
    return items;
  },
  delete: (id: string): Loan[] => {
    const items = loanStorage.getAll().filter((l) => l.id !== id);
    save(KEYS.LOANS, items);
    return items;
  },
};

// ─── Transfers ────────────────────────────────────────────────────────────────
export const transferStorage = {
  getAll: (): Transfer[] => load<Transfer>(KEYS.TRANSFERS, reviveTransfer),
  add: (item: Transfer): Transfer[] => {
    const items = [item, ...transferStorage.getAll()];
    save(KEYS.TRANSFERS, items);
    return items;
  },
};
