'use client';

import React, { useState, useEffect } from 'react';
import { CogIcon, BellIcon, PlusIcon, CreditCardIcon } from '@heroicons/react/24/outline';
import { formatCurrency, formatDate } from '@/lib/utils';
import type { Transaction, CreditCard } from '@/types';
import { transactionStorage, creditCardStorage } from '@/lib/storage';

export default function PaymentsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [cards, setCards] = useState<CreditCard[]>([]);
  const [isClient, setIsClient] = useState(false);
  const [notificationsOn, setNotificationsOn] = useState(true);

  useEffect(() => {
    setIsClient(true);
    setTransactions(transactionStorage.getAll());
    setCards(creditCardStorage.getAll());
  }, []);

  if (!isClient) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: '#0B0E1A' }}>
        <div className="w-16 h-16 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  const subscriptions = transactions.filter(t => t.type === 'expense' && t.isRecurring);
  const uniqueSubs = subscriptions.reduce((acc, sub) => {
    if (!acc.find(s => s.category === sub.category && s.description === sub.description)) {
      acc.push(sub);
    }
    return acc;
  }, [] as Transaction[]);

  const CARD_GRADIENTS = [
    'linear-gradient(135deg, #3B82F6, #6366F1)',
    'linear-gradient(135deg, #F59E0B, #D97706)',
    'linear-gradient(135deg, #22C55E, #16A34A)',
    'linear-gradient(135deg, #EF4444, #DC2626)',
    'linear-gradient(135deg, #7C3AED, #6C5CE7)',
  ];

  return (
    <div className="min-h-screen pb-32" style={{ background: 'linear-gradient(180deg, #0B0E1A 0%, #0F1527 100%)' }}>
      {/* Header */}
      <div className="px-6 pt-14 pb-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-black text-white tracking-tight">Ödemeler</h1>
          <button className="p-3 rounded-xl" style={{ background: 'var(--bg-card)' }}>
            <CogIcon className="w-5 h-5 text-[#94A3B8]" />
          </button>
        </div>
      </div>

      <div className="px-6 space-y-8">
        {/* Abonelikler */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-black text-white tracking-tight">Abonelikler</h2>
            <span className="text-xs font-bold text-indigo-400">Tümünü Gör</span>
          </div>

          {uniqueSubs.length === 0 ? (
            <div className="card-elevated p-8 text-center">
              <p className="text-[#64748B] font-bold text-sm">Henüz tekrarlayan bir ödemeniz yok.</p>
              <p className="text-[10px] text-[#475569] mt-1">İşlem eklerken "Tekrarlayan" seçeneğini işaretleyin.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {uniqueSubs.map(sub => (
                <div key={sub.id} className="card-elevated flex items-center justify-between p-4">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-xl bg-indigo-500/10 flex items-center justify-center text-lg">
                      🔄
                    </div>
                    <div>
                      <p className="text-white font-bold text-sm">{sub.description || sub.category}</p>
                      <p className="text-[10px] text-[#64748B]">
                        {sub.recurringFrequency === 'monthly' ? 'Aylık' : sub.recurringFrequency === 'weekly' ? 'Haftalık' : sub.recurringFrequency === 'yearly' ? 'Yıllık' : 'Günlük'} Plan
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-white font-black text-base">{formatCurrency(sub.amount)}</p>
                    <span className="status-badge status-badge-info text-[8px]">
                      {sub.recurringFrequency === 'monthly' ? 'Her Ay' : sub.recurringFrequency === 'yearly' ? 'Her Yıl' : 'Aktif'}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Kart Hatırlatıcıları */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-black text-white tracking-tight">Kart Hatırlatıcıları</h2>
            <div className="flex items-center gap-2">
              <span className="text-[10px] text-[#94A3B8] uppercase font-black tracking-widest">Bildirimler</span>
              <button
                onClick={() => setNotificationsOn(!notificationsOn)}
                className={`w-10 h-6 rounded-full transition-all relative ${notificationsOn ? 'bg-indigo-500' : 'bg-[var(--bg-surface)]'}`}
              >
                <span className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow transition-all ${notificationsOn ? 'left-5' : 'left-1'}`} />
              </button>
            </div>
          </div>

          {cards.length === 0 ? (
            <div className="card-elevated p-8 text-center">
              <CreditCardIcon className="w-10 h-10 text-[#64748B] mx-auto mb-3" />
              <p className="text-[#64748B] font-bold text-sm">Henüz kredi kartınız yok.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {cards.map((card, i) => (
                <div
                  key={card.id}
                  className="rounded-2xl p-5 text-white shadow-xl relative overflow-hidden"
                  style={{ background: CARD_GRADIENTS[i % CARD_GRADIENTS.length] }}
                >
                  <div className="relative z-10">
                    <p className="text-[10px] uppercase font-black tracking-[0.15em] opacity-80">{card.bank || card.name}</p>
                    <p className="text-2xl font-black tracking-widest mt-2">•••• {card.name.slice(-4) || '0000'}</p>
                    <div className="flex justify-between mt-4 text-xs font-bold opacity-90">
                      <div>
                        <p className="text-[8px] uppercase tracking-widest opacity-60">Hesap Kesim</p>
                        <p>{card.statementDay}. gün</p>
                      </div>
                      <div>
                        <p className="text-[8px] uppercase tracking-widest opacity-60">Son Ödeme</p>
                        <p>{card.dueDay}. gün</p>
                      </div>
                    </div>
                  </div>
                  <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full -mr-8 -mt-8 blur-xl" />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Yeni Ödeme Ekle */}
        <button className="w-full py-4 rounded-2xl font-bold text-sm flex items-center justify-center gap-2 btn-bounce"
          style={{ background: 'var(--bg-card-elevated)', border: '1px solid rgba(99, 102, 241, 0.2)', color: '#94A3B8' }}>
          <PlusIcon className="w-5 h-5" />
          Yeni Ödeme Ekle
        </button>
      </div>
    </div>
  );
}
