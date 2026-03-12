'use client';

import { useState, useEffect } from 'react';
import { PlusIcon, BanknotesIcon, TrashIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { Loan, Account, Transaction } from '@/types';
import { loanStorage, accountStorage, transactionStorage } from '@/lib/storage';
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
  
  const getMonthsLeft = () => {
    if (!loan.endDate) return 0;
    const end = new Date(loan.endDate);
    if (isNaN(end.getTime())) return 0;
    const diff = end.getTime() - Date.now();
    return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24 * 30)));
  };
  const monthsLeft = getMonthsLeft();

  return (
    <div className="glass-strong rounded-2xl p-5 border border-gray-600/30 card-hover animate-slide-up">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-orange-500/20 flex items-center justify-center text-2xl">
            {typeInfo?.icon}
          </div>
          <div>
            <p className="font-semibold text-white">{loan.name}</p>
            <div className="flex items-center gap-1">
              <p className="text-[10px] uppercase font-bold text-orange-400/80 tracking-wider text-xs">{loan.bank}</p>
              <span className="text-[10px] text-gray-600">•</span>
              <p className="text-[10px] text-gray-400">{typeInfo?.label}</p>
            </div>
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

function AddLoanModal({ accounts, onClose, onAdd }: { accounts: Account[]; onClose: () => void; onAdd: (loan: Loan) => void }) {
  const [bank, setBank] = useState('');
  const [bankAccountId, setBankAccountId] = useState(accounts[0]?.id || '');
  const [type, setType] = useState<Loan['type']>('personal');
  const [principalAmount, setPrincipalAmount] = useState('');
  const [interestRate, setInterestRate] = useState('');
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState('');
  
  const [calculatedTotal, setCalculatedTotal] = useState(0);
  const [calculatedMonthly, setCalculatedMonthly] = useState(0);

  useEffect(() => {
    if (!principalAmount || !endDate || !startDate) {
      setCalculatedMonthly(0);
      setCalculatedTotal(0);
      return;
    }

    // Handle comma as decimal separator
    const cleanPrincipal = principalAmount.replace(',', '.');
    const cleanRate = interestRate.replace(',', '.');

    const pr = parseFloat(cleanPrincipal);
    const ir = parseFloat(cleanRate || '0') / 100; // Monthly rate
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    if (isNaN(pr) || isNaN(start.getTime()) || isNaN(end.getTime())) return;

    // Calculate months
    let months = (end.getFullYear() - start.getFullYear()) * 12 + (end.getMonth() - start.getMonth());
    if (months <= 0) months = 1;

    let monthly = 0;
    if (ir > 0) {
      // Annuity formula: P = (r * L) / (1 - (1 + r)^-n)
      const divider = 1 - Math.pow(1 + ir, -months);
      monthly = divider !== 0 ? (ir * pr) / divider : pr / months;
    } else {
      monthly = pr / months;
    }

    if (isNaN(monthly)) monthly = 0;

    setCalculatedMonthly(monthly);
    setCalculatedTotal(monthly * months);
  }, [principalAmount, interestRate, startDate, endDate]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!bankAccountId || !endDate) return;
    
    const selectedAccount = accounts.find(a => a.id === bankAccountId);
    
    const loan: Loan = {
      id: generateId(),
      name: bank || `${selectedAccount?.name} Kredisi`,
      bank: bank || selectedAccount?.name || 'Banka',
      type,
      accountId: bankAccountId,
      totalAmount: calculatedTotal,
      remainingAmount: calculatedTotal,
      monthlyPayment: calculatedMonthly,
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
            <label className="block text-sm text-gray-400 mb-2">Banka Adı / Şube (Etiket)</label>
            <input value={bank} onChange={(e) => setBank(e.target.value)} placeholder="örn. Akbank / Beşiktaş" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} required />
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
              <label className="block text-sm text-gray-400 mb-2">Çekilen Tutar (₺)</label>
              <input value={principalAmount} onChange={(e) => setPrincipalAmount(e.target.value)} type="number" step="100" placeholder="0.00" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} required />
            </div>
            <div>
              <label className="block text-sm text-gray-400 mb-2">Aylık Faiz Oranı (%)</label>
              <input value={interestRate} onChange={(e) => setInterestRate(e.target.value)} type="number" step="0.01" placeholder="0.00" className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white placeholder-gray-500 focus:border-orange-500 focus:outline-none" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} required />
            </div>
          </div>
          <div>
            <label className="block text-sm text-gray-400 mb-2">Ödeme Yapılacak (Bağlı) Hesap</label>
            <select 
              value={bankAccountId} 
              onChange={(e) => setBankAccountId(e.target.value)} 
              className="w-full bg-gray-800/80 border border-gray-700 rounded-xl p-3 text-white focus:border-orange-500 focus:outline-none"
              required
            >
              <option value="">Hesap seçin...</option>
              {accounts.map(acc => (
                <option key={acc.id} value={acc.id}>{acc.name} — {formatCurrency(acc.balance)}</option>
              ))}
            </select>
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

          {calculatedMonthly > 0 && (
            <div className="p-4 rounded-2xl bg-orange-500/10 border border-orange-500/20 space-y-2 animate-fade-in">
              <div className="flex justify-between items-center">
                <span className="text-xs text-gray-400 uppercase font-bold tracking-wider">Aylık Taksit</span>
                <span className="text-lg font-black text-orange-400">{formatCurrency(calculatedMonthly)}</span>
              </div>
              <div className="flex justify-between items-center pt-2 border-t border-orange-500/10">
                <span className="text-xs text-gray-400 uppercase font-bold tracking-wider">Toplam Geri Ödeme</span>
                <span className="text-sm font-bold text-white">{formatCurrency(calculatedTotal)}</span>
              </div>
            </div>
          )}

          <button type="submit" className="w-full bg-gradient-to-r from-orange-600 to-orange-500 text-white py-4 rounded-xl font-bold btn-bounce btn-glow mt-2">Kredi Ekle</button>
        </form>
      </div>
    </div>
  );
}

function PayLoanModal({ loan, onClose, onPay }: { loan: Loan; onClose: () => void; onPay: (amount: number) => void }) {
  const [amount, setAmount] = useState(loan.monthlyPayment.toString());
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center px-4 pb-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-md" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-strong rounded-3xl p-6 border border-gray-700/50 animate-bounce-in">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Taksit Öde</h2>
            <p className="text-gray-400 text-sm">{loan.name} ödemesi ({loan.bank} üzerinden)</p>
          </div>
          <button onClick={onClose} className="p-3 rounded-2xl glass hover:bg-gray-700/50 text-gray-400 btn-bounce"><XMarkIcon className="w-6 h-6" /></button>
        </div>
        
        <div className="bg-orange-500/10 border border-orange-500/20 rounded-2xl p-4 mb-8 text-center">
            <p className="text-gray-400 text-xs uppercase tracking-widest mb-1">Aylık Taksit</p>
            <p className="text-2xl font-bold text-orange-400">{formatCurrency(loan.monthlyPayment)}</p>
        </div>
        
        <div className="space-y-6">
          <div className="relative">
            <input 
               value={amount} 
               onChange={(e) => setAmount(e.target.value)} 
               type="number" 
               step="0.01" 
               className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-5 pl-12 text-white text-xl font-bold focus:border-orange-500/50 focus:bg-gray-800 focus:outline-none transition-all" 
               style={{ userSelect: 'text', WebkitUserSelect: 'text' }} 
            />
            <span className="absolute left-5 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-xl">₺</span>
          </div>
          
          <button 
             onClick={() => { 
               const cleanAmount = amount.toString().replace(',', '.');
               const finalAmount = parseFloat(cleanAmount);
               if (!isNaN(finalAmount) && finalAmount > 0) {
                 onPay(finalAmount); 
                 onClose(); 
               }
             }} 
             className="w-full bg-gradient-to-r from-orange-600 to-orange-500 text-white py-5 rounded-2xl font-bold text-xl btn-bounce shadow-xl shadow-orange-600/20 tracking-tight"
          >
            Ödemeyi Onayla
          </button>
        </div>
      </div>
    </div>
  );
}

export default function LoansPage() {
  const [loans, setLoans] = useState<Loan[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [payingLoan, setPayingLoan] = useState<Loan | null>(null);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => { 
    setIsClient(true);
    setLoans(loanStorage.getAll()); 
    setAccounts(accountStorage.getAll().filter(acc => acc.type === 'bank'));
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

  const handlePay = (loanId: string, amount: number) => {
    const loan = loans.find(l => l.id === loanId);
    if (!loan) return;

    if (loan.accountId) {
      const linkedAccount = accounts.find(a => a.id === loan.accountId);
      if (linkedAccount && linkedAccount.balance < amount) {
        alert(`Yetersiz Bakiye!\n\n${linkedAccount.name} hesabında ${formatCurrency(linkedAccount.balance)} bulunuyor. Ödeme için ${formatCurrency(amount)} gerekiyor.`);
        return;
      }
      // Banka hesabından düş
      accountStorage.adjustBalance(loan.accountId, -amount);
      setAccounts(accountStorage.getAll().filter(acc => acc.type === 'bank'));
    }

    // İşlemlere gider olarak ekle
    const newTransaction: Transaction = {
      id: generateId(),
      userId: 'local-user',
      type: 'expense',
      amount: amount,
      category: 'Kredi Ödemesi',
      description: `${loan.name} Taksit Ödemesi`,
      date: new Date(),
      isPlanned: false,
      accountId: loan.accountId,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    transactionStorage.add(newTransaction);

    const updated = loanStorage.update({
      ...loan,
      remainingAmount: Math.max(0, loan.remainingAmount - amount),
      updatedAt: new Date(),
    });
    setLoans(updated);
    setPayingLoan(null);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div className="glass px-4 pt-12 pb-6 animate-slide-up">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-2xl font-bold text-white">🏧 Krediler & Borçlar</h1>
          <button
            onClick={() => setShowAdd(true)}
            className="w-12 h-12 rounded-2xl bg-gradient-to-r from-orange-600 to-orange-500 flex items-center justify-center shadow-lg shadow-orange-500/30 btn-bounce btn-glow"
          >
            <PlusIcon className="w-6 h-6 text-white" />
          </button>
        </div>
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
            <LoanCard key={loan.id} loan={loan} onDelete={handleDelete} onPay={setPayingLoan} />
          ))
        )}
      </div>


      {showAdd && <AddLoanModal accounts={accounts} onClose={() => setShowAdd(false)} onAdd={handleAdd} />}
      {payingLoan && <PayLoanModal loan={payingLoan} onClose={() => setPayingLoan(null)} onPay={(amount) => handlePay(payingLoan.id, amount)} />}
    </div>
  );
}
