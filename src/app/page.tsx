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

// Count-up animation hook
function useCountUp(end: number, duration: number = 1000) {
  const [count, setCount] = useState(0);
  
  useEffect(() => {
    let startTime: number;
    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      
      // Easing function
      const easeOut = 1 - Math.pow(1 - progress, 3);
      setCount(Math.floor(end * easeOut));
      
      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };
    
    requestAnimationFrame(animate);
  }, [end, duration]);
  
  return count;
}

// Haptic feedback (vibration)
function useHapticFeedback() {
  const triggerLight = () => {
    if ('vibrate' in navigator) {
      navigator.vibrate(50);
    }
  };
  
  const triggerMedium = () => {
    if ('vibrate' in navigator) {
      navigator.vibrate(100);
    }
  };
  
  const triggerSuccess = () => {
    if ('vibrate' in navigator) {
      navigator.vibrate([100, 50, 100]);
    }
  };
  
  return { triggerLight, triggerMedium, triggerSuccess };
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
  const { triggerLight } = useHapticFeedback();
  const animatedAmount = useCountUp(amount, 800);
  
  const handleClick = () => {
    triggerLight();
    onClick();
  };
  
  return (
    <button
      onClick={handleClick}
      className={`flex-1 p-4 rounded-xl text-white font-semibold text-sm transition-all duration-300 
        btn-bounce btn-glow card-hover animate-slide-up ${
        isIncome 
          ? 'bg-gradient-to-r from-green-600 to-green-500 hover:from-green-500 hover:to-green-400' 
          : 'bg-gradient-to-r from-red-600 to-red-500 hover:from-red-500 hover:to-red-400'
      }`}
    >
      <div className="flex items-center justify-center space-x-2">
        <div className={`w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300 float ${
          isIncome ? 'bg-green-400 shadow-lg shadow-green-400/30' : 'bg-red-400 shadow-lg shadow-red-400/30'
        }`}>
          {isIncome ? (
            <ArrowUpIcon className="w-4 h-4 text-white" />
          ) : (
            <ArrowDownIcon className="w-4 h-4 text-white" />
          )}
        </div>
        <div>
          <div className="text-xs opacity-90">{isIncome ? 'Gelir' : 'Gider'}</div>
          <div className="text-sm font-bold animate-count-up">{formatCurrency(animatedAmount)}</div>
        </div>
      </div>
    </button>
  );
}

function TransactionItem({ transaction, index }: { transaction: Transaction; index: number }) {
  const isIncome = transaction.type === 'income';
  
  return (
    <div 
      className={`flex items-center justify-between p-4 bg-gray-800 rounded-xl card-hover glass
        animate-slide-right transition-all duration-300 stagger-${Math.min(index + 1, 4)}`}
      style={{ animationDelay: `${index * 0.1}s` }}
    >
      <div className="flex items-center space-x-3">
        <div className={`w-10 h-10 rounded-full flex items-center justify-center text-xs transition-all duration-300 ${
          isIncome ? 'bg-green-500/20 text-green-400 border border-green-500/30' : 'bg-red-500/20 text-red-400 border border-red-500/30'
        }`}>
          {isIncome ? (
            <ArrowUpIcon className="w-5 h-5" />
          ) : (
            <ArrowDownIcon className="w-5 h-5" />
          )}
        </div>
        <div>
          <p className="font-medium text-white text-sm">{transaction.category}</p>
          <p className="text-xs text-gray-400">{formatDate(transaction.date)}</p>
        </div>
      </div>
      <div className="text-right">
        <p className={`font-bold text-sm animate-count-up ${
          isIncome ? 'text-green-400' : 'text-red-400'
        }`}>
          {isIncome ? '+' : '-'}{formatCurrency(transaction.amount)}
        </p>
      </div>
    </div>
  );
}

function BalanceCard({ balance }: { balance: number }) {
  const animatedBalance = useCountUp(Math.abs(balance), 1200);
  const isPositive = balance >= 0;
  
  return (
    <div className="text-center animate-bounce-in">
      <div className={`inline-flex items-center justify-center space-x-2 px-6 py-3 rounded-2xl glass-strong 
        ${isPositive ? 'border-green-500/30' : 'border-red-500/30'}`}>
        <WalletIcon className={`w-5 h-5 float ${isPositive ? 'text-green-400' : 'text-red-400'}`} />
        <span className={`text-xl font-bold animate-count-up ${
          isPositive ? 'text-green-400' : 'text-red-400'
        }`}>
          {isPositive ? '' : '-'}{formatCurrency(animatedBalance)}
        </span>
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
    <div className="absolute top-full right-0 mt-2 w-48 glass-strong rounded-xl shadow-xl border border-gray-700/50 z-50 animate-slide-up">
      <div className="py-2">
        <button
          onClick={() => {
            onViewChange('home');
            onClose();
          }}
          className={`w-full px-4 py-3 text-left hover:bg-gray-700/50 transition-all duration-200 flex items-center space-x-3 text-sm spring ${
            currentView === 'home' ? 'bg-gray-700/50 text-blue-400' : 'text-white'
          }`}
        >
          <HomeIcon className="w-5 h-5" />
          <span>Ana Sayfa</span>
        </button>
        
        <button
          onClick={() => {
            onViewChange('stats');
            onClose();
          }}
          className={`w-full px-4 py-3 text-left hover:bg-gray-700/50 transition-all duration-200 flex items-center space-x-3 text-sm spring ${
            currentView === 'stats' ? 'bg-gray-700/50 text-blue-400' : 'text-white'
          }`}
        >
          <ChartBarIcon className="w-5 h-5" />
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
  const [isLoading, setIsLoading] = useState(true);
  const menuRef = useRef<HTMLDivElement>(null);
  const { triggerSuccess } = useHapticFeedback();

  useEffect(() => {
    setIsLoading(true);
    setTimeout(() => {
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
      setIsLoading(false);
    }, 1000);
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
    triggerSuccess();
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center space-y-4 animate-fade-in">
          <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
          <div className="w-12 h-12 bg-gray-800 rounded-full flex items-center justify-center mx-auto animate-pulse-custom">
            <WalletIcon className="w-6 h-6 text-blue-400" />
          </div>
          <p className="text-gray-400 text-sm animate-count-up">Finans yükleniyor...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 safe-area-top safe-area-bottom">
      {/* Header */}
      <div className="glass px-4 pt-8 pb-6 animate-slide-up">
          <div className="flex items-center justify-between">
          <div className="flex-1" />
          <div className="text-center">
            <h1 className="text-2xl font-bold text-white mb-2 animate-fade-in">Finans v1.4</h1>
            <BalanceCard balance={balance} />
              </div>
          <div className="flex-1 flex justify-end">
            <div className="relative" ref={menuRef}>
              <button
                onClick={() => setIsMenuOpen(!isMenuOpen)}
                className="p-3 rounded-xl glass-strong hover:bg-gray-700/50 transition-all duration-200 btn-bounce"
              >
                <Bars3Icon className="w-6 h-6 text-white" />
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
      <div className="px-4 pb-24" style={{ paddingTop: '40px' }}>
        {currentView === 'home' ? (
          <div className="animate-fade-in">
            {/* Quick Add Buttons */}
            <div className="mb-6">
              <div className="flex space-x-4">
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
            <div className="animate-slide-up" style={{ animationDelay: '0.2s' }}>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-semibold text-white">
                  Son İşlemler
                </h2>
                <span className="text-sm text-gray-400 glass px-3 py-1 rounded-full">
                  {realTransactions.length}
                </span>
            </div>

              {realTransactions.length === 0 ? (
                <div className="text-center py-12 animate-bounce-in">
                  <div className="w-16 h-16 glass rounded-full flex items-center justify-center mx-auto mb-4 float">
                    <PlusIcon className="w-8 h-8 text-gray-400" />
              </div>
                  <p className="text-gray-400 mb-6 text-lg">İlk işleminizi ekleyin</p>
                  <div className="space-y-3 max-w-xs mx-auto">
                    <button
                      onClick={() => setIsIncomeModalOpen(true)}
                      className="w-full bg-gradient-to-r from-green-600 to-green-500 text-white py-3 rounded-xl font-semibold btn-bounce btn-glow"
                    >
                      💰 Gelir Ekle
                    </button>
                    <button
                      onClick={() => setIsExpenseModalOpen(true)}
                      className="w-full bg-gradient-to-r from-red-600 to-red-500 text-white py-3 rounded-xl font-semibold btn-bounce btn-glow"
                    >
                      💸 Gider Ekle
                    </button>
            </div>
          </div>
              ) : (
                <div className="space-y-3">
                  {realTransactions
                    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                    .slice(0, 15)
                    .map((transaction, index) => (
                      <TransactionItem
                        key={transaction.id}
                        transaction={transaction}
                        index={index}
                      />
                    ))}
            </div>
              )}
            </div>
          </div>
        ) : (
          <div className="animate-fade-in z-50">
            <Statistics transactions={transactions} />
        </div>
        )}
        </div>


      {/* Modals */}
      <Modal
        isOpen={isIncomeModalOpen}
        onClose={() => setIsIncomeModalOpen(false)}
        title="💰 Gelir Ekle"
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
        title="💸 Gider Ekle"
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
