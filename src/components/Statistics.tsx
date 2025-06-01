'use client';

import { Transaction } from '@/types';
import { formatCurrency } from '@/lib/utils';
import { 
  ArrowTrendingUpIcon, 
  ArrowTrendingDownIcon, 
  CalendarIcon,
  ChartBarIcon,
  ChartPieIcon
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

  // Yıllık istatistikler
  const thisYearTransactions = realTransactions.filter(t => {
    const transactionDate = new Date(t.date);
    return transactionDate.getFullYear() === currentYear;
  });
  
  const yearlyIncome = thisYearTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const yearlyExpenses = thisYearTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);
  
  const yearlyBalance = yearlyIncome - yearlyExpenses;

  // Aylık trend verileri (son 6 ay)
  const monthlyTrend = [];
  for (let i = 5; i >= 0; i--) {
    const targetDate = new Date();
    targetDate.setMonth(targetDate.getMonth() - i);
    const targetMonth = targetDate.getMonth();
    const targetYear = targetDate.getFullYear();
    
    const monthTransactions = realTransactions.filter(t => {
      const transactionDate = new Date(t.date);
      return transactionDate.getMonth() === targetMonth && 
             transactionDate.getFullYear() === targetYear;
    });
    
    const monthIncome = monthTransactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const monthExpense = monthTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    
    monthlyTrend.push({
      month: targetDate.toLocaleDateString('tr-TR', { month: 'short' }),
      income: monthIncome,
      expense: monthExpense,
      balance: monthIncome - monthExpense
    });
  }
  
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

  // Grafik için yardımcı fonksiyonlar
  const maxAmount = Math.max(...monthlyTrend.map(m => Math.max(m.income, m.expense)));
  const getBarHeight = (amount: number) => maxAmount > 0 ? (amount / maxAmount) * 100 : 0;
  
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

      {/* Yıllık Özet */}
      <div className="bg-gray-800 p-3 rounded-lg">
        <div className="flex items-center space-x-2 mb-3">
          <CalendarIcon className="w-4 h-4 text-purple-400" />
          <span className="text-sm font-semibold text-white">{currentYear} Yılı Özeti</span>
        </div>
        
        <div className="grid grid-cols-2 gap-3">
          <div>
            <div className="text-xs text-gray-400 mb-1">Yıllık Gelir</div>
            <div className="text-sm font-bold text-green-400">
              {formatCurrency(yearlyIncome)}
            </div>
          </div>
          <div>
            <div className="text-xs text-gray-400 mb-1">Yıllık Gider</div>
            <div className="text-sm font-bold text-red-400">
              {formatCurrency(yearlyExpenses)}
            </div>
          </div>
        </div>
        
        <div className="mt-2 pt-2 border-t border-gray-700">
          <div className="text-xs text-gray-400 mb-1">Yıllık Net Bakiye</div>
          <div className={`text-base font-bold ${
            yearlyBalance >= 0 ? 'text-green-400' : 'text-red-400'
          }`}>
            {formatCurrency(yearlyBalance)}
          </div>
        </div>

        {/* Yıllık performans yüzdesi */}
        <div className="mt-2 pt-2 border-t border-gray-700">
          <div className="text-xs text-gray-400 mb-1">Tasarruf Oranı</div>
          <div className="text-sm font-bold text-blue-400">
            {yearlyIncome > 0 ? ((yearlyBalance / yearlyIncome) * 100).toFixed(1) : '0.0'}%
          </div>
        </div>
      </div>

      {/* Aylık Trend Grafiği */}
      {monthlyTrend.some(m => m.income > 0 || m.expense > 0) && (
        <div className="bg-gray-800 p-3 rounded-lg">
          <div className="flex items-center space-x-2 mb-3">
            <ChartBarIcon className="w-4 h-4 text-blue-400" />
            <span className="text-sm font-semibold text-white">6 Aylık Trend</span>
          </div>
          
          <div className="space-y-3">
            {/* Chart */}
            <div className="h-32 flex items-end justify-between space-x-1">
              {monthlyTrend.map((month, index) => (
                <div key={index} className="flex-1 flex flex-col items-center space-y-1">
                  <div className="w-full flex flex-col justify-end space-y-0.5" style={{ height: '80px' }}>
                    {/* Gelir barı */}
                    <div 
                      className="w-full bg-green-500 rounded-sm"
                      style={{ height: `${getBarHeight(month.income)}%`, minHeight: month.income > 0 ? '2px' : '0px' }}
                    />
                    {/* Gider barı */}
                    <div 
                      className="w-full bg-red-500 rounded-sm"
                      style={{ height: `${getBarHeight(month.expense)}%`, minHeight: month.expense > 0 ? '2px' : '0px' }}
                    />
                  </div>
                  <div className="text-xs text-gray-400">{month.month}</div>
                </div>
              ))}
            </div>
            
            {/* Legend */}
            <div className="flex justify-center space-x-4">
              <div className="flex items-center space-x-1">
                <div className="w-3 h-3 bg-green-500 rounded-sm"></div>
                <span className="text-xs text-gray-400">Gelir</span>
              </div>
              <div className="flex items-center space-x-1">
                <div className="w-3 h-3 bg-red-500 rounded-sm"></div>
                <span className="text-xs text-gray-400">Gider</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Kategori Pasta Grafiği */}
      {topExpenseCategories.length > 0 && (
        <div className="bg-gray-800 p-3 rounded-lg">
          <div className="flex items-center space-x-2 mb-3">
            <ChartPieIcon className="w-4 h-4 text-orange-400" />
            <span className="text-sm font-semibold text-white">Gider Dağılımı</span>
          </div>
          
          <div className="space-y-2">
            {topExpenseCategories.map(([category, amount], index) => {
              const percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0;
              const colors = ['bg-red-500', 'bg-orange-500', 'bg-yellow-500'];
              
              return (
                <div key={category} className="space-y-1">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-white">{category}</span>
                    <div className="text-right">
                      <div className="text-gray-300 font-semibold">{formatCurrency(amount)}</div>
                      <div className="text-xs text-gray-400">{percentage.toFixed(1)}%</div>
                    </div>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${colors[index] || 'bg-gray-500'}`}
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
      
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
          
          <div className="flex justify-between">
            <span className="text-gray-400 text-xs">Bu Yıl İşlem</span>
            <span className="text-purple-400 font-semibold text-xs">{thisYearTransactions.length}</span>
          </div>
        </div>
      </div>
    </div>
  );
} 