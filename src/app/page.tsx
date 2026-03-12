'use client';

import React, { useState, useEffect } from 'react';
import { PlusIcon, ArrowUpIcon, ArrowDownIcon } from '@heroicons/react/24/outline';
import { formatCurrency, formatDate, generateId } from '@/lib/utils';
import type { Transaction, Account, CreditCard, Loan } from '@/types';
import { transactionStorage, accountStorage, creditCardStorage, loanStorage } from '@/lib/storage';
import Modal from '@/components/forms/Modal';
import TransactionForm from '@/components/forms/TransactionForm';

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
}

function useCountUp(end: number, duration: number = 1000) {
  const [count, setCount] = useState(0);
  useEffect(() => {
    let startTime: number;
    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      const easeOut = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(end * easeOut));
      if (progress < 1) requestAnimationFrame(animate);
    };
    requestAnimationFrame(animate);
  }, [end, duration]);
  return count;
}

function useHapticFeedback() {
  const triggerSuccess = () => { 
    if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
      navigator.vibrate([100, 50, 100]);
    }
  };
  return { triggerSuccess };
}

function SummaryRow({ income, expenses }: { income: number; expenses: number }) {
  return (
    <div className="flex gap-4 mt-8">
      <div className="flex-1 glass rounded-3xl p-5 border border-green-500/10 bg-green-500/5">
        <div className="flex items-center gap-2 mb-1">
           <div className="w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center">
              <ArrowUpIcon className="w-3.5 h-3.5 text-green-400" />
           </div>
           <p className="text-[10px] text-green-300/60 uppercase font-black tracking-widest">Gelir</p>
        </div>
        <p className="text-xl font-bold text-green-400 tracking-tight">{formatCurrency(income)}</p>
      </div>
      <div className="flex-1 glass rounded-3xl p-5 border border-red-500/10 bg-red-500/5">
        <div className="flex items-center gap-2 mb-1">
           <div className="w-6 h-6 rounded-full bg-red-500/20 flex items-center justify-center">
              <ArrowDownIcon className="w-3.5 h-3.5 text-red-400" />
           </div>
           <p className="text-[10px] text-red-300/60 uppercase font-black tracking-widest">Gider</p>
        </div>
        <p className="text-xl font-bold text-red-400 tracking-tight">{formatCurrency(expenses)}</p>
      </div>
    </div>
  );
}

function TransactionItem({ transaction, accounts, cards, index }: {
  transaction: Transaction;
  accounts: Account[];
  cards: CreditCard[];
  index: number;
}) {
  const isIncome = transaction.type === 'income';
  const account = accounts.find((a) => a.id === transaction.accountId);
  const card = cards.find((c) => c.id === transaction.creditCardId);

  return (
    <div
      className={`flex items-center justify-between p-5 rounded-[2rem] glass-strong border border-gray-700/20 bg-gray-800/20 animate-slide-up stagger-${Math.min(index + 1, 4)}`}
      style={{ animationDelay: `${index * 0.05}s` }}
    >
      <div className="flex items-center gap-4">
        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg ${isIncome ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}`}>
          {isIncome ? <ArrowUpIcon className="w-6 h-6" /> : <ArrowDownIcon className="w-6 h-6" />}
        </div>
        <div>
          <p className="font-black text-white text-base tracking-tight">{transaction.category}</p>
          <div className="flex items-center gap-2">
            <p className="text-[10px] text-gray-500 uppercase font-bold tracking-wider">{formatDate(transaction.date)}</p>
            {account && (
              <span className="text-[9px] px-2 py-0.5 rounded-full font-black uppercase tracking-tighter" style={{ backgroundColor: `${account.color}20`, color: account.color }}>
                {account.name}
              </span>
            )}
            {card && (
              <span className="text-[9px] px-2 py-0.5 rounded-full bg-purple-500/20 text-purple-400 font-black uppercase tracking-tighter">
                {card.name}
              </span>
            )}
          </div>
        </div>
      </div>
      <p className={`font-black text-lg tracking-tighter ${isIncome ? 'text-green-400' : 'text-red-400'}`}>
        {isIncome ? '+' : '-'}{formatCurrency(transaction.amount)}
      </p>
    </div>
  );
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
    const txs = transactionStorage.getAll();
    const accs = accountStorage.getAll();
    const cds = creditCardStorage.getAll();
    const lns = loanStorage.getAll();
    setTransactions(txs);
    setAccounts(accs);
    setCards(cds);
    setLoans(lns);
    setIsLoading(false);
  }, []);

  const realTransactions = transactions.filter((t) => !t.isPlanned);
  const totalIncome = realTransactions.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const totalExpenses = realTransactions.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
  
  const accountsTotal = accounts.reduce((s, a) => s + a.balance, 0);
  const cardsDebt = cards.reduce((s, c) => s + c.currentDebt, 0);
  const loansDebt = loans.reduce((s, l) => s + l.remainingAmount, 0);
  
  const netWorth = accountsTotal - cardsDebt - loansDebt; 

  const netWorthAnimated = useCountUp(netWorth, 1500);

  const handleSubmit = async (data: TransactionFormData) => {
    const newTransaction: Transaction = {
      id: generateId(),
      userId: 'local-user',
      type: data.type,
      amount: parseFloat(data.amount.toString()),
      category: data.category,
      description: data.description || data.category,
      date: new Date(data.date),
      isRecurring: data.isRecurring,
      recurringFrequency: data.recurringFrequency,
      accountId: data.accountId,
      creditCardId: data.creditCardId,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    if (data.accountId) {
      accountStorage.adjustBalance(data.accountId, data.type === 'income' ? data.amount : -data.amount);
      setAccounts(accountStorage.getAll());
    }
    if (data.creditCardId && data.type === 'expense') {
      creditCardStorage.adjustDebt(data.creditCardId, data.amount);
      setCards(creditCardStorage.getAll());
    }

    const updated = transactionStorage.add(newTransaction);
    setTransactions(updated);
    setIsIncomeModalOpen(false);
    setIsExpenseModalOpen(false);
    haptic.triggerSuccess();
  };

  if (!isClient || isLoading) {
    return (
      <div className="min-h-screen bg-[#0a0a0f] flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 via-gray-900 to-[#0a0a0f] pb-32">
      {/* Mobile Top Bar */}
      <div className="px-6 pt-14 pb-10 animate-fade-in relative overflow-hidden">
        <div className="relative z-10 text-center">
            <h1 className="text-2xl font-black text-white/40 mb-10 tracking-tighter uppercase italic">Finans</h1>
            <p className="text-[10px] text-gray-500 uppercase font-black tracking-[0.2em] mb-2">Net Varlık</p>
            <p className={`text-6xl font-black tracking-tighter ${netWorth >= 0 ? 'text-white' : 'text-red-500'}`}>
              {formatCurrency(netWorthAnimated)}
            </p>
            <SummaryRow income={totalIncome} expenses={totalExpenses} />
        </div>
        
        <div className="absolute -top-20 -left-20 w-80 h-80 bg-blue-600/10 rounded-full blur-[120px]" />
        <div className="absolute -top-20 -right-20 w-80 h-80 bg-purple-600/10 rounded-full blur-[120px]" />
      </div>

      <div className="px-6 space-y-8">
        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-4">
           <button 
             onClick={() => setIsIncomeModalOpen(true)}
             className="bg-green-500 text-white rounded-[2rem] p-6 font-black text-lg btn-bounce shadow-xl shadow-green-500/20"
           >
             Gelir Ekle
           </button>
           <button 
             onClick={() => setIsExpenseModalOpen(true)}
             className="bg-red-500 text-white rounded-[2rem] p-6 font-black text-lg btn-bounce shadow-xl shadow-red-500/20"
           >
             Gider Ekle
           </button>
        </div>

        <div>
          <div className="flex items-center justify-between mb-6 px-1">
            <h2 className="text-xl font-black text-white tracking-tight">Son İşlemler</h2>
            <span className="text-[10px] font-black text-gray-500 uppercase tracking-widest glass px-3 py-1 rounded-full">{realTransactions.length} işlem</span>
          </div>

          {realTransactions.length === 0 ? (
            <div className="text-center py-20 bg-gray-800/20 rounded-[3rem] border border-gray-700/10 animate-fade-in">
              <div className="w-20 h-20 glass rounded-[2rem] flex items-center justify-center mx-auto mb-6 float border border-gray-700/30">
                <PlusIcon className="w-10 h-10 text-gray-600" />
              </div>
              <p className="text-gray-500 font-bold mb-1 px-10 leading-tight">Henüz bir işlem yapmadın</p>
            </div>
          ) : (
            <div className="space-y-4">
              {realTransactions
                .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                .slice(0, 50)
                .map((transaction, index) => (
                  <TransactionItem
                    key={transaction.id}
                    transaction={transaction}
                    accounts={accounts}
                    cards={cards}
                    index={index}
                  />
                ))}
            </div>
          )}
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
