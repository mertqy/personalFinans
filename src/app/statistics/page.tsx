'use client';

import React, { useState, useEffect } from 'react';
import Statistics from '@/components/Statistics';
import type { Transaction } from '@/types';
import { transactionStorage } from '@/lib/storage';
import { AdjustmentsHorizontalIcon, ChevronLeftIcon } from '@heroicons/react/24/outline';
import Link from 'next/link';

export default function StatisticsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    const result = transactionStorage.processRecurring();
    setTransactions(result.updatedTransactions);
  }, []);

  if (!isClient) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#0B0E1A' }}>
        <div className="w-16 h-16 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen pb-32" style={{ background: 'linear-gradient(180deg, #0B0E1A 0%, #0F1527 100%)' }}>
      {/* Header */}
      <div className="px-6 pt-14 pb-4">
        <div className="flex items-center justify-between">
          <Link href="/" className="p-3 rounded-xl" style={{ background: 'var(--bg-card)' }}>
            <ChevronLeftIcon className="w-5 h-5 text-[#94A3B8]" />
          </Link>
          <h1 className="text-lg font-black text-white tracking-tight">Detaylı İstatistikler</h1>
          <button className="p-3 rounded-xl" style={{ background: 'var(--bg-card)' }}>
            <AdjustmentsHorizontalIcon className="w-5 h-5 text-[#94A3B8]" />
          </button>
        </div>
      </div>
      
      <div className="px-6">
        <Statistics transactions={transactions} />
      </div>
    </div>
  );
}
