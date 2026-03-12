'use client';

import React, { useState, useEffect } from 'react';
import Statistics from '@/components/Statistics';
import type { Transaction } from '@/types';
import { transactionStorage } from '@/lib/storage';

export default function StatisticsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    setTransactions(transactionStorage.getAll());
  }, []);

  if (!isClient) {
    return (
      <div className="min-h-screen bg-[#0a0a0f] flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 via-gray-900 to-[#0a0a0f] px-6">
      <Statistics transactions={transactions} />
    </div>
  );
}
