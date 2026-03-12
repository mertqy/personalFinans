'use client';

import { useState, useEffect } from 'react';
import { PlusIcon, CreditCardIcon, TrashIcon, XMarkIcon, BuildingLibraryIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline';
import { CreditCard, Account, Transaction } from '@/types';
import { creditCardStorage, accountStorage, transactionStorage } from '@/lib/storage';
import { formatCurrency, generateId } from '@/lib/utils';
import Link from 'next/link';

const CARD_COLORS = [
  { from: '#1a1a2e', to: '#16213e', accent: '#3B82F6' },
  { from: '#0f3460', to: '#16213e', accent: '#06B6D4' },
  { from: '#1a1a2e', to: '#3d0c11', accent: '#EF4444' },
  { from: '#1c1c1c', to: '#2d1b4e', accent: '#8B5CF6' },
  { from: '#0a2e0a', to: '#1a1a2e', accent: '#10B981' },
  { from: '#2e1a00', to: '#1a1a2e', accent: '#F59E0B' },
];

function CreditCardVisual({ card, accountName }: { card: CreditCard, accountName?: string }) {
  const colorScheme = CARD_COLORS.find((c) => c.accent === card.color) || CARD_COLORS[0];
  const usedPercent = card.limit > 0 ? (card.currentDebt / card.limit) * 100 : 0;
  const availableLimit = card.limit - card.currentDebt;
  
  return (
    <div className="space-y-3">
      {/* Physical card look */}
      <div
        className="relative rounded-2xl p-6 overflow-hidden card-hover animate-slide-up"
        style={{
          background: `linear-gradient(135deg, ${colorScheme.from}, ${colorScheme.to})`,
          border: `1px solid ${colorScheme.accent}30`,
          boxShadow: `0 12px 40px ${colorScheme.accent}30`,
        }}
      >
        <div
          className="absolute -top-10 -right-10 w-48 h-48 rounded-full opacity-10"
          style={{ background: colorScheme.accent }}
        />
        <div
          className="absolute -bottom-10 -left-10 w-36 h-36 rounded-full opacity-10"
          style={{ background: colorScheme.accent }}
        />
        <div className="relative z-10">
          <div className="flex justify-between items-start mb-8">
            <div>
              <div className="flex items-center gap-1.5 opacity-80 mb-1">
                <BuildingLibraryIcon className="w-3.5 h-3.5 text-white" />
                <p className="text-[10px] uppercase tracking-wider text-white font-medium">{accountName || card.bank}</p>
              </div>
              <p className="text-white font-bold text-xl tracking-tight">{card.name}</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/20">
              <CreditCardIcon className="w-7 h-7" style={{ color: colorScheme.accent }} />
            </div>
          </div>
          
          <div className="flex justify-between items-end mt-8">
            <div>
              <p className="text-[10px] uppercase tracking-widest text-white/60 mb-1 font-medium">Bakiye / Borç</p>
              <p className="text-2xl font-bold text-white tracking-tight">{formatCurrency(card.currentDebt)}</p>
            </div>
            <div className="text-right">
              <p className="text-[10px] uppercase tracking-widest text-white/60 mb-1 font-medium">Limit</p>
              <p className="text-sm font-bold text-white/90">
                {formatCurrency(card.limit)}
              </p>
            </div>
          </div>
          
          {/* Usage bar */}
          <div className="mt-5 bg-white/10 rounded-full h-2 overflow-hidden backdrop-blur-sm">
            <div
              className="h-full rounded-full transition-all duration-1000 ease-out"
              style={{
                width: `${Math.min(usedPercent, 100)}%`,
                background: usedPercent > 90 ? '#ff4d4d' : usedPercent > 70 ? '#ffa502' : colorScheme.accent,
                boxShadow: `0 0 10px ${usedPercent > 70 ? '#ffa502' : colorScheme.accent}80`
              }}
            />
          </div>
        </div>
        
        {/* NFC Icon placeholder */}
        <div className="absolute right-6 top-1/2 -translate-y-1/2 opacity-20">
           <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
             <path d="M4 12C4 7.58172 7.58172 4 12 4" stroke="white" strokeWidth="2" strokeLinecap="round"/>
             <path d="M7 12C7 9.23858 9.23858 7 12 7" stroke="white" strokeWidth="2" strokeLinecap="round"/>
             <path d="M10 12C10 10.8954 10.8954 10 12 10" stroke="white" strokeWidth="2" strokeLinecap="round"/>
           </svg>
        </div>
      </div>

      {/* Stats row mobile optimized */}
      <div className="flex gap-2 w-full overflow-x-auto no-scrollbar pb-1">
        <div className="flex-1 min-w-[100px] glass rounded-2xl p-3 border border-gray-700/30">
          <p className="text-[10px] text-gray-400 uppercase tracking-tighter mb-1">Doluluk</p>
          <p className={`text-sm font-bold ${usedPercent > 90 ? 'text-red-400' : 'text-blue-400'}`}>%{usedPercent.toFixed(0)}</p>
        </div>
        <div className="flex-1 min-w-[100px] glass rounded-2xl p-3 border border-gray-700/30">
          <p className="text-[10px] text-gray-400 uppercase tracking-tighter mb-1">Kalan Limit</p>
          <p className="text-sm font-bold text-green-400">{formatCurrency(availableLimit)}</p>
        </div>
        <div className="flex-1 min-w-[100px] glass rounded-2xl p-3 border border-gray-700/30">
          <p className="text-[10px] text-gray-400 uppercase tracking-tighter mb-1">Dönem Sonu</p>
          <p className="text-sm font-bold text-yellow-500">{card.dueDay}. Gün</p>
        </div>
      </div>
    </div>
  );
}

function AddCardModal({ accounts, onClose, onAdd }: { accounts: Account[], onClose: () => void; onAdd: (card: CreditCard) => void }) {
  const [name, setName] = useState('');
  const [bankAccountId, setBankAccountId] = useState(accounts[0]?.id || '');
  const [limit, setLimit] = useState('');
  const [statementDay, setStatementDay] = useState('1');
  const [dueDay, setDueDay] = useState('10');
  const [color, setColor] = useState(CARD_COLORS[0].accent);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !bankAccountId || !limit) return;
    
    const selectedAccount = accounts.find(a => a.id === bankAccountId);
    
    const card: CreditCard = {
      id: generateId(),
      name,
      bank: selectedAccount?.name || 'Banka',
      accountId: bankAccountId,
      limit: parseFloat(limit),
      currentDebt: 0,
      statementDay: parseInt(statementDay),
      dueDay: parseInt(dueDay),
      color,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    onAdd(card);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center px-4 pb-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-md" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-strong rounded-3xl p-6 border border-gray-700/50 animate-bounce-in max-h-[85vh] overflow-y-auto overflow-x-hidden">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Yeni Kart</h2>
            <p className="text-gray-400 text-sm">Banka hesabına bağlı kredi kartı</p>
          </div>
          <button onClick={onClose} className="p-3 rounded-2xl glass hover:bg-gray-700/50 text-gray-400 btn-bounce">
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 pl-1">Kart Etiketi</label>
              <input 
                value={name} 
                onChange={(e) => setName(e.target.value)} 
                placeholder="Örn: Akbank Axess" 
                className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-4 text-white placeholder-gray-500 focus:border-blue-500/50 focus:bg-gray-800 focus:outline-none transition-all" 
                style={{ userSelect: 'text', WebkitUserSelect: 'text' }} 
                required 
              />
            </div>
            
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 pl-1">Bağlı Banka Hesabı</label>
              <div className="relative">
                <select 
                  value={bankAccountId} 
                  onChange={(e) => setBankAccountId(e.target.value)} 
                  className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-4 text-white appearance-none focus:border-blue-500/50 focus:bg-gray-800 focus:outline-none transition-all"
                  required
                >
                  {accounts.map(acc => (
                    <option key={acc.id} value={acc.id} className="bg-gray-900">{acc.name}</option>
                  ))}
                </select>
                <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-gray-500">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M5 7.5L10 12.5L15 7.5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 pl-1">Kart Limiti</label>
              <div className="relative">
                <input 
                  value={limit} 
                  onChange={(e) => setLimit(e.target.value)} 
                  type="number" 
                  step="100" 
                  placeholder="0.00" 
                  className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-4 pl-12 text-white placeholder-gray-500 focus:border-blue-500/50 focus:bg-gray-800 focus:outline-none transition-all" 
                  style={{ userSelect: 'text', WebkitUserSelect: 'text' }} 
                  required 
                />
                <span className="absolute left-5 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-lg">₺</span>
              </div>
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 pl-1">Kesim Günü</label>
                <input value={statementDay} onChange={(e) => setStatementDay(e.target.value)} type="number" min="1" max="31" className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-4 text-white focus:border-blue-500/50 focus:outline-none transition-all text-center font-bold" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 pl-1">Son Ödeme</label>
                <input value={dueDay} onChange={(e) => setDueDay(e.target.value)} type="number" min="1" max="31" className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-4 text-white focus:border-blue-500/50 focus:outline-none transition-all text-center font-bold" style={{ userSelect: 'text', WebkitUserSelect: 'text' }} />
              </div>
            </div>
            
            <div>
              <label className="block text-xs font-semibold text-gray-400 uppercase tracking-widest mb-2 pl-1">Görünüm</label>
              <div className="flex gap-4 flex-wrap justify-between px-1">
                {CARD_COLORS.map((c) => (
                  <button 
                    key={c.accent} 
                    type="button" 
                    onClick={() => setColor(c.accent)} 
                    className={`w-10 h-10 rounded-2xl transition-all duration-300 btn-bounce ${color === c.accent ? 'scale-110 ring-4 ring-blue-500/20 shadow-lg shadow-blue-500/10 border-2 border-white' : 'opacity-60 grayscale-[0.5]'}`} 
                    style={{ backgroundColor: c.accent }} 
                  />
                ))}
              </div>
            </div>
          </div>
          
          <button type="submit" className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-5 rounded-2xl font-bold text-lg btn-bounce shadow-xl shadow-blue-600/20 active:scale-95 transition-all mt-4 tracking-tight">
            Kartı Oluştur
          </button>
        </form>
      </div>
    </div>
  );
}

function PayDebtModal({ card, onClose, onPay }: { card: CreditCard; onClose: () => void; onPay: (amount: number) => void }) {
  const [amount, setAmount] = useState(card.currentDebt.toString());
  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center px-4 pb-4">
      <div className="absolute inset-0 bg-black/80 backdrop-blur-md" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-strong rounded-3xl p-6 border border-gray-700/50 animate-bounce-in">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Borç Öde</h2>
            <p className="text-gray-400 text-sm">{card.name} ödemesi ({card.bank} üzerinden)</p>
          </div>
          <button onClick={onClose} className="p-3 rounded-2xl glass hover:bg-gray-700/50 text-gray-400 btn-bounce"><XMarkIcon className="w-6 h-6" /></button>
        </div>
        
        <div className="bg-red-500/10 border border-red-500/20 rounded-2xl p-4 mb-8 text-center">
            <p className="text-gray-400 text-xs uppercase tracking-widest mb-1">Toplam Borç</p>
            <p className="text-2xl font-bold text-red-400">{formatCurrency(card.currentDebt)}</p>
        </div>
        
        <div className="space-y-6">
          <div className="relative">
            <input 
               value={amount} 
               onChange={(e) => setAmount(e.target.value)} 
               type="number" 
               step="0.01" 
               className="w-full bg-gray-800/50 border border-gray-700/50 rounded-2xl p-5 pl-12 text-white text-xl font-bold focus:border-green-500/50 focus:bg-gray-800 focus:outline-none transition-all" 
               style={{ userSelect: 'text', WebkitUserSelect: 'text' }} 
            />
            <span className="absolute left-5 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-xl">₺</span>
          </div>
          
          <div className="grid grid-cols-3 gap-3">
            <button onClick={() => setAmount((card.currentDebt / 4).toFixed(2))} className="glass py-4 rounded-2xl text-xs font-bold text-gray-300 btn-bounce border border-gray-700/50 hover:bg-gray-700/30 uppercase tracking-tighter">Asgari</button>
            <button onClick={() => setAmount((card.currentDebt / 2).toFixed(2))} className="glass py-4 rounded-2xl text-xs font-bold text-gray-300 btn-bounce border border-gray-700/50 hover:bg-gray-700/30 uppercase tracking-tighter">Yarısı</button>
            <button onClick={() => setAmount(card.currentDebt.toFixed(2))} className="glass py-4 rounded-2xl text-xs font-bold text-gray-300 btn-bounce border border-gray-700/50 hover:bg-gray-700/30 uppercase tracking-tighter font-black text-white">Tamamı</button>
          </div>
          
          <button 
             onClick={() => { onPay(parseFloat(amount)); onClose(); }} 
             className="w-full bg-gradient-to-r from-green-600 to-emerald-600 text-white py-5 rounded-2xl font-bold text-xl btn-bounce shadow-xl shadow-green-600/20 tracking-tight"
          >
            Ödemeyi Onayla
          </button>
        </div>
      </div>
    </div>
  );
}

export default function CardsPage() {
  const [cards, setCards] = useState<CreditCard[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [showAdd, setShowAdd] = useState(false);
  const [payingCard, setPayingCard] = useState<CreditCard | null>(null);
  const [isClient, setIsClient] = useState(false);

  useEffect(() => { 
    setIsClient(true);
    setCards(creditCardStorage.getAll()); 
    setAccounts(accountStorage.getAll().filter(acc => acc.type === 'bank'));
  }, []);

  if (!isClient) return null;

  const totalDebt = cards.reduce((s, c) => s + c.currentDebt, 0);
  const totalLimit = cards.reduce((s, c) => s + c.limit, 0);

  const handleAdd = (card: CreditCard) => {
    const updated = creditCardStorage.add(card);
    setCards(updated);
  };

  const handleDelete = (id: string) => {
    const updated = creditCardStorage.delete(id);
    setCards(updated);
  };

  const handlePay = (cardId: string, amount: number) => {
    const card = cards.find(c => c.id === cardId);
    if (!card) return;

    if (card.accountId) {
       const linkedAccount = accounts.find(a => a.id === card.accountId);
       if (linkedAccount && linkedAccount.balance < amount) {
          alert(`Yetersiz Bakiye!\n\n${linkedAccount.name} hesabında ${formatCurrency(linkedAccount.balance)} bulunuyor. Ödeme için ${formatCurrency(amount)} gerekiyor.`);
          return;
       }
       // Kredi kartı ödemesi bağlı banka hesabından düşer
       accountStorage.adjustBalance(card.accountId, -amount);
       setAccounts(accountStorage.getAll().filter(acc => acc.type === 'bank'));
    }
    
    // İşlemlere gider olarak ekle
    const newTransaction: Transaction = {
      id: generateId(),
      userId: 'local-user',
      type: 'expense',
      amount: Number(amount),
      category: 'Kredi Kartı Ödemesi',
      description: `${card.name} Borç Ödemesi`,
      date: new Date(),
      isPlanned: false, // Ana ekranda gözükmesi için zorunlu
      accountId: card.accountId,
      creditCardId: card.id,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    transactionStorage.add(newTransaction);
    
    creditCardStorage.adjustDebt(cardId, -amount);
    setCards(creditCardStorage.getAll());
    setPayingCard(null); // Modalı kapat
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 via-gray-900 to-[#0a0a0f] pb-32">
      {/* Mobile Top Bar */}
      <div className="px-6 pt-14 pb-8 animate-fade-in">
        <h1 className="text-3xl font-black text-white mb-6 tracking-tighter">Kredi Kartları</h1>
        
        <div className="grid grid-cols-2 gap-4">
          <div className="glass rounded-[2rem] p-5 border border-red-500/10 bg-red-500/5">
            <p className="text-[10px] text-red-300/60 uppercase font-black tracking-widest mb-1">Toplam Borç</p>
            <p className="text-xl font-bold text-red-400 tracking-tight">{formatCurrency(totalDebt)}</p>
          </div>
          <div className="glass rounded-[2rem] p-5 border border-blue-500/10 bg-blue-500/5">
            <p className="text-[10px] text-blue-300/60 uppercase font-black tracking-widest mb-1">Toplam Limit</p>
            <p className="text-xl font-bold text-blue-400 tracking-tight">{formatCurrency(totalLimit)}</p>
          </div>
        </div>
      </div>

      <div className="px-6 space-y-8">
        {accounts.length === 0 && (
           <div className="p-6 rounded-3xl bg-yellow-500/10 border border-yellow-500/20 animate-bounce-in">
              <div className="flex items-center gap-3 mb-3">
                 <ExclamationTriangleIcon className="w-6 h-6 text-yellow-500" />
                 <h3 className="text-yellow-500 font-bold">Banka Hesabı Gerekli</h3>
              </div>
              <p className="text-sm text-gray-400 mb-4 leading-relaxed">
                Kredi kartı ekleyebilmek için önce <strong>Hesaplar</strong> sayfasından en az bir adet <strong>Banka</strong> türünde hesap oluşturmalısınız.
              </p>
              <Link href="/accounts" className="inline-block bg-yellow-500 text-gray-900 font-black py-3 px-6 rounded-2xl text-sm btn-bounce">Hesaplara Git</Link>
           </div>
        )}

        {cards.length === 0 ? (
          <div className="text-center py-20 animate-fade-in">
            <div className="w-24 h-24 glass rounded-[2.5rem] flex items-center justify-center mx-auto mb-6 float border border-gray-700/30">
              <CreditCardIcon className="w-12 h-12 text-gray-500" />
            </div>
            <p className="text-gray-400 text-lg font-bold mb-1">Henüz kartın yok</p>
            <p className="text-gray-500 text-sm px-10">Tüm kredi kartlarını buradan takip etmeye başla.</p>
          </div>
        ) : (
          cards.map((card) => {
            const linkedAccount = accounts.find(a => a.id === card.accountId);
            return (
              <div key={card.id} className="space-y-4">
                <CreditCardVisual card={card} accountName={linkedAccount?.name} />
                <div className="flex gap-3">
                  <button 
                    onClick={() => setPayingCard(card)} 
                    className="flex-[2] bg-white text-gray-900 py-4 rounded-2xl text-sm font-black btn-bounce shadow-xl shadow-white/5 uppercase tracking-tighter"
                  >
                    Borç Öde
                  </button>
                  <button 
                    onClick={() => handleDelete(card.id)} 
                    className="flex-1 p-4 rounded-2xl glass border border-red-500/20 text-red-500 flex items-center justify-center btn-bounce hover:bg-red-500/5 transition-all"
                  >
                    <TrashIcon className="w-5 h-5" />
                  </button>
                </div>
              </div>
            )
          })
        )}
      </div>

      {accounts.length > 0 && (
        <button
          onClick={() => setShowAdd(true)}
          className="fixed bottom-28 right-6 w-16 h-16 rounded-[2rem] bg-gradient-to-b from-blue-500 to-indigo-600 flex items-center justify-center shadow-2xl shadow-blue-600/40 btn-bounce active:scale-90 z-50 border-t border-white/20"
        >
          <PlusIcon className="w-8 h-8 text-white" />
        </button>
      )}

      {showAdd && <AddCardModal accounts={accounts} onClose={() => setShowAdd(false)} onAdd={handleAdd} />}
      {payingCard && <PayDebtModal card={payingCard} onClose={() => setPayingCard(null)} onPay={(amount) => handlePay(payingCard.id, amount)} />}
    </div>
  );
}
