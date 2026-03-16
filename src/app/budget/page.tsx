'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { ChevronLeftIcon, DocumentIcon, PlusIcon, TrophyIcon } from '@heroicons/react/24/outline';
import { formatCurrency } from '@/lib/utils';
import type { Transaction } from '@/types';
import { transactionStorage } from '@/lib/storage';
import Link from 'next/link';

const MONTHS = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

import { budgetStorage } from '@/lib/budgetStorage';

export default function BudgetPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [budgets, setBudgets] = useState<any[]>([]);
  const [goals, setGoals] = useState<any[]>([]);
  const [isClient, setIsClient] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

  useEffect(() => {
    setIsClient(true);
    setTransactions(transactionStorage.getAll());
    setBudgets(budgetStorage.getBudgets());
    setGoals(budgetStorage.getGoals());
  }, []);

  const budgetData = useMemo(() => {
    const monthExpenses = transactions.filter(t => {
      const d = new Date(t.date);
      return t.type === 'expense' && d.getMonth() === selectedMonth && d.getFullYear() === selectedYear;
    });

    const categorySpending: Record<string, number> = {};
    monthExpenses.forEach(t => {
      categorySpending[t.category] = (categorySpending[t.category] || 0) + t.amount;
    });

    const budgetsCalculated = budgets.map((b) => ({
      category: b.categoryId,
      limit: b.amount,
      spent: categorySpending[b.categoryId] || 0,
    })).filter(b => b.spent > 0 || b.limit > 0);

    return budgetsCalculated.sort((a, b) => (b.spent / b.limit) - (a.spent / a.limit));
  }, [transactions, budgets, selectedMonth, selectedYear]);

  if (!isClient) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#0B0E1A' }}>
        <div className="w-16 h-16 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const getStatusBadge = (spent: number, limit: number) => {
    const ratio = spent / limit;
    if (ratio >= 1) return { text: `Limit Aşımı: ${formatCurrency(spent - limit)}`, cls: 'status-badge-danger', icon: '⚠️' };
    if (ratio >= 0.85) return { text: `Limitin %${Math.round(ratio * 100)}'ine ulaşıldı`, cls: 'status-badge-warning', icon: '⚡' };
    return { text: 'Yolunda', cls: 'status-badge-success', icon: '' };
  };

  const getBarColor = (spent: number, limit: number) => {
    const ratio = spent / limit;
    if (ratio >= 1) return '#EF4444';
    if (ratio >= 0.85) return '#F97316';
    return '#3B82F6';
  };

  return (
    <div className="min-h-screen pb-32" style={{ background: 'linear-gradient(180deg, #0B0E1A 0%, #0F1527 100%)' }}>
      {/* Header */}
      <div className="px-6 pt-14 pb-6">
        <div className="flex items-center justify-between">
          <Link href="/" className="p-3 rounded-xl" style={{ background: 'var(--bg-card)' }}>
            <ChevronLeftIcon className="w-5 h-5 text-[#94A3B8]" />
          </Link>
          <h1 className="text-lg font-black text-white tracking-tight">Bütçe & Hedefler</h1>
          <div className="w-11" /> {/* Spacer for centering */}
        </div>
      </div>

      <div className="px-6 space-y-8">
        {/* Aylık Harcama */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xs text-[#64748B] uppercase font-black tracking-[0.15em]">Aylık Harcama</h2>
            <div className="flex items-center gap-2">
              <button onClick={() => { if (selectedMonth > 0) setSelectedMonth(selectedMonth - 1); else { setSelectedMonth(11); setSelectedYear(selectedYear - 1); } }}
                className="text-[#64748B] hover:text-white transition-colors text-sm font-bold">&lt;</button>
              <span className="text-white font-bold text-sm">{MONTHS[selectedMonth]} {selectedYear}</span>
              <button onClick={() => { if (selectedMonth < 11) setSelectedMonth(selectedMonth + 1); else { setSelectedMonth(0); setSelectedYear(selectedYear + 1); } }}
                className="text-[#64748B] hover:text-white transition-colors text-sm font-bold">&gt;</button>
            </div>
          </div>

          <div className="space-y-4">
            {budgetData.length === 0 ? (
              <div className="card-elevated p-8 text-center">
                <p className="text-[#64748B] font-bold text-sm">Bu ay henüz harcama yok.</p>
              </div>
            ) : (
              budgetData.map(budget => {
                const status = getStatusBadge(budget.spent, budget.limit);
                const barColor = getBarColor(budget.spent, budget.limit);
                const ratio = Math.min(budget.spent / budget.limit, 1.15);

                return (
                  <div key={budget.category} className="card-elevated p-5 animate-fade-in">
                    <div className="flex items-center justify-between mb-2">
                      <p className="text-[10px] text-[#94A3B8] uppercase font-black tracking-[0.1em]">{budget.category}</p>
                      {status.icon && <span className="text-sm">{status.icon}</span>}
                    </div>
                    <div className="flex items-baseline gap-2 mb-3">
                      <p className="text-2xl font-black text-white tracking-tight">{formatCurrency(budget.spent)}</p>
                      <p className="text-sm text-[#64748B] font-bold">/ {formatCurrency(budget.limit)}</p>
                      <span className={`status-badge ${status.cls} ml-auto`}>{status.text}</span>
                    </div>
                    <div className="progress-bar">
                      <div className="progress-bar-fill" style={{ width: `${Math.min(ratio * 100, 100)}%`, backgroundColor: barColor }} />
                    </div>
                    {budget.spent > budget.limit && (
                      <p className="text-xs text-red-400 font-bold mt-2">Limit Aşımı: {formatCurrency(budget.spent - budget.limit)}</p>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Tasarruf Hedefleri */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xs text-[#64748B] uppercase font-black tracking-[0.15em]">Tasarruf Hedefleri</h2>
            <button className="status-badge status-badge-info flex items-center gap-1">
              <PlusIcon className="w-3 h-3" />
              Yeni Hedef
            </button>
          </div>

          <div className="space-y-4">
            {goals.map(goal => {
              const progress = goal.currentAmount / goal.targetAmount;

              return (
                <div key={goal.id} className="card-elevated p-5">
                  <div className="flex items-center gap-4 mb-3">
                    <div className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl" style={{ background: 'var(--bg-surface)' }}>
                      {goal.icon}
                    </div>
                    <div>
                      <p className="text-white font-bold text-base">{goal.title}</p>
                      <p className="text-[10px] text-[#64748B] uppercase font-bold tracking-widest">Hedef: {new Date(goal.targetDate).toLocaleDateString('tr-TR', { month: 'short', year: 'numeric' })}</p>
                    </div>
                  </div>
                  <div className="flex items-baseline gap-2 mb-3">
                    <p className="text-xl font-black text-white tracking-tight">{formatCurrency(goal.currentAmount)}</p>
                    <p className="text-xs text-[#64748B]">biriktirildi</p>
                    <p className="text-sm text-[#64748B] font-bold ml-auto">{formatCurrency(goal.targetAmount)}</p>
                  </div>
                  <div className="progress-bar mb-3">
                    <div className="progress-bar-fill" style={{ width: `${Math.min(progress * 100, 100)}%`, backgroundColor: goal.levelColor }} />
                  </div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1">
                      <TrophyIcon className="w-3.5 h-3.5" style={{ color: goal.levelColor }} />
                      <span className="text-[10px] font-black uppercase tracking-widest" style={{ color: goal.levelColor }}>{goal.level}</span>
                    </div>
                    <span className="text-[10px] text-[#64748B] font-bold">%{Math.round(progress * 100)} Tamamlandı</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
