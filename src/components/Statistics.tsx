'use client';

import React, { useState, useEffect } from 'react';
import type { Transaction } from '@/types';
import { formatCurrency } from '@/lib/utils';
import { 
  ArrowTrendingUpIcon, 
  ArrowTrendingDownIcon, 
  ChartBarIcon,
  ChartPieIcon,
  BanknotesIcon 
} from '@heroicons/react/24/outline';

interface StatisticsProps {
  transactions: Transaction[];
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
  icon: React.ElementType;
  trend?: 'up' | 'down';
  color?: 'blue' | 'green' | 'red' | 'purple';
  delay?: number;
}) {
  const animatedValue = useCountUp(typeof value === 'number' ? value : 0, 1200);
  const displayValue = typeof value === 'number' ? formatCurrency(animatedValue) : value;
  
  const colorMap = {
    blue: 'from-blue-500 to-blue-600 shadow-blue-500/20',
    green: 'from-green-500 to-green-600 shadow-green-500/20',
    red: 'from-red-500 to-red-600 shadow-red-500/20',
    purple: 'from-purple-500 to-purple-600 shadow-purple-500/20'
  };

  return (
    <div 
      className="p-6 rounded-[2rem] glass-strong border border-gray-700/20 bg-gray-800/10 animate-slide-up relative overflow-hidden"
      style={{ animationDelay: `${delay}s` }}
    >
      <div className="flex items-center justify-between mb-4 relative z-10">
        <div className={`w-12 h-12 rounded-2xl bg-gradient-to-br ${colorMap[color]} flex items-center justify-center text-white shadow-xl`}>
          <Icon className="w-6 h-6" />
        </div>
        {trend && (
           <div className={`text-[10px] font-black uppercase tracking-widest px-2 py-1 rounded-full ${trend === 'up' ? 'bg-green-500/20 text-green-400' : 'bg-red-500/20 text-red-400'}`}>
             {trend === 'up' ? 'Yükseliş' : 'Düşüş'}
           </div>
        )}
      </div>
      <h3 className="text-[10px] text-gray-500 uppercase font-black tracking-widest mb-1 pl-1">{title}</h3>
      <p className="text-2xl font-black text-white tracking-tighter">{displayValue}</p>
    </div>
  );
}

function SectionCard({ title, children, delay = 0, icon: Icon }: { title: string; children: React.ReactNode; delay?: number; icon?: React.ElementType }) {
  return (
    <div 
      className="p-8 rounded-[2.5rem] glass-strong border border-gray-700/20 bg-gray-800/10 animate-slide-up"
      style={{ animationDelay: `${delay}s` }}
    >
      <div className="flex items-center gap-3 mb-8">
        {Icon && <Icon className="w-6 h-6 text-white/40" />}
        <h3 className="text-xl font-black text-white tracking-tight">{title}</h3>
      </div>
      {children}
    </div>
  );
}

export default function Statistics({ transactions }: StatisticsProps) {
  const [isClient, setIsClient] = useState(false);
  
  useEffect(() => {
    setIsClient(true);
  }, []);

  const realTransactions = transactions.filter(t => !t.isPlanned);
  
  const totalIncome = realTransactions.filter(t => t.type === 'income').reduce((sum, t) => sum + t.amount, 0);
  const totalExpenses = realTransactions.filter(t => t.type === 'expense').reduce((sum, t) => sum + t.amount, 0);
  const balance = totalIncome - totalExpenses;
  const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;

  const currentYear = new Date().getFullYear();
  const yearlyTransactions = realTransactions.filter(t => new Date(t.date).getFullYear() === currentYear);
  const yearlyIncome = yearlyTransactions.filter(t => t.type === 'income').reduce((sum, t) => sum + t.amount, 0);
  const yearlyExpenses = yearlyTransactions.filter(t => t.type === 'expense').reduce((sum, t) => sum + t.amount, 0);

  const monthlyData: {month: string, income: number, expenses: number, net: number}[] = [];
  for (let i = 4; i >= 0; i--) {
    const d = new Date();
    d.setMonth(d.getMonth() - i);
    const mtx = realTransactions.filter(t => {
      const td = new Date(t.date);
      return td.getMonth() === d.getMonth() && td.getFullYear() === d.getFullYear();
    });
    const inc = mtx.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
    const exp = mtx.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    monthlyData.push({ month: d.toLocaleDateString('tr-TR', { month: 'short' }), income: inc, expenses: exp, net: inc - exp });
  }

  const categoryData = realTransactions.filter(t => t.type === 'expense').reduce((acc, t) => {
    acc[t.category] = (acc[t.category] || 0) + t.amount;
    return acc;
  }, {} as Record<string, number>);

  const topCategories = Object.entries(categoryData).sort(([,a], [,b]) => b - a).slice(0, 5);
  const maxCategoryAmount = Math.max(...Object.values(categoryData), 1);

  if (!isClient) return null;

  return (
    <div className="space-y-10 animate-fade-in pb-20">
      <div className="pt-8 mb-4 px-2">
        <h1 className="text-3xl font-black text-white mb-2 tracking-tighter">Analiz</h1>
        <p className="text-gray-500 text-sm font-medium tracking-tight">Finansal yolculuğunu detaylıca incele.</p>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <StatCard title="Toplam Gelir" value={totalIncome} icon={ArrowTrendingUpIcon} color="green" trend="up" delay={0.1} />
        <StatCard title="Toplam Gider" value={totalExpenses} icon={ArrowTrendingDownIcon} color="red" trend="down" delay={0.2} />
        <StatCard title="Cüzdan" value={balance} icon={BanknotesIcon} color={balance >= 0 ? 'blue' : 'red'} delay={0.3} />
        <StatCard title="Tasarruf" value={`%${savingsRate.toFixed(1)}`} icon={ChartPieIcon} color="purple" delay={0.4} />
      </div>

      <SectionCard title="Aylık Trend" icon={ChartBarIcon} delay={0.5}>
         <div className="space-y-6">
            {monthlyData.map((m) => (
              <div key={m.month} className="flex items-end gap-3">
                 <div className="w-10 text-[10px] font-black uppercase text-gray-500 pb-1">{m.month}</div>
                 <div className="flex-1 flex flex-col gap-1.5 pb-1">
                    <div 
                      className="h-3 bg-green-500 rounded-full transition-all duration-1000 origin-left"
                      style={{ width: `${Math.max((m.income / (Math.max(m.income, m.expenses, 1))) * 100, 2)}%` }}
                    />
                    <div 
                      className="h-3 bg-red-500 rounded-full transition-all duration-1000 origin-left"
                      style={{ width: `${Math.max((m.expenses / (Math.max(m.income, m.expenses, 1))) * 100, 2)}%` }}
                    />
                 </div>
                 <div className="w-16 text-right text-[10px] font-black text-white">
                    {formatCurrency(m.net)}
                 </div>
              </div>
            ))}
         </div>
      </SectionCard>

      {topCategories.length > 0 && (
        <SectionCard title="Harcama Dağılımı" icon={ChartPieIcon} delay={0.6}>
           <div className="space-y-8 mt-2">
              {topCategories.map(([cat, amt]) => (
                <div key={cat} className="group">
                   <div className="flex justify-between items-baseline mb-3 px-1">
                      <p className="text-sm font-black text-white tracking-tight">{cat}</p>
                      <p className="text-xs font-bold text-gray-400">{formatCurrency(amt)}</p>
                   </div>
                   <div className="w-full bg-gray-900/40 rounded-full h-4 overflow-hidden p-1 border border-gray-700/20">
                      <div 
                        className="h-full bg-gradient-to-r from-red-500 to-indigo-500 rounded-full transition-all duration-1000"
                        style={{ width: `${(amt / maxCategoryAmount) * 100}%` }}
                      />
                   </div>
                </div>
              ))}
           </div>
        </SectionCard>
      )}

      <div className="p-8 rounded-[3rem] bg-gradient-to-br from-indigo-600 to-blue-700 text-white shadow-2xl shadow-blue-600/20 relative overflow-hidden animate-slide-up mx-2">
         <div className="relative z-10">
            <p className="text-[10px] font-black uppercase tracking-[0.2em] mb-2 opacity-60">{currentYear} Yılı Özeti</p>
            <div className="flex justify-between items-end">
               <div>
                  <p className="text-xs opacity-80 mb-1 font-bold italic tracking-tighter">Yıllık Kazanç</p>
                  <p className="text-3xl font-black tracking-tighter">{formatCurrency(yearlyIncome)}</p>
               </div>
               <div className="text-right">
                  <p className="text-xs opacity-80 mb-1 font-bold italic tracking-tighter">Yıllık Harcama</p>
                  <p className="text-3xl font-black tracking-tighter">{formatCurrency(yearlyExpenses)}</p>
               </div>
            </div>
         </div>
         <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -mr-10 -mt-10 blur-3xl" />
      </div>
    </div>
  );
}