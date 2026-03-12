'use client';

import { useState, useEffect } from 'react';
import { PlusIcon, BanknotesIcon, TrashIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { Loan } from '@/types';
import { loanStorage } from '@/lib/storage';
import { formatCurrency, formatDate, generateId } from '@/lib/utils';

const LOAN_TYPES = [
  { value: 'personal', label: 'İhtiyaç', icon: '💼' },
  { value: 'mortgage', label: 'Konut', icon: '🏠' },
  { value: 'auto', label: 'Taşıt', icon: '🚗' },
  { value: 'other', label: 'Diğer', icon: '📋' },
];

function LoanCard({ loan, onDelete, onPay }: { loan: Loan; onDelete: (id: string) => void; onPay: (loan: Loan) => void }) {
  const typeInfo = LOAN_TYPES.find((t) => t.value === loan.type);
  const paidPercent = loan.totalAmount > 0 ? ((loan.totalAmount - loan.remainingAmount) / loan.totalAmount) * 100 : 0;
  const monthsLeft = Math.ceil((new Date(loan.endDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24 * 30));

  return (
    <div className="glass-strong rounded-2xl p-5 border border-gray-600/30 card-hover animate-slide-up">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-orange-500/20 flex items-center justify-center text-2xl">
            {typeInfo?.icon}
          </div>
          <div>
            <p className="font-semibold text-white">{loan.name}</p>
            <p className="text-xs text-gray-400">{typeInfo?.label} Kredisi</p>
          </div>
        </div>
        <button onClick={() => onDelete(loan.id)} className="p-2 rounded-lg hover:bg-red-500/20 text-gray-500 hover:text-red-400 transition-all duration-200 btn-bounce">
          <TrashIcon className="w-4 h-4" />
        </button>
      </div>

      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="glass rounded-xl p-3 text-center">
          <p className="text-xs text-gray-400">Taksit</p>
          <p className="text-sm font-bold text-orange-400">{formatCurrency(loan.monthlyPayment)}</p>
        </div>
        <div className="glass rounded-xl p-3 text-center">
          <p className="text-xs text-gray-400">Kalan</p>
          <p className="text-sm font-bold text-red-400">{formatCurrency(loan.remainingAmount)}</p>
        </div>
        <div className="glass rounded-xl p-3 text-center">
          <p className="text-xs text-gray-400">Ay Kaldı</p>
          <p className="text-sm font-bold text-blue-400">{monthsLeft > 0 ? monthsLeft : 0}</p>
        </div>
      </div>

      {/* Progress */}
      <div className="mb-3">
        <div className="flex justify-between text-xs text-gray-400 mb-2">
          <span>Ödenen: {formatCurrency(loan.totalAmount - loan.remainingAmount)}</span>
          <span>{paidPercent.toFixed(0)}%</span>
        </div>
        <div className="bg-gray-700 rounded-full h-3 overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-1000 bg-gradient-to-r from-green-500 to-green-400"
            style={{ width: `${paidPercent}%` }}
          />
        </div>
        <p className="text-xs text-gray-500 mt-1">Toplam: {formatCurrency(loan.totalAmount)} · Faiz: %{loan.interestRate} · Bitiş: {formatDate(loan.endDate)}</p>
      </div>

      <button
        onClick={() => onPay(loan)}
        className="w-full bg-gradient-to-r from-orange-600/80 to-orange-500/80 text-white py-2.5 rounded-xl text-sm font-semibold btn-bounce mt-1"
      >
        💰 Taksit Öde
      </button>
    </div>
  );
}

function AddLoanModal({ onClose, onAdd }: { onClose: () => void; onAdd: (loan: Loan) => void }) {
  const [name, setName] = useState('');
  const [type, setType] = useState<Loan['type']>('personal');
  const [totalAmount, setTotalAmount] = useState('');
  const [monthlyPayment, setMonthlyPayment] = useState('');
  const [interestRate, setInterestRate] = useState('');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const loan: Loan = {
      id: generateId(),
      name,
      type,
      totalAmount: parseFloat(totalAmount),
      remainingAmount: parseFloat(totalAmount),
      monthlyPayment: parseFloat(monthlyPayment),
      interestRate: parseFloat(interestRate || '0'),
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    onAdd(loan);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-strong rounded-t-3xl p-6 border-t border-gray-700/50 animate-slide-up max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">🏧 Kredi Ekle</h2>
          <button onClick={onClose} className="p-2 rounded-xl glass text-gray-400 btn-bounce"><XMarkIcon className="w-5 h-5" /></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm text-gray-400 mb-2">Kredi Adı</label>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="örn. İhtiyaç Kredisi" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} required />
          </div>
          <div>
            <label className="block text-sm text-gray-400 mb-2">Kredi Türü</label>
            <div className="grid grid-cols-4 gap-2">
              {LOAN_TYPES.map((t) => (
                <button key={t.value} type="button" onClick={() => setType(t.value as Loan['type'])} className={`p-3 rounded-xl flex flex-col items-center gap-1 text-xs transition-all duration-200 btn-bounce ${type === t.value ? 'bg-orange-500/30 border border-orange-500/60 text-orange-400' : 'glass border border-gray-700 text-gray-400'}`}>
                  <span className="text-xl">{t.icon}</span>
                  <span>{t.label}</span>
                </button>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm text-gray-400 mb-2">Toplam Tutar (₺)</label>
              <input value={totalAmount} onChange={(e) => setTotalAmount(e.target.value)} type="number" step="100" placeholder="0.00" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} required />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-2">Aylık Taksit (₺)</label>
              <input value={monthlyPayment} onChange={(e) => setMonthlyPayment(e.target.value)} type="number" step="0.01" placeholder="0.00" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} required />
            </div>
          </div>
          <div>
            <label className="block text-sm text-gray-400 mb-2">Faiz Oranı (%)</label>
            <input value={interestRate} onChange={(e) => setInterestRate(e.target.value)} type="number" step="0.01" placeholder="0.00" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm text-gray-400 mb-2">Başlangıç</label>
              <input value={startDate} onChange={(e) => setStartDate(e.target.value)} type="date" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white focus:border-orange-500 focus:outline-none" style={{ colorScheme: 'dark' }} />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-2">Bitiş</label>
              <input value={endDate} onChange={(e) => setEndDate(e.target.value)} type="date" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white focus:border-orange-500 focus:outline-none" style={{ colorScheme: 'dark' }} required />
            </div>
          </div>
          <button type="submit" className="w-full bg-gradient-to-r from-orange-600 to-orange-500 text-white py-4 rounded-xl font-bold btn-bounce btn-glow mt-2">Kredi Ekle</button>
        </form>
      </div>
    </div>
  );
}

export default function LoansPage() {
  const [loans, setLoans] = useState<Loan[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => { 
    setIsClient(true);
    setLoans(loanStorage.getAll()); 
  }, []);

  if (!isClient) return null;

  const totalRemaining = loans.reduce((s, l) => s + l.remainingAmount, 0);
  const totalMonthly = loans.reduce((s, l) => s + l.monthlyPayment, 0);

  const handleAdd = (loan: Loan) => {
    const updated = loanStorage.add(loan);
    setLoans(updated);
  };

  const handleDelete = (id: string) => {
    const updated = loanStorage.delete(id);
    setLoans(updated);
  };

  const handlePay = (loan: Loan) => {
    const updated = loanStorage.update({
      ...loan,
      remainingAmount: Math.max(0, loan.remainingAmount - loan.monthlyPayment),
      updatedAt: new Date(),
    });
    setLoans(updated);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div className="glass px-4 pt-12 pb-6 animate-slide-up">
        <h1 className="text-2xl font-bold text-white mb-4">🏧 Krediler & Borçlar</h1>
        <div className="grid grid-cols-2 gap-3">
          <div className="glass rounded-xl p-3 border border-red-500/30">
            <p className="text-xs text-gray-400">Toplam Kalan Borç</p>
            <p className="text-xl font-bold text-red-400 mt-1">{formatCurrency(totalRemaining)}</p>
          </div>
          <div className="glass rounded-xl p-3 border border-orange-500/30">
            <p className="text-xs text-gray-400">Aylık Taksit Yükü</p>
            <p className="text-xl font-bold text-orange-400 mt-1">{formatCurrency(totalMonthly)}</p>
          </div>
        </div>
      </div>

      <div className="px-4 pt-6 space-y-4">
        {loans.length === 0 ? (
          <div className="text-center py-16 animate-bounce-in">
            <div className="w-20 h-20 glass rounded-full flex items-center justify-center mx-auto mb-4 float">
              <BanknotesIcon className="w-10 h-10 text-gray-400" />
            </div>
            <p className="text-gray-400 text-lg mb-2">Kredi bulunmuyor</p>
            <p className="text-gray-500 text-sm">Takip etmek istediğiniz krediyi ekleyin</p>
          </div>
        ) : (
          loans.map((loan) => (
            <LoanCard key={loan.id} loan={loan} onDelete={handleDelete} onPay={handlePay} />
          ))
        )}
      </div>

      <button
        onClick={() => setShowAdd(true)}
        className="fixed bottom-24 right-4 w-14 h-14 rounded-full bg-gradient-to-r from-orange-600 to-orange-500 flex items-center justify-center shadow-lg shadow-orange-500/30 btn-bounce btn-glow"
      >
        <PlusIcon className="w-7 h-7 text-white" />
      </button>

      {showAdd && <AddLoanModal onClose={() => setShowAdd(false)} onAdd={handleAdd} />}
    </div>
  );
}
