'use client';

import React from 'react';
import { Transaction } from '@/types';
import { formatCurrency } from '@/lib/utils';
import { 
  ArrowTrendingUpIcon, 
  ArrowTrendingDownIcon, 
  CalendarIcon,
  ChartBarIcon,
  ChartPieIcon,
  BanknotesIcon,
  CreditCardIcon
} from '@heroicons/react/24/outline';

interface StatisticsProps {
  transactions: Transaction[];
}

// Count-up animation hook (same as in main page)
function useCountUp(end: number, duration: number = 1000) {
  const [count, setCount] = React.useState(0);
  
  React.useEffect(() => {
    let startTime: number;
    const animate = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      
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

interface MonthData {
  month: string;
  income: number;
  expenses: number;
  net: number;
}

function StatCard({ 
  title, 
  value, 
  icon: Icon, 
  trend, 
  color = 'blue',
  delay = 0 
}: {
  title: string;
  value: string | number;
  icon: any;
  trend?: 'up' | 'down';
  color?: 'blue' | 'green' | 'red' | 'purple';
  delay?: number;
}) {
  const animatedValue = useCountUp(typeof value === 'number' ? value : 0, 1000);
  const displayValue = typeof value === 'number' ? formatCurrency(animatedValue) : value;
  
  const colorClasses = {
    blue: 'from-blue-500/20 to-blue-600/20 border-blue-500/30 text-blue-400',
    green: 'from-green-500/20 to-green-600/20 border-green-500/30 text-green-400',
    red: 'from-red-500/20 to-red-600/20 border-red-500/30 text-red-400',
    purple: 'from-purple-500/20 to-purple-600/20 border-purple-500/30 text-purple-400'
  };

  return (
    <div 
      className={`p-4 rounded-xl bg-gradient-to-br ${colorClasses[color]} border 
        card-hover animate-slide-up transition-all duration-300`}
      style={{ animationDelay: `${delay}s` }}
    >
      <div className="flex items-center justify-between mb-3">
        <div className={`p-2 rounded-lg bg-gradient-to-r ${colorClasses[color]} float`}>
          <Icon className="w-5 h-5" />
        </div>
        {trend && (
          <div className={`flex items-center ${trend === 'up' ? 'text-green-400' : 'text-red-400'}`}>
            {trend === 'up' ? (
              <ArrowTrendingUpIcon className="w-4 h-4" />
            ) : (
              <ArrowTrendingDownIcon className="w-4 h-4" />
            )}
          </div>
        )}
      </div>
      <h3 className="text-sm text-gray-400 mb-1">{title}</h3>
      <p className="text-xl font-bold text-white animate-count-up">{displayValue}</p>
    </div>
  );
}

function ChartCard({ 
  title, 
  children, 
  delay = 0 
}: { 
  title: string; 
  children: React.ReactNode;
  delay?: number;
}) {
  return (
    <div 
      className="p-6 rounded-xl glass-strong border border-gray-600/30 card-hover animate-slide-up"
      style={{ animationDelay: `${delay}s` }}
    >
      <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
        <ChartBarIcon className="w-5 h-5 text-blue-400" />
        <span>{title}</span>
      </h3>
      {children}
    </div>
  );
}

export default function Statistics({ transactions }: StatisticsProps) {
  const realTransactions = transactions.filter(t => !t.isPlanned);
  
  // Genel istatistikler
  const totalIncome = realTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const totalExpenses = realTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const balance = totalIncome - totalExpenses;
  const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;

  // Yıllık istatistikler
  const currentYear = new Date().getFullYear();
  const yearlyTransactions = realTransactions.filter(t => 
    new Date(t.date).getFullYear() === currentYear
  );
  
  const yearlyIncome = yearlyTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const yearlyExpenses = yearlyTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  // Aylık trend (son 6 ay)
  const monthlyData: MonthData[] = [];
  for (let i = 5; i >= 0; i--) {
    const date = new Date();
    date.setMonth(date.getMonth() - i);
    const monthTransactions = realTransactions.filter(t => {
      const tDate = new Date(t.date);
      return tDate.getMonth() === date.getMonth() && 
             tDate.getFullYear() === date.getFullYear();
    });
    
    const income = monthTransactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const expenses = monthTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    monthlyData.push({
      month: date.toLocaleDateString('tr-TR', { month: 'short' }),
      income,
      expenses,
      net: income - expenses
    });
  }

  // Kategori analizi
  const categoryData = realTransactions
    .filter(t => t.type === 'expense')
    .reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + t.amount;
      return acc;
    }, {} as Record<string, number>);

  const topCategories = Object.entries(categoryData)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 5);

  const maxCategoryAmount = Math.max(...Object.values(categoryData));

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="text-center mb-8 animate-slide-up">
        <h1 className="text-2xl font-bold text-white mb-2">📊 İstatistikler</h1>
        <p className="text-gray-400">Finansal durumunuzu analiz edin</p>
      </div>

      {/* Ana İstatistikler */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <StatCard
          title="Toplam Gelir"
          value={totalIncome}
          icon={ArrowTrendingUpIcon}
          color="green"
          trend="up"
          delay={0.1}
        />
        <StatCard
          title="Toplam Gider"
          value={totalExpenses}
          icon={ArrowTrendingDownIcon}
          color="red"
          trend="down"
          delay={0.2}
        />
        <StatCard
          title="Net Bakiye"
          value={balance}
          icon={BanknotesIcon}
          color={balance >= 0 ? 'green' : 'red'}
          delay={0.3}
        />
        <StatCard
          title="Tasarruf Oranı"
          value={`%${savingsRate.toFixed(1)}`}
          icon={ChartPieIcon}
          color="purple"
          delay={0.4}
        />
      </div>

      {/* Yıllık Özet */}
      <ChartCard title={`${currentYear} Yılı Özeti`} delay={0.5}>
        <div className="grid grid-cols-2 gap-4">
          <div className="text-center p-4 rounded-lg glass border border-green-500/30">
            <ArrowTrendingUpIcon className="w-8 h-8 text-green-400 mx-auto mb-2 float" />
            <p className="text-sm text-gray-400">Yıllık Gelir</p>
            <p className="text-lg font-bold text-green-400 animate-count-up">
              {formatCurrency(yearlyIncome)}
            </p>
          </div>
          <div className="text-center p-4 rounded-lg glass border border-red-500/30">
            <ArrowTrendingDownIcon className="w-8 h-8 text-red-400 mx-auto mb-2 float" />
            <p className="text-sm text-gray-400">Yıllık Gider</p>
            <p className="text-lg font-bold text-red-400 animate-count-up">
              {formatCurrency(yearlyExpenses)}
            </p>
          </div>
        </div>
        <div className="mt-4 p-4 rounded-lg glass border border-blue-500/30 text-center">
          <p className="text-sm text-gray-400 mb-1">Yıllık Net</p>
          <p className={`text-xl font-bold animate-count-up ${
            (yearlyIncome - yearlyExpenses) >= 0 ? 'text-green-400' : 'text-red-400'
          }`}>
            {formatCurrency(yearlyIncome - yearlyExpenses)}
          </p>
        </div>
      </ChartCard>

      {/* 6 Aylık Trend */}
      <ChartCard title="6 Aylık Trend" delay={0.6}>
        <div className="space-y-3">
          {monthlyData.map((month, index) => {
            const maxAmount = Math.max(...monthlyData.map(m => Math.max(m.income, m.expenses)));
            const incomeWidth = maxAmount > 0 ? (month.income / maxAmount) * 100 : 0;
            const expenseWidth = maxAmount > 0 ? (month.expenses / maxAmount) * 100 : 0;
            
            return (
              <div 
                key={month.month} 
                className="animate-slide-right"
                style={{ animationDelay: `${0.1 * index}s` }}
              >
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm text-gray-400 font-medium">{month.month}</span>
                  <span className={`text-sm font-bold ${
                    month.net >= 0 ? 'text-green-400' : 'text-red-400'
                  }`}>
                    {formatCurrency(Math.abs(month.net))}
                  </span>
                </div>
                
                <div className="space-y-1">
                  {/* Gelir bar */}
                  <div className="flex items-center space-x-2">
                    <div className="w-8 text-xs text-green-400">G</div>
                    <div className="flex-1 bg-gray-700 rounded-full h-2 overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-green-500 to-green-400 rounded-full transition-all duration-1000 ease-out"
                        style={{ width: `${incomeWidth}%` }}
                      />
                    </div>
                    <div className="text-xs text-gray-400 w-16 text-right">
                      {formatCurrency(month.income)}
                    </div>
                  </div>
                  
                  {/* Gider bar */}
                  <div className="flex items-center space-x-2">
                    <div className="w-8 text-xs text-red-400">G</div>
                    <div className="flex-1 bg-gray-700 rounded-full h-2 overflow-hidden">
                      <div 
                        className="h-full bg-gradient-to-r from-red-500 to-red-400 rounded-full transition-all duration-1000 ease-out"
                        style={{ width: `${expenseWidth}%` }}
                      />
                    </div>
                    <div className="text-xs text-gray-400 w-16 text-right">
                      {formatCurrency(month.expenses)}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </ChartCard>

      {/* Top Kategoriler */}
      {topCategories.length > 0 && (
        <ChartCard title="En Çok Harcama Yapılan Kategoriler" delay={0.7}>
          <div className="space-y-3">
            {topCategories.map(([category, amount], index) => {
              const percentage = maxCategoryAmount > 0 ? (amount / maxCategoryAmount) * 100 : 0;
              
              return (
                <div 
                  key={category}
                  className="animate-slide-right"
                  style={{ animationDelay: `${0.1 * index}s` }}
                >
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm text-white font-medium">{category}</span>
                    <span className="text-sm font-bold text-red-400">
                      {formatCurrency(amount)}
                    </span>
                  </div>
                  <div className="bg-gray-700 rounded-full h-3 overflow-hidden">
                    <div 
                      className="h-full bg-gradient-to-r from-red-500 to-red-400 rounded-full transition-all duration-1000 ease-out"
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </ChartCard>
      )}

      {/* Genel Bilgiler */}
      <ChartCard title="Genel Bilgiler" delay={0.8}>
        <div className="grid grid-cols-2 gap-4 text-center">
          <div className="p-4 rounded-lg glass">
            <CalendarIcon className="w-8 h-8 text-blue-400 mx-auto mb-2 float" />
            <p className="text-sm text-gray-400">Toplam İşlem</p>
            <p className="text-lg font-bold text-white animate-count-up">
              {realTransactions.length}
            </p>
          </div>
          
          <div className="p-4 rounded-lg glass">
            <CreditCardIcon className="w-8 h-8 text-purple-400 mx-auto mb-2 float" />
            <p className="text-sm text-gray-400">Ortalama İşlem</p>
            <p className="text-lg font-bold text-white animate-count-up">
              {realTransactions.length > 0 
                ? formatCurrency((totalIncome + totalExpenses) / realTransactions.length)
                : formatCurrency(0)
              }
            </p>
          </div>
        </div>
        
        {realTransactions.length > 0 && (
          <div className="mt-4 p-4 rounded-lg glass text-center">
            <p className="text-sm text-gray-400 mb-1">Günlük Ortalama Harcama</p>
            <p className="text-lg font-bold text-red-400 animate-count-up">
              {formatCurrency(totalExpenses / Math.max(1, 
                Math.ceil((Date.now() - new Date(realTransactions[realTransactions.length - 1].date).getTime()) / (1000 * 60 * 60 * 24))
              ))}
            </p>
          </div>
        )}
      </ChartCard>
    </div>
  );
} 