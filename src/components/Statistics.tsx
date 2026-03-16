'use client';

import React, { useState, useEffect } from 'react';
import type { Transaction } from '@/types';
import { formatCurrency } from '@/lib/utils';
import { 
  ArrowTrendingUpIcon, 
  ArrowTrendingDownIcon, 
  ChartBarIcon,
  ChartPieIcon,
  BanknotesIcon,
  ArrowPathIcon
} from '@heroicons/react/24/outline';
import { 
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell,
  AreaChart, Area, LineChart, Line, CartesianGrid
} from 'recharts';

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
      className="p-8 rounded-[2.5rem] glass-strong border border-gray-700/20 bg-gray-800/10 animate-slide-up overflow-hidden"
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

const COLORS = ['#ef4444', '#f59e0b', '#10b981', '#3b82f6', '#8b5cf6'];

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

  // Abonelikler (Tekrarlayan İşlemler)
  const subscriptions = realTransactions.filter(t => t.type === 'expense' && t.isRecurring);

  const currentYear = new Date().getFullYear();
  const yearlyTransactions = realTransactions.filter(t => new Date(t.date).getFullYear() === currentYear);
  const yearlyIncome = yearlyTransactions.filter(t => t.type === 'income').reduce((sum, t) => sum + t.amount, 0);
  const yearlyExpenses = yearlyTransactions.filter(t => t.type === 'expense').reduce((sum, t) => sum + t.amount, 0);

  // Generate Monthly Data for Bar & Line Charts
  const monthlyData: {month: string, income: number, expenses: number, net: number, expenseDiff: number}[] = [];
  
  // Önceki ayı başlangıç olarak al (7 ay öncesi)
  const getExpensesForMonthsAgo = (monthsAgo: number) => {
    const d = new Date();
    d.setMonth(d.getMonth() - monthsAgo);
    const mtx = realTransactions.filter(t => {
      const td = new Date(t.date);
      return td.getMonth() === d.getMonth() && td.getFullYear() === d.getFullYear();
    });
    return mtx.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
  };

  let previousExpense = getExpensesForMonthsAgo(6);

  for (let i = 5; i >= 0; i--) {
    const d = new Date();
    d.setMonth(d.getMonth() - i);
    const mtx = realTransactions.filter(t => {
      const td = new Date(t.date);
      return td.getMonth() === d.getMonth() && td.getFullYear() === d.getFullYear();
    });
    const inc = mtx.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
    const exp = mtx.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
    const net = inc - exp;
    
    const expenseDiff = exp - previousExpense;
    previousExpense = exp;

    monthlyData.push({ 
      month: d.toLocaleDateString('tr-TR', { month: 'short' }).toUpperCase(), 
      income: inc, 
      expenses: exp, 
      net: net,
      expenseDiff: expenseDiff
    });
  }

  // Generate Category Data for Pie Check (Donut)
  const categoryData = realTransactions.filter(t => t.type === 'expense').reduce((acc, t) => {
    acc[t.category] = (acc[t.category] || 0) + t.amount;
    return acc;
  }, {} as Record<string, number>);

  const pieData = Object.entries(categoryData)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 5); // Top 5 categories

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-gray-800 border border-gray-700 p-4 rounded-xl shadow-xl">
          <p className="text-white font-bold mb-2">{label}</p>
          {payload.map((entry: any, index: number) => {
            const isDiff = entry.name === 'expenseDiff';
            const val = entry.value;
            const formatted = formatCurrency(Math.abs(val));
            const diffPrefix = isDiff && val > 0 ? '+' : isDiff && val < 0 ? '-' : '';
            return (
              <p key={index} className="text-sm font-medium" style={{ color: entry.color }}>
                {entry.name === 'income' ? 'Gelir: ' : entry.name === 'expenses' ? 'Gider: ' : entry.name === 'net' ? 'Net: ' : isDiff ? 'Gider Değişimi: ' : ''}
                {diffPrefix}{formatted}
              </p>
            );
          })}
        </div>
      );
    }
    return null;
  };

  const CustomPieTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-gray-800 border border-gray-700 p-3 rounded-xl shadow-xl">
          <p className="text-white font-bold text-sm">{payload[0].name}</p>
          <p className="text-sm font-medium" style={{ color: payload[0].payload.fill }}>
            {formatCurrency(payload[0].value)}
          </p>
        </div>
      );
    }
    return null;
  };

  if (!isClient) return null;

  return (
    <div className="space-y-8 animate-fade-in pb-20">
      <div className="pt-8 mb-4 px-2">
        <h1 className="text-3xl font-black text-white mb-2 tracking-tighter">Analiz</h1>
        <p className="text-gray-500 text-sm font-medium tracking-tight">Finansal yolculuğunu detaylıca incele.</p>
      </div>

      {/* İstatistik Kartları */}
      <div className="grid grid-cols-2 gap-4">
        <StatCard title="Toplam Gelir" value={totalIncome} icon={ArrowTrendingUpIcon} color="green" trend="up" delay={0.1} />
        <StatCard title="Toplam Gider" value={totalExpenses} icon={ArrowTrendingDownIcon} color="red" trend="down" delay={0.2} />
        <StatCard title="Cüzdan" value={balance} icon={BanknotesIcon} color={balance >= 0 ? 'blue' : 'red'} delay={0.3} />
        <StatCard title="Tasarruf" value={`%${savingsRate.toFixed(1)}`} icon={ChartPieIcon} color="purple" delay={0.4} />
      </div>

      {/* Aylık Trend (Çubuk Grafiği) */}
      <SectionCard title="Aylık Gelir/Gider (Son 6 Ay)" icon={ChartBarIcon} delay={0.5}>
         <div className="h-64 w-full -ml-4">
           <ResponsiveContainer width="100%" height="100%">
             <BarChart data={monthlyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
               <CartesianGrid strokeDasharray="3 3" stroke="#374151" vertical={false} />
               <XAxis dataKey="month" stroke="#9CA3AF" fontSize={10} axisLine={false} tickLine={false} />
               <YAxis stroke="#9CA3AF" fontSize={10} axisLine={false} tickLine={false} tickFormatter={(val) => `₺${val >= 1000 ? (val/1000).toFixed(0)+'k' : val}`} />
               <Tooltip content={<CustomTooltip />} cursor={{fill: 'transparent'}}/>
               <Bar dataKey="income" fill="#10B981" radius={[4, 4, 0, 0]} barSize={12} />
               <Bar dataKey="expenses" fill="#EF4444" radius={[4, 4, 0, 0]} barSize={12} />
             </BarChart>
           </ResponsiveContainer>
         </div>
      </SectionCard>

      {/* Harcama Dağılımı (Donut Grafiği) */}
      {pieData.length > 0 && (
        <SectionCard title="Harcama Dağılımı (Top 5)" icon={ChartPieIcon} delay={0.6}>
           <div className="h-64 w-full relative">
             <ResponsiveContainer width="100%" height="100%">
               <PieChart>
                 <Pie
                   data={pieData}
                   cx="50%"
                   cy="50%"
                   innerRadius={60}
                   outerRadius={80}
                   paddingAngle={5}
                   dataKey="value"
                   stroke="none"
                 >
                   {pieData.map((entry, index) => (
                     <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                   ))}
                 </Pie>
                 <Tooltip content={<CustomPieTooltip />} />
               </PieChart>
             </ResponsiveContainer>
             {/* Center Text for Donut */}
             <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-[10px] text-gray-500 font-bold uppercase tracking-widest">En Yüksek</span>
                <span className="text-white font-black text-lg truncate px-4 text-center">{pieData[0].name}</span>
             </div>
           </div>
           
           {/* Custom Legend */}
           <div className="grid grid-cols-2 gap-x-4 gap-y-3 mt-4">
             {pieData.map((entry, index) => (
               <div key={entry.name} className="flex items-center gap-2">
                 <div className="w-3 h-3 rounded-full" style={{ backgroundColor: COLORS[index % COLORS.length] }} />
                 <p className="text-xs text-white truncate flex-1 font-medium">{entry.name}</p>
               </div>
             ))}
           </div>
        </SectionCard>
      )}

      {/* Gider Değişimi İlerlemesi (Çizgi/Alan Grafiği) */}
      <SectionCard title="Aylık Gider Değişimi" icon={ArrowTrendingUpIcon} delay={0.7}>
         <div className="h-64 w-full -ml-4">
           <ResponsiveContainer width="100%" height="100%">
             <AreaChart data={monthlyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
               <defs>
                 <linearGradient id="colorExpenseDiff" x1="0" y1="0" x2="0" y2="1">
                   <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.3}/>
                   <stop offset="95%" stopColor="#f59e0b" stopOpacity={0}/>
                 </linearGradient>
               </defs>
               <CartesianGrid strokeDasharray="3 3" stroke="#374151" vertical={false} />
               <XAxis dataKey="month" stroke="#9CA3AF" fontSize={10} axisLine={false} tickLine={false} />
               <YAxis stroke="#9CA3AF" fontSize={10} axisLine={false} tickLine={false} tickFormatter={(val) => `₺${Math.abs(val) >= 1000 ? (Math.abs(val)/1000).toFixed(0)+'k' : Math.abs(val)}`} />
               <Tooltip content={<CustomTooltip />} />
               <Area type="monotone" dataKey="expenseDiff" stroke="#f59e0b" strokeWidth={3} fillOpacity={1} fill="url(#colorExpenseDiff)" />
             </AreaChart>
           </ResponsiveContainer>
         </div>
      </SectionCard>

      {/* Aboneliklerim (Tekrarlayan Giderler) */}
      {subscriptions.length > 0 && (
        <SectionCard title="Aboneliklerim" icon={ArrowPathIcon} delay={0.8}>
           <div className="space-y-4 mt-2">
              {subscriptions.reduce((uniqueSubs, sub) => {
                 // Sadece benzersiz abonelikleri listelemek için isimlerine göre filtrele 
                 // (Çünkü geçmiş aylar dahil aynı isimde çok fatura olabilir, en güncelini baz alalım)
                 if (!uniqueSubs.find(s => s.category === sub.category && s.description === sub.description)) {
                   uniqueSubs.push(sub);
                 }
                 return uniqueSubs;
              }, [] as Transaction[]).map((sub) => (
                <div key={sub.id} className="flex items-center justify-between p-4 bg-gray-900/40 rounded-2xl border border-gray-700/30 w-full group overflow-hidden">
                   <div className="flex items-center gap-4 min-w-0 pr-4">
                     <div className="w-12 h-12 flex-shrink-0 bg-gray-800 rounded-xl flex items-center justify-center shadow-lg border border-white/5">
                        <ArrowPathIcon className="w-5 h-5 text-purple-400 group-hover:rotate-180 transition-transform duration-700" />
                     </div>
                     <div className="flex flex-col min-w-0">
                        <p className="text-white font-bold tracking-tight text-base truncate">{sub.description || sub.category}</p>
                        <p className="text-[10px] text-gray-500 font-black uppercase tracking-widest truncate">
                          {sub.recurringFrequency === 'monthly' ? 'Aylık' : sub.recurringFrequency === 'weekly' ? 'Haftalık' : sub.recurringFrequency === 'yearly' ? 'Yıllık' : 'Günlük'}
                        </p>
                     </div>
                   </div>
                   <div className="flex-shrink-0 text-right">
                      <p className="text-red-400 font-black text-lg">-{formatCurrency(sub.amount)}</p>
                   </div>
                </div>
              ))}
           </div>
        </SectionCard>
      )}

      <div className="p-8 rounded-[3rem] bg-gradient-to-br from-indigo-600 to-blue-700 text-white shadow-2xl shadow-blue-600/20 relative overflow-hidden animate-slide-up mx-2 mt-8">
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
         <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full -mr-10 -mt-10 blur-3xl opacity-50 pointer-events-none" />
      </div>
    </div>
  );
}