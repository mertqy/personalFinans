'use client';

import { Transaction } from '@/types';
import { formatCurrency } from '@/lib/utils';
import { 
  ArrowTrendingUpIcon, 
  ArrowTrendingDownIcon, 
  CalendarIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';

interface StatisticsProps {
  transactions: Transaction[];
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
  
  // Bu ay istatistikleri
  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();
  
  const thisMonthTransactions = realTransactions.filter(t => {
    const transactionDate = new Date(t.date);
    return transactionDate.getMonth() === currentMonth && 
           transactionDate.getFullYear() === currentYear;
  });
  
  const monthlyIncome = thisMonthTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const monthlyExpenses = thisMonthTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const monthlyBalance = monthlyIncome - monthlyExpenses;
  
  // Kategori istatistikleri
  const expensesByCategory = realTransactions
    .filter(t => t.type === 'expense')
    .reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + t.amount;
      return acc;
    }, {} as Record<string, number>);
  
  const incomeByCategory = realTransactions
    .filter(t => t.type === 'income')
    .reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + t.amount;
      return acc;
    }, {} as Record<string, number>);
  
  const topExpenseCategories = Object.entries(expensesByCategory)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 3);
  
  const topIncomeCategories = Object.entries(incomeByCategory)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 3);
  
  // Günlük ortalama
  const daysWithTransactions = new Set(
    realTransactions.map(t => new Date(t.date).toDateString())
  ).size;
  
  const avgDailyExpense = daysWithTransactions > 0 ? totalExpenses / daysWithTransactions : 0;
  const avgDailyIncome = daysWithTransactions > 0 ? totalIncome / daysWithTransactions : 0;
  
  return (
    <div className="space-y-4">
      {/* Genel Özet */}
      <div className="grid grid-cols-2 gap-3">
        <div className="bg-gray-800 p-3 rounded-lg">
          <div className="flex items-center space-x-2 mb-2">
            <ArrowTrendingUpIcon className="w-4 h-4 text-green-400" />
            <span className="text-xs text-gray-400">Toplam Gelir</span>
          </div>
          <div className="text-base font-bold text-green-400">
            {formatCurrency(totalIncome)}
          </div>
        </div>
        
        <div className="bg-gray-800 p-3 rounded-lg">
          <div className="flex items-center space-x-2 mb-2">
            <ArrowTrendingDownIcon className="w-4 h-4 text-red-400" />
            <span className="text-xs text-gray-400">Toplam Gider</span>
          </div>
          <div className="text-base font-bold text-red-400">
            {formatCurrency(totalExpenses)}
          </div>
        </div>
        
        <div className="bg-gray-800 p-3 rounded-lg col-span-2">
          <div className="flex items-center space-x-2 mb-2">
            <ChartBarIcon className="w-4 h-4 text-blue-400" />
            <span className="text-xs text-gray-400">Net Bakiye</span>
          </div>
          <div className={`text-lg font-bold ${
            balance >= 0 ? 'text-green-400' : 'text-red-400'
          }`}>
            {formatCurrency(balance)}
          </div>
        </div>
      </div>
      
      {/* Bu Ay İstatistikleri */}
      <div className="bg-gray-800 p-3 rounded-lg">
        <div className="flex items-center space-x-2 mb-3">
          <CalendarIcon className="w-4 h-4 text-blue-400" />
          <span className="text-sm font-semibold text-white">Bu Ay</span>
        </div>
        
        <div className="grid grid-cols-2 gap-3">
          <div>
            <div className="text-xs text-gray-400 mb-1">Gelir</div>
            <div className="text-sm font-bold text-green-400">
              {formatCurrency(monthlyIncome)}
            </div>
          </div>
          <div>
            <div className="text-xs text-gray-400 mb-1">Gider</div>
            <div className="text-sm font-bold text-red-400">
              {formatCurrency(monthlyExpenses)}
            </div>
          </div>
        </div>
        
        <div className="mt-2 pt-2 border-t border-gray-700">
          <div className="text-xs text-gray-400 mb-1">Bu Ay Bakiye</div>
          <div className={`text-base font-bold ${
            monthlyBalance >= 0 ? 'text-green-400' : 'text-red-400'
          }`}>
            {formatCurrency(monthlyBalance)}
          </div>
        </div>
      </div>
      
      {/* Günlük Ortalamalar */}
      <div className="bg-gray-800 p-3 rounded-lg">
        <h3 className="text-sm font-semibold text-white mb-3">Günlük Ortalamalar</h3>
        
        <div className="grid grid-cols-2 gap-3">
          <div>
            <div className="text-xs text-gray-400 mb-1">Günlük Gelir</div>
            <div className="text-sm font-bold text-green-400">
              {formatCurrency(avgDailyIncome)}
            </div>
          </div>
          <div>
            <div className="text-xs text-gray-400 mb-1">Günlük Gider</div>
            <div className="text-sm font-bold text-red-400">
              {formatCurrency(avgDailyExpense)}
            </div>
          </div>
        </div>
      </div>
      
      {/* En Çok Harcama Yapılan Kategoriler */}
      {topExpenseCategories.length > 0 && (
        <div className="bg-gray-800 p-3 rounded-lg">
          <h3 className="text-sm font-semibold text-white mb-3">Top Gider Kategorileri</h3>
          
          <div className="space-y-2">
            {topExpenseCategories.map(([category, amount], index) => (
              <div key={category} className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="flex items-center justify-center w-5 h-5 bg-red-500/20 rounded text-red-400 text-xs font-bold">
                    {index + 1}
                  </div>
                  <span className="text-white text-sm">{category}</span>
                </div>
                <div className="text-red-400 font-semibold text-sm">
                  {formatCurrency(amount)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      
      {/* En Çok Gelir Kategorileri */}
      {topIncomeCategories.length > 0 && (
        <div className="bg-gray-800 p-3 rounded-lg">
          <h3 className="text-sm font-semibold text-white mb-3">Top Gelir Kategorileri</h3>
          
          <div className="space-y-2">
            {topIncomeCategories.map(([category, amount], index) => (
              <div key={category} className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <div className="flex items-center justify-center w-5 h-5 bg-green-500/20 rounded text-green-400 text-xs font-bold">
                    {index + 1}
                  </div>
                  <span className="text-white text-sm">{category}</span>
                </div>
                <div className="text-green-400 font-semibold text-sm">
                  {formatCurrency(amount)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      
      {/* Genel Bilgiler */}
      <div className="bg-gray-800 p-3 rounded-lg">
        <h3 className="text-sm font-semibold text-white mb-3">Genel Bilgiler</h3>
        
        <div className="space-y-2">
          <div className="flex justify-between">
            <span className="text-gray-400 text-xs">Toplam İşlem</span>
            <span className="text-white font-semibold text-xs">{realTransactions.length}</span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-gray-400 text-xs">Gelir İşlem</span>
            <span className="text-green-400 font-semibold text-xs">
              {realTransactions.filter(t => t.type === 'income').length}
            </span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-gray-400 text-xs">Gider İşlem</span>
            <span className="text-red-400 font-semibold text-xs">
              {realTransactions.filter(t => t.type === 'expense').length}
            </span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-gray-400 text-xs">Aktif Gün</span>
            <span className="text-white font-semibold text-xs">{daysWithTransactions}</span>
          </div>
        </div>
      </div>
    </div>
  );
} 