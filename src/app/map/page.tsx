'use client';

import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import { transactionStorage } from '@/lib/storage';
import { Transaction } from '@/types';
import { MapIcon, MapPinIcon, ChevronLeftIcon } from '@heroicons/react/24/outline';
import Link from 'next/link';

// Map bileşenini client-side render yapmak için dynamic import
const SpendingMap = dynamic(() => import('@/components/SpendingMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-[500px] bg-gray-800 animate-pulse rounded-[2.5rem] flex items-center justify-center border border-gray-700/30">
        <div className="flex flex-col items-center gap-4">
            <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin" />
            <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">Harita Yükleniyor...</p>
        </div>
    </div>
  )
});

export default function MapPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    setTransactions(transactionStorage.getAll());
  }, []);

  if (!isClient) return null;

  const locCount = transactions.filter(t => t.location).length;

  return (
    <div className="min-h-screen bg-[#0a0a0f] pb-32">
       {/* Header */}
       <div className="px-6 pt-14 pb-10">
          <div className="flex items-center justify-between mb-2">
             <Link href="/" className="p-3 bg-gray-800/50 rounded-2xl border border-gray-700/30 hover:bg-gray-700 transition-all">
                <ChevronLeftIcon className="w-6 h-6 text-gray-400" />
             </Link>
             <div className="text-right">
                <p className="text-[10px] text-blue-400 font-black uppercase tracking-[0.2em]">Konum Bazlı</p>
                <h1 className="text-2xl font-black text-white tracking-tight">Harcama Haritası</h1>
             </div>
          </div>
       </div>

       {/* Map Section */}
       <div className="px-6 space-y-6">
          <div className="relative group">
            <div className="absolute -inset-1 bg-gradient-to-r from-blue-600 to-purple-600 rounded-[2.6rem] blur opacity-25 group-hover:opacity-40 transition duration-1000"></div>
            <div className="relative h-[500px]">
               <SpendingMap transactions={transactions} />
            </div>
          </div>

          <div className="bg-gray-800/20 border border-gray-700/10 rounded-[2rem] p-6 animate-slide-up">
             <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-blue-500/10 flex items-center justify-center border border-blue-500/20">
                   <MapPinIcon className="w-6 h-6 text-blue-400" />
                </div>
                <div>
                   <p className="text-white font-black text-lg">{locCount} Konumlu İşlem</p>
                   <p className="text-xs text-gray-500 font-medium">Harcamalarınızın nerede gerçekleştiğini görün.</p>
                </div>
             </div>
          </div>

          {locCount === 0 && (
            <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-[2rem] p-6 text-center animate-fade-in">
                <p className="text-yellow-500 text-sm font-bold italic">
                  💡 Harita üzerinde veri görebilmek için yeni işlem eklerken "Konum Ekle" butonuna basın!
                </p>
            </div>
          )}
       </div>
    </div>
  );
}
