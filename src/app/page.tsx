'use client';

import { useState, useEffect, useRef } from 'react';
import { PlusIcon, ArrowUpIcon, ArrowDownIcon, WalletIcon, Bars3Icon, HomeIcon, ChartBarIcon } from '@heroicons/react/24/outline';
import { formatCurrency, formatDate, generateId } from '@/lib/utils';
import { Transaction } from '@/types';
import Modal from '@/components/forms/Modal';
import TransactionForm from '@/components/forms/TransactionForm';
import Statistics from '@/components/Statistics';

interface TransactionFormData {
  type: 'income' | 'expense';
  amount: number;
  category: string;
  description: string;
  date: string;
  isRecurring: boolean;
  recurringFrequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
}

function QuickAddButton({ 
  type, 
  onClick,
  amount 
}: { 
  type: 'income' | 'expense'; 
  onClick: () => void;
  amount: number;
}) {
  const isIncome = type === 'income';
  return (
    <button
      onClick={onClick}
      className={`flex-1 p-3 rounded-xl text-white font-semibold text-sm transition-all duration-200 active:scale-95 ${
        isIncome 
          ? 'bg-green-600 hover:bg-green-500' 
          : 'bg-red-600 hover:bg-red-500'
      }`}
    >
      <div className="flex items-center justify-center space-x-2">
        <div className={`w-6 h-6 rounded-full flex items-center justify-center ${
          isIncome ? 'bg-green-500' : 'bg-red-500'
        }`}>
          {isIncome ? (
            <ArrowUpIcon className="w-3 h-3" />
          ) : (
            <ArrowDownIcon className="w-3 h-3" />
          )}
        </div>
        <div>
          <div className="text-xs opacity-90">{isIncome ? 'Gelir' : 'Gider'}</div>
          <div className="text-xs font-bold">{formatCurrency(amount)}</div>
        </div>
      </div>
    </button>
  );
}

function TransactionItem({ transaction }: { transaction: Transaction }) {
  const isIncome = transaction.type === 'income';
  
  return (
    <div className="flex items-center justify-between p-3 bg-gray-800 rounded-lg">
      <div className="flex items-center space-x-3">
        <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs ${
          isIncome ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'
        }`}>
          {isIncome ? (
            <ArrowUpIcon className="w-4 h-4" />
          ) : (
            <ArrowDownIcon className="w-4 h-4" />
          )}
        </div>
        <div>
          <p className="font-medium text-white text-sm">{transaction.category}</p>
          <p className="text-xs text-gray-400">{formatDate(transaction.date)}</p>
        </div>
      </div>
      <div className="text-right">
        <p className={`font-bold text-sm ${
          isIncome ? 'text-green-400' : 'text-red-400'
        }`}>
          {isIncome ? '+' : '-'}{formatCurrency(transaction.amount)}
        </p>
      </div>
    </div>
  );
}

function MenuDropdown({ 
  isOpen, 
  onClose, 
  currentView, 
  onViewChange 
}: { 
  isOpen: boolean; 
  onClose: () => void;
  currentView: 'home' | 'stats';
  onViewChange: (view: 'home' | 'stats') => void;
}) {
  if (!isOpen) return null;

  return (
    <div className="absolute top-full right-0 mt-2 w-40 bg-gray-800 rounded-lg shadow-xl border border-gray-700 z-50">
      <div className="py-1">
        <button
          onClick={() => {
            onViewChange('home');
            onClose();
          }}
          className={`w-full px-3 py-2 text-left hover:bg-gray-700 transition-colors flex items-center space-x-2 text-sm ${
            currentView === 'home' ? 'bg-gray-700 text-blue-400' : 'text-white'
          }`}
        >
          <HomeIcon className="w-4 h-4" />
          <span>Ana Sayfa</span>
        </button>
        
        <button
          onClick={() => {
            onViewChange('stats');
            onClose();
          }}
          className={`w-full px-3 py-2 text-left hover:bg-gray-700 transition-colors flex items-center space-x-2 text-sm ${
            currentView === 'stats' ? 'bg-gray-700 text-blue-400' : 'text-white'
          }`}
        >
          <ChartBarIcon className="w-4 h-4" />
          <span>İstatistikler</span>
        </button>
      </div>
    </div>
  );
}

export default function HomePage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isIncomeModalOpen, setIsIncomeModalOpen] = useState(false);
  const [isExpenseModalOpen, setIsExpenseModalOpen] = useState(false);
  const [isClient, setIsClient] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [currentView, setCurrentView] = useState<'home' | 'stats'>('home');
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setIsClient(true);
    const savedTransactions = localStorage.getItem('transactions');
    if (savedTransactions) {
      try {
        const parsed = JSON.parse(savedTransactions);
        setTransactions(parsed.map((t: Transaction) => ({
          ...t,
          date: new Date(t.date)
        })));
      } catch (error) {
        console.error('Error loading transactions:', error);
      }
    }
  }, []);

  useEffect(() => {
    if (isClient && transactions.length > 0) {
      localStorage.setItem('transactions', JSON.stringify(transactions));
    }
  }, [transactions, isClient]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsMenuOpen(false);
      }
    }

    if (isMenuOpen) {
      document.addEventListener('mousedown', handleClickOutside);
      return () => {
        document.removeEventListener('mousedown', handleClickOutside);
      };
    }
  }, [isMenuOpen]);

  const realTransactions = isClient ? transactions.filter(t => !t.isPlanned) : [];
  const totalIncome = realTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const totalExpenses = realTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const balance = totalIncome - totalExpenses;

  const handleSubmit = async (data: TransactionFormData) => {
    if (!isClient) return;
    
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
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    setTransactions(prev => [newTransaction, ...prev]);
    setIsIncomeModalOpen(false);
    setIsExpenseModalOpen(false);
  };

  if (!isClient) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 safe-area-top safe-area-bottom">
      {/* Header */}
      <div className="bg-gray-900 px-4 pt-8 pb-4">
        <div className="flex items-center justify-between">
          <div className="flex-1" />
          <div className="text-center">
            <h1 className="text-xl font-bold text-white mb-1">Finans</h1>
            <div className="flex items-center justify-center space-x-2">
              <WalletIcon className="w-4 h-4 text-blue-400" />
              <span className={`text-lg font-bold ${
                balance >= 0 ? 'text-green-400' : 'text-red-400'
              }`}>
                {formatCurrency(balance)}
              </span>
            </div>
          </div>
          <div className="flex-1 flex justify-end">
            <div className="relative" ref={menuRef}>
              <button
                onClick={() => setIsMenuOpen(!isMenuOpen)}
                className="p-2 rounded-lg bg-gray-800 hover:bg-gray-700 transition-colors"
              >
                <Bars3Icon className="w-5 h-5 text-white" />
              </button>
              
              <MenuDropdown
                isOpen={isMenuOpen}
                onClose={() => setIsMenuOpen(false)}
                currentView={currentView}
                onViewChange={setCurrentView}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Ana İçerik */}
      <div className="px-4 pb-4">
        {currentView === 'home' ? (
          <>
            {/* Quick Add Buttons */}
            <div className="mb-4">
              <div className="flex space-x-2">
                <QuickAddButton
                  type="income"
                  onClick={() => setIsIncomeModalOpen(true)}
                  amount={totalIncome}
                />
                <QuickAddButton
                  type="expense"
                  onClick={() => setIsExpenseModalOpen(true)}
                  amount={totalExpenses}
                />
              </div>
            </div>

            {/* Transactions List */}
            <div>
              <h2 className="text-base font-semibold text-white mb-3">
                Son İşlemler ({realTransactions.length})
              </h2>
              
              {realTransactions.length === 0 ? (
                <div className="text-center py-8">
                  <div className="w-12 h-12 bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-3">
                    <PlusIcon className="w-6 h-6 text-gray-400" />
                  </div>
                  <p className="text-gray-400 mb-4 text-sm">İlk işleminizi ekleyin</p>
                  <div className="space-y-2">
                    <button
                      onClick={() => setIsIncomeModalOpen(true)}
                      className="w-full bg-green-600 text-white py-2 rounded-lg font-semibold text-sm"
                    >
                      Gelir Ekle
                    </button>
                    <button
                      onClick={() => setIsExpenseModalOpen(true)}
                      className="w-full bg-red-600 text-white py-2 rounded-lg font-semibold text-sm"
                    >
                      Gider Ekle
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  {realTransactions
                    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                    .slice(0, 15)
                    .map((transaction) => (
                      <TransactionItem
                        key={transaction.id}
                        transaction={transaction}
                      />
                    ))}
                </div>
              )}
            </div>
          </>
        ) : (
          <Statistics transactions={transactions} />
        )}
      </div>

      {/* Modals */}
      <Modal
        isOpen={isIncomeModalOpen}
        onClose={() => setIsIncomeModalOpen(false)}
        title="Gelir Ekle"
      >
        <TransactionForm
          type="income"
          onSubmit={handleSubmit}
          onCancel={() => setIsIncomeModalOpen(false)}
        />
      </Modal>

      <Modal
        isOpen={isExpenseModalOpen}
        onClose={() => setIsExpenseModalOpen(false)}
        title="Gider Ekle"
      >
        <TransactionForm
          type="expense"
          onSubmit={handleSubmit}
          onCancel={() => setIsExpenseModalOpen(false)}
        />
      </Modal>
    </div>
  );
}
