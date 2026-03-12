'use client';

import { useState, useEffect } from 'react';
import {
  PlusIcon,
  BanknotesIcon,
  ArrowsRightLeftIcon,
  TrashIcon,
  XMarkIcon,
  BuildingLibraryIcon,
  CurrencyDollarIcon,
  ArrowTrendingUpIcon,
} from '@heroicons/react/24/outline';
import { Account, Transfer } from '@/types';
import { accountStorage, transferStorage } from '@/lib/storage';
import { formatCurrency, generateId } from '@/lib/utils';

const ACCOUNT_TYPES = [
  { value: 'cash', label: 'Nakit', icon: <CurrencyDollarIcon className="w-6 h-6" />, emoji: '💵' },
  { value: 'bank', label: 'Banka', icon: <BuildingLibraryIcon className="w-6 h-6" />, emoji: '🏦' },
  { value: 'savings', label: 'Birikim', icon: <BanknotesIcon className="w-6 h-6" />, emoji: '🐷' },
  { value: 'investment', label: 'Yatırım', icon: <ArrowTrendingUpIcon className="w-6 h-6" />, emoji: '📈' },
];

const ACCOUNT_COLORS = [
  '#3B82F6', '#10B981', '#8B5CF6', '#F59E0B',
  '#EF4444', '#06B6D4', '#EC4899', '#6B7280',
];

function AccountCard({
  account,
  onDelete,
}: {
  account: Account;
  onDelete: (id: string) => void;
}) {
  const typeInfo = ACCOUNT_TYPES.find((t) => t.value === account.type);
  const isPositive = account.balance >= 0;
  return (
    <div
      className="p-6 rounded-[2rem] glass-strong border border-gray-700/30 card-hover animate-slide-up relative bg-gradient-to-br from-gray-800/40 to-transparent"
    >
      <div className="flex items-start justify-between mb-6">
        <div className="flex items-center gap-4">
          <div
            className="w-14 h-14 rounded-2xl flex items-center justify-center text-2xl shadow-lg border border-white/10"
            style={{ background: account.color, color: 'white' }}
          >
            {typeInfo?.icon || '💰'}
          </div>
          <div>
            <p className="font-black text-white text-lg tracking-tight">{account.name}</p>
            <p className="text-[10px] text-gray-500 uppercase font-bold tracking-widest">{typeInfo?.label}</p>
          </div>
        </div>
        <button
          onClick={() => onDelete(account.id)}
          className="p-3 rounded-2xl glass border border-red-500/10 text-red-500/60 hover:text-red-400 transition-all btn-bounce"
        >
          <TrashIcon className="w-5 h-5" />
        </button>
      </div>
      
      <div className="flex items-end justify-between">
        <div>
          <p className="text-[10px] text-gray-500 uppercase font-black tracking-widest mb-1">Mevcut Bakiye</p>
          <p className={`text-3xl font-black tracking-tighter ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
            {formatCurrency(account.balance)}
          </p>
        </div>
        <div className="pb-1 opacity-20">
           {account.icon}
        </div>
      </div>
    </div>
  );
}

function AddAccountModal({
  onClose,
  onAdd,
}: {
  onClose: () => void;
  onAdd: (account: Account) => void;
}) {
  const [name, setName] = useState('');
  const [type, setType] = useState<Account['type']>('bank');
  const [balance, setBalance] = useState('');
  const [color, setColor] = useState(ACCOUNT_COLORS[0]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !balance) return;
    const account: Account = {
      id: generateId(),
      name,
      type,
      balance: parseFloat(balance),
      currency: 'TRY',
      color,
      icon: ACCOUNT_TYPES.find((t) => t.value === type)?.emoji || '💰',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    onAdd(account);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center px-4 pb-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-md" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-strong rounded-3xl p-8 border border-gray-700/50 animate-bounce-in max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-10">
          <div>
            <h2 className="text-3xl font-black text-white tracking-tighter">Yeni Hesap</h2>
            <p className="text-gray-400 text-sm">Finansal varlıklarını yönet</p>
          </div>
          <button onClick={onClose} className="p-4 rounded-2xl glass hover:bg-gray-700/50 text-gray-400 btn-bounce">
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="space-y-8">
          <div className="space-y-6">
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 px-1">Hesap Adı</label>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Örn: Garanti Maaş"
                className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-5 text-white text-lg font-bold placeholder-gray-600 focus:border-blue-500 focus:bg-gray-800 focus:outline-none transition-all"
                style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
                required
              />
            </div>
            
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 px-1">Hesap Türü</label>
              <div className="grid grid-cols-2 gap-3">
                {ACCOUNT_TYPES.map((t) => (
                  <button
                    key={t.value}
                    type="button"
                    onClick={() => setType(t.value as Account['type'])}
                    className={`p-4 rounded-2xl flex items-center gap-3 transition-all duration-300 btn-bounce
                      ${type === t.value ? 'bg-blue-600 border-none text-white shadow-xl shadow-blue-600/20' : 'glass border border-gray-700/50 text-gray-500'}`}
                  >
                    <span className="text-xl">{t.emoji}</span>
                    <span className="font-bold text-sm tracking-tight">{t.label}</span>
                  </button>
                ))}
              </div>
            </div>
            
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 px-1">Bakiye</label>
              <div className="relative">
                <input
                  value={balance}
                  onChange={(e) => setBalance(e.target.value)}
                  type="number"
                  step="0.01"
                  placeholder="0.00"
                  className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-5 pl-12 text-white text-2xl font-black focus:border-green-500 focus:bg-gray-800 focus:outline-none transition-all"
                  style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
                  required
                />
                <span className="absolute left-5 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-2xl">₺</span>
              </div>
            </div>
            
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 px-1">Renk</label>
              <div className="flex gap-4 flex-wrap justify-between px-1">
                {ACCOUNT_COLORS.map((c) => (
                  <button
                    key={c}
                    type="button"
                    onClick={() => setColor(c)}
                    className={`w-10 h-10 rounded-2xl transition-all duration-300 btn-bounce ${color === c ? 'scale-110 ring-4 ring-white/10 border-2 border-white' : 'opacity-60 grayscale-[0.2]'}`}
                    style={{ backgroundColor: c }}
                  />
                ))}
              </div>
            </div>
          </div>
          
          <button
            type="submit"
            className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-6 rounded-2xl font-black text-xl btn-bounce shadow-2xl shadow-blue-600/30 tracking-tight"
          >
            Hesabı Oluştur
          </button>
        </form>
      </div>
    </div>
  );
}

function TransferModal({
  accounts,
  onClose,
  onTransfer,
}: {
  accounts: Account[];
  onClose: () => void;
  onTransfer: (transfer: Transfer) => void;
}) {
  const [fromId, setFromId] = useState(accounts[0]?.id || '');
  const [toId, setToId] = useState(accounts[1]?.id || '');
  const [amount, setAmount] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fromId || !toId || fromId === toId || !amount) return;
    const transfer: Transfer = {
      id: generateId(),
      fromAccountId: fromId,
      toAccountId: toId,
      amount: parseFloat(amount),
      date: new Date(),
      description: '',
      createdAt: new Date(),
    };
    onTransfer(transfer);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center px-4 pb-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-md" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-strong rounded-3xl p-8 border border-gray-700/50 animate-bounce-in">
        <div className="flex items-center justify-between mb-10">
          <div>
            <h2 className="text-3xl font-black text-white tracking-tighter">Transfer</h2>
            <p className="text-gray-400 text-sm">Hesapların arası para aktarımı</p>
          </div>
          <button onClick={onClose} className="p-4 rounded-2xl glass hover:bg-gray-700/50 text-gray-400 btn-bounce">
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-3 relative">
            <div className="absolute left-1/2 top-11 -translate-x-1/2 z-10 w-10 h-10 bg-white text-gray-900 rounded-full flex items-center justify-center shadow-xl border-4 border-gray-900 animate-pulse-custom">
                <ArrowsRightLeftIcon className="w-5 h-5" />
            </div>
            
            <div>
              <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2 pl-2">Gönderen</label>
              <select
                value={fromId}
                onChange={(e) => setFromId(e.target.value)}
                className="w-full bg-gray-800/80 border border-gray-700 rounded-2xl p-4 text-white text-sm font-bold appearance-none focus:border-purple-500 transition-all h-16"
              >
                {accounts.map((a) => (
                  <option key={a.id} value={a.id}>{a.name}</option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2 pl-2">Alıcı</label>
              <select
                value={toId}
                onChange={(e) => setToId(e.target.value)}
                className="w-full bg-gray-800/80 border border-gray-700 rounded-2xl p-4 text-white text-sm font-bold appearance-none focus:border-purple-500 transition-all h-16"
              >
                {accounts.filter((a) => a.id !== fromId).map((a) => (
                  <option key={a.id} value={a.id}>{a.name}</option>
                ))}
              </select>
            </div>
          </div>
          
          <div>
            <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 px-1">Aktarılacak Tutar</label>
            <div className="relative">
              <input
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                type="number"
                step="0.01"
                placeholder="0.00"
                className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-5 pl-12 text-white text-2xl font-black focus:border-purple-500 focus:bg-gray-800 focus:outline-none transition-all"
                style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
                required
              />
              <span className="absolute left-5 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-2xl">₺</span>
            </div>
          </div>
          
          <button
            type="submit"
            className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 text-white py-6 rounded-2xl font-black text-xl btn-bounce shadow-2xl shadow-purple-600/30 tracking-tight"
          >
            Transferi Onayla
          </button>
        </form>
      </div>
    </div>
  );
}

export default function AccountsPage() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [showTransfer, setShowTransfer] = useState(false);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
    setAccounts(accountStorage.getAll());
  }, []);

  if (!isClient) return null;

  const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);

  const handleAdd = (account: Account) => {
    const updated = accountStorage.add(account);
    setAccounts(updated);
  };

  const handleDelete = (id: string) => {
    const updated = accountStorage.delete(id);
    setAccounts(updated);
  };

  const handleTransfer = (transfer: Transfer) => {
    accountStorage.adjustBalance(transfer.fromAccountId, -transfer.amount);
    accountStorage.adjustBalance(transfer.toAccountId, transfer.amount);
    transferStorage.add(transfer);
    setAccounts(accountStorage.getAll());
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 via-gray-900 to-[#0a0a0f] pb-32">
      {/* Mobile Top Bar */}
      <div className="px-6 pt-14 pb-10 animate-fade-in relative overflow-hidden">
        <div className="relative z-10">
            <h1 className="text-3xl font-black text-white mb-8 tracking-tighter">Hesaplar</h1>
            <p className="text-[10px] text-gray-500 uppercase font-black tracking-[0.2em] mb-1 pl-1">Toplam Varlık</p>
            <p className={`text-5xl font-black tracking-tighter animate-count-up ${totalBalance >= 0 ? 'text-green-400' : 'text-red-400'}`}>
              {formatCurrency(totalBalance)}
            </p>
        </div>
        
        {/* Abstract background element */}
        <div className="absolute -top-20 -right-20 w-64 h-64 bg-blue-500/10 rounded-full blur-[100px]" />
      </div>

      <div className="px-6 space-y-6">
        {accounts.length === 0 ? (
          <div className="text-center py-20 animate-fade-in">
            <div className="w-24 h-24 glass rounded-[2.5rem] flex items-center justify-center mx-auto mb-6 float border border-gray-700/30">
              <BanknotesIcon className="w-12 h-12 text-gray-500" />
            </div>
            <p className="text-gray-400 text-lg font-bold mb-1">Hesap yok</p>
            <p className="text-gray-500 text-sm px-10">Tüm banka ve nakit hesaplarını ekleyerek takip et.</p>
          </div>
        ) : (
          accounts.map((account) => (
            <AccountCard key={account.id} account={account} onDelete={handleDelete} />
          ))
        )}
      </div>

      {/* FABs mobile optimized */}
      <div className="fixed bottom-28 right-6 flex flex-col gap-4 z-50">
        {accounts.length >= 2 && (
          <button
            onClick={() => setShowTransfer(true)}
            className="w-14 h-14 rounded-2xl bg-white text-gray-900 flex items-center justify-center shadow-xl btn-bounce active:scale-90 border-t border-white"
          >
            <ArrowsRightLeftIcon className="w-6 h-6" />
          </button>
        )}
        <button
          onClick={() => setShowAdd(true)}
          className="w-16 h-16 rounded-[2rem] bg-gradient-to-b from-blue-500 to-indigo-600 flex items-center justify-center shadow-2xl shadow-blue-600/40 btn-bounce active:scale-90 border-t border-white/20"
        >
          <PlusIcon className="w-8 h-8 text-white" />
        </button>
      </div>

      {showAdd && <AddAccountModal onClose={() => setShowAdd(false)} onAdd={handleAdd} />}
      {showTransfer && (
        <TransferModal
          accounts={accounts}
          onClose={() => setShowTransfer(false)}
          onTransfer={handleTransfer}
        />
      )}
    </div>
  );
}
