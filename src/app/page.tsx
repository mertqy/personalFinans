'use client';

import React, { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import { PlusIcon, ArrowUpIcon, ArrowDownIcon, ArrowsRightLeftIcon, UserCircleIcon } from '@heroicons/react/24/outline';
import { formatCurrency, formatDate, generateId, convertToBaseCurrency, EXCHANGE_RATES } from '@/lib/utils';
import type { Transaction, Account, CreditCard, Loan } from '@/types';
import { transactionStorage, accountStorage, creditCardStorage, loanStorage } from '@/lib/storage';
import Modal from '@/components/forms/Modal';
import TransactionForm from '@/components/forms/TransactionForm';
import Link from 'next/link';

const SpendingMap = dynamic(() => import('@/components/SpendingMap'), {
  ssr: false,
  loading: () => <div className="h-full w-full bg-[var(--bg-card)] animate-pulse rounded-2xl" />
});

interface TransactionFormData {
  type: 'income' | 'expense';
  amount: number;
  category: string;
  description: string;
  date: string;
  isRecurring: boolean;
  recurringFrequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  accountId?: string;
  creditCardId?: string;
  location?: { lat: number; lng: number };
}

const CATEGORY_ICONS: Record<string, string> = {
  'Market': '🛒', 'Yemek': '🍔', 'Ulaşım': '🚗', 'Fatura': '⚡',
  'Eğlence': '🎬', 'Sağlık': '💊', 'Giyim': '👕', 'Eğitim': '📚',
  'Kira': '🏠', 'Maaş': '💼', 'Freelance': '💻', 'Yatırım': '📈',
  'Hediye': '🎁', 'Diğer': '📋', 'Abonelik': '🔄', 'Spor': '🏋️',
};

function useHapticFeedback() {
  const triggerSuccess = () => {
    if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
      navigator.vibrate([100, 50, 100]);
    }
  };
  return { triggerSuccess };
}

export default function HomePage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [cards, setCards] = useState<CreditCard[]>([]);
  const [loans, setLoans] = useState<Loan[]>([]);
  const [isIncomeModalOpen, setIsIncomeModalOpen] = useState(false);
  const [isExpenseModalOpen, setIsExpenseModalOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isClient, setIsClient] = useState(false);
  const haptic = useHapticFeedback();

  useEffect(() => {
    setIsClient(true);
    let txs = transactionStorage.getAll();
    let accs = accountStorage.getAll();
    let cds = creditCardStorage.getAll();
    const lns = loanStorage.getAll();

    const result = transactionStorage.processRecurring();
    if (result.updatedTransactions.length > txs.length) {
      txs = result.updatedTransactions;
      if (result.updatedAccounts) accs = accountStorage.getAll();
      if (result.updatedCards) cds = creditCardStorage.getAll();
    }

    setTransactions(txs);
    setAccounts(accs);
    setCards(cds);
    setLoans(lns);
    setIsLoading(false);
  }, []);

  const realTransactions = transactions.filter((t) => !t.isPlanned);
  const totalIncome = realTransactions.filter((t) => t.type === 'income').reduce((s, t) => {
    const acc = accounts.find(a => a.id === t.accountId);
    return s + convertToBaseCurrency(t.amount, acc?.currency || 'TRY', 'TRY');
  }, 0);
  
  const totalExpenses = realTransactions.filter((t) => t.type === 'expense').reduce((s, t) => {
    const acc = accounts.find(a => a.id === t.accountId);
    return s + convertToBaseCurrency(t.amount, acc?.currency || 'TRY', 'TRY');
  }, 0);

  const accountsTotal = accounts.reduce((s, a) => s + convertToBaseCurrency(a.balance, a.currency || 'TRY', 'TRY'), 0);
  const cardsDebt = cards.reduce((s, c) => s + c.currentDebt, 0); // Varsayılan olarak kart ve kredi TRY kabul edildi
  const loansDebt = loans.reduce((s, l) => s + l.remainingAmount, 0);
  const netWorth = accountsTotal - cardsDebt - loansDebt;

  const locTransactions = realTransactions.filter(t => t.location);

  const handleSubmit = async (data: TransactionFormData) => {
    const txId = generateId();
    const newTransaction: Transaction = {
      id: txId,
      userId: 'local-user',
      type: data.type,
      amount: parseFloat(data.amount.toString()),
      category: data.category,
      description: data.description || data.category,
      date: new Date(data.date),
      isRecurring: data.isRecurring,
      recurringFrequency: data.recurringFrequency,
      recurrenceId: data.isRecurring ? txId : undefined,
      location: data.location,
      accountId: data.accountId,
      creditCardId: data.creditCardId,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    if (data.creditCardId && data.type === 'expense') {
      creditCardStorage.adjustDebt(data.creditCardId, data.amount);
      setCards(creditCardStorage.getAll());
    } else if (data.accountId) {
      accountStorage.adjustBalance(data.accountId, data.type === 'income' ? data.amount : -data.amount);
      setAccounts(accountStorage.getAll());
    }

    const updated = transactionStorage.add(newTransaction);
    setTransactions(updated);
    setIsIncomeModalOpen(false);
    setIsExpenseModalOpen(false);
    haptic.triggerSuccess();
  };

  if (!isClient || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#0B0E1A' }}>
        <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen pb-32" style={{ background: 'linear-gradient(180deg, #0B0E1A 0%, #0F1527 100%)' }}>

      {/* Header */}
      <div className="px-6 pt-14 pb-6 animate-fade-in">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs text-[#64748B] uppercase font-black tracking-[0.15em]">Tekrar hoş geldin,</p>
            <h1 className="text-2xl font-black text-white tracking-tight mt-1">Kullanıcı</h1>
          </div>
          <div className="w-12 h-12 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/20 ring-2 ring-indigo-500/30">
            <span className="text-white font-black text-sm">KL</span>
          </div>
        </div>
      </div>

      {/* Net Varlık Kartı */}
      <div className="px-6 mb-6">
        <div className="relative overflow-hidden rounded-[1.5rem] p-6 animate-fade-in" 
             style={{ background: 'linear-gradient(135deg, #1A1F3A 0%, #151B2E 50%, #1A2540 100%)', border: '1px solid rgba(99, 102, 241, 0.15)' }}>
          <div className="relative z-10">
            <p className="text-[10px] text-[#94A3B8] uppercase font-black tracking-[0.2em] mb-2">Toplam Varlık</p>
            <p className={`text-4xl font-black tracking-tighter ${netWorth >= 0 ? 'text-white' : 'text-red-400'}`}>
              {formatCurrency(netWorth)}
            </p>
            <div className="flex items-center gap-4 mt-3 text-[10px]">
              <span className="text-[#94A3B8] font-bold">USD/TRY <span className="text-blue-400">{EXCHANGE_RATES.USD.toFixed(2)}</span></span>
              <span className="text-[#94A3B8] font-bold">ALTIN/TRY <span className="text-yellow-400">{EXCHANGE_RATES.GOLD.toLocaleString('tr-TR')} ₺</span></span>
            </div>
          </div>
          <div className="absolute top-0 right-0 w-40 h-40 bg-indigo-500/10 rounded-full -mr-16 -mt-16 blur-[60px]" />
          <div className="absolute bottom-0 left-0 w-32 h-32 bg-purple-500/10 rounded-full -ml-10 -mb-10 blur-[50px]" />
        </div>
      </div>

      {/* Gelir / Gider Kartları */}
      <div className="px-6 mb-8">
        <div className="flex gap-4">
          <button 
            onClick={() => setIsIncomeModalOpen(true)}
            className="flex-1 flex items-center justify-between rounded-2xl p-4 btn-bounce card-surface"
          >
            <div>
              <p className="text-[10px] text-green-400 uppercase font-black tracking-[0.1em]">Gelir</p>
              <p className="text-xl font-black text-green-400 tracking-tight">+{formatCurrency(totalIncome)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-green-500 flex items-center justify-center shadow-lg shadow-green-500/30">
              <PlusIcon className="w-5 h-5 text-white" />
            </div>
          </button>
          <button 
            onClick={() => setIsExpenseModalOpen(true)}
            className="flex-1 flex items-center justify-between rounded-2xl p-4 btn-bounce card-surface"
          >
            <div>
              <p className="text-[10px] text-red-400 uppercase font-black tracking-[0.1em]">Gider</p>
              <p className="text-xl font-black text-red-400 tracking-tight">-{formatCurrency(totalExpenses)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-red-500 flex items-center justify-center shadow-lg shadow-red-500/30">
              <PlusIcon className="w-5 h-5 text-white" />
            </div>
          </button>
        </div>
      </div>

      {/* Harcama Lokasyonları */}
      {locTransactions.length > 0 && (
        <div className="px-6 mb-8 animate-fade-in">
          <div className="card-elevated p-5">
            <h2 className="text-lg font-black text-white tracking-tight mb-4">Harcama Lokasyonları</h2>
            <div className="h-36 rounded-2xl overflow-hidden mb-4 relative">
              <div className="absolute inset-0 z-10 rounded-2xl cursor-pointer" onClick={() => window.location.href = '/map'} />
              <SpendingMap transactions={realTransactions} />
            </div>
            <div className="space-y-3">
              {(() => {
                const locationGroups: Record<string, { count: number; total: number; lat: number; lng: number }> = {};
                locTransactions.forEach(t => {
                  const key = `${t.location!.lat.toFixed(2)},${t.location!.lng.toFixed(2)}`;
                  if (!locationGroups[key]) locationGroups[key] = { count: 0, total: 0, lat: t.location!.lat, lng: t.location!.lng };
                  locationGroups[key].count++;
                  locationGroups[key].total += t.amount;
                });
                return Object.entries(locationGroups).slice(0, 3).map(([key, data]) => (
                  <div key={key} className="flex items-center justify-between p-3 rounded-xl" style={{ background: 'var(--bg-surface)' }}>
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-blue-500/10 flex items-center justify-center">
                        <span className="text-blue-400 text-sm">📍</span>
                      </div>
                      <div>
                        <p className="text-white font-bold text-sm">Bölge {key.split(',')[0].slice(-2)}</p>
                        <p className="text-[10px] text-[#64748B]">{data.count} İşlem</p>
                      </div>
                    </div>
                    <p className="text-white font-black">{formatCurrency(data.total)}</p>
                  </div>
                ));
              })()}
            </div>
          </div>
        </div>
      )}

      {/* İşlem Geçmişi */}
      <div className="px-6 mb-8">
        <div className="card-elevated p-5">
          <div className="flex items-center justify-between mb-5">
            <h2 className="text-lg font-black text-white tracking-tight">İşlem Geçmişi</h2>
            <span className="text-xs font-bold text-indigo-400 cursor-pointer hover:text-indigo-300 transition-colors">Tümünü Gör</span>
          </div>

          {realTransactions.length === 0 ? (
            <div className="text-center py-12 animate-fade-in">
              <div className="w-16 h-16 glass rounded-2xl flex items-center justify-center mx-auto mb-4">
                <PlusIcon className="w-8 h-8 text-[#64748B]" />
              </div>
              <p className="text-[#64748B] font-bold">Henüz bir işlem yapmadın</p>
            </div>
          ) : (
            <div className="space-y-3">
              {realTransactions
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                .slice(0, 10)
                .map((transaction, index) => {
                  const isIncome = transaction.type === 'income';
                  const account = accounts.find((a) => a.id === transaction.accountId);
                  const icon = CATEGORY_ICONS[transaction.category] || '📋';

                  return (
                    <div
                      key={transaction.id}
                      className="flex items-center justify-between p-3 rounded-xl transition-all hover:scale-[1.01]"
                      style={{ background: 'var(--bg-surface)', animationDelay: `${index * 0.04}s` }}
                    >
                      <div className="flex items-center gap-3">
                        <div className={`w-11 h-11 rounded-xl flex items-center justify-center text-lg shadow-lg ${isIncome ? 'bg-green-500/15' : 'bg-red-500/15'}`}>
                          {icon}
                        </div>
                        <div>
                          <p className="font-bold text-white text-sm tracking-tight">{transaction.category}</p>
                          <p className="text-[10px] text-[#64748B] font-medium">{formatDate(transaction.date)}{transaction.description && transaction.description !== transaction.category ? ` • ${transaction.description}` : ''}</p>
                        </div>
                      </div>
                      <p className={`font-black text-sm tracking-tight ${isIncome ? 'text-green-400' : 'text-red-400'}`}>
                        {isIncome ? '+' : '-'}{formatCurrency(transaction.amount)}
                      </p>
                    </div>
                  );
                })}
            </div>
          )}
        </div>
      </div>

      {/* Alt Aksiyon Butonları */}
      <div className="px-6 mb-6">
        <div className="flex gap-4">
          <button
            onClick={() => setIsExpenseModalOpen(true)}
            className="flex-1 flex flex-col items-center gap-2 p-5 rounded-2xl btn-bounce card-surface"
          >
            <div className="w-12 h-12 rounded-xl bg-indigo-500/15 flex items-center justify-center">
              <PlusIcon className="w-6 h-6 text-indigo-400" />
            </div>
            <span className="text-xs font-bold text-[#94A3B8]">İşlem Ekle</span>
          </button>
          <button
            className="flex-1 flex flex-col items-center gap-2 p-5 rounded-2xl btn-bounce card-surface"
          >
            <div className="w-12 h-12 rounded-xl bg-yellow-500/15 flex items-center justify-center">
              <ArrowsRightLeftIcon className="w-6 h-6 text-yellow-400" />
            </div>
            <span className="text-xs font-bold text-[#94A3B8]">Döviz/Altın Takas</span>
          </button>
        </div>
      </div>

      {/* Modals */}
      {isIncomeModalOpen && (
        <Modal isOpen={isIncomeModalOpen} onClose={() => setIsIncomeModalOpen(false)} title="💰 Gelir Ekle">
          <TransactionForm
            type="income"
            onSubmit={handleSubmit}
            onCancel={() => setIsIncomeModalOpen(false)}
            accounts={accounts}
          />
        </Modal>
      )}
      {isExpenseModalOpen && (
        <Modal isOpen={isExpenseModalOpen} onClose={() => setIsExpenseModalOpen(false)} title="💸 Gider Ekle">
          <TransactionForm
            type="expense"
            onSubmit={handleSubmit}
            onCancel={() => setIsExpenseModalOpen(false)}
            accounts={accounts.filter(a => a.type !== 'savings')}
            creditCards={cards}
          />
        </Modal>
      )}
    </div>
  );
}
