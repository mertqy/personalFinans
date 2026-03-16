'use client';

import { useForm } from 'react-hook-form';
import { useState } from 'react';
import { DEFAULT_CATEGORIES } from '@/lib/constants';
import { formatCurrency } from '@/lib/utils';
import type { Account, CreditCard } from '@/types';
import { MapPinIcon, MapIcon } from '@heroicons/react/24/outline';

interface TransactionFormData {
  type: 'income' | 'expense';
  amount: number;
  category: string;
  description: string;
  date: string;
  isRecurring: boolean;
  recurringFrequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
  accountId?: string;
  creditCardId?: string;
  location?: { lat: number; lng: number };
}

interface TransactionFormProps {
  type: 'income' | 'expense';
  onSubmit: (data: TransactionFormData) => void;
  onCancel: () => void;
  initialData?: Partial<TransactionFormData>;
  accounts?: Account[];
  creditCards?: CreditCard[];
}

export default function TransactionForm({
  type,
  onSubmit,
  onCancel,
  initialData,
  accounts = [],
  creditCards = [],
}: TransactionFormProps) {
  const [location, setLocation] = useState<{ lat: number; lng: number } | undefined>(undefined);
  const [isGettingLocation, setIsGettingLocation] = useState(false);
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting }
  } = useForm<TransactionFormData>({
    defaultValues: {
      type,
      amount: initialData?.amount || 0,
      category: initialData?.category || '',
      description: initialData?.description || '',
      date: initialData?.date || new Date().toISOString().split('T')[0],
      isRecurring: initialData?.isRecurring || false,
      recurringFrequency: initialData?.recurringFrequency || 'monthly',
      accountId: initialData?.accountId || '',
      creditCardId: initialData?.creditCardId || '',
    }
  });

  const isRecurring = watch('isRecurring');
  const watchedCreditCardId = watch('creditCardId');
  const watchedAccountId = watch('accountId');
  const availableLinkedCards = creditCards.filter(c => c.accountId === watchedAccountId);
  const categories = DEFAULT_CATEGORIES.filter(cat => cat.type === type);

  const handleGetLocation = () => {
    if (!navigator.geolocation) {
      alert('Tarayıcınız konum özelliğini desteklemiyor.');
      return;
    }

    setIsGettingLocation(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude
        });
        setIsGettingLocation(false);
      },
      (error) => {
        console.error('Location error:', error);
        alert('Konum alınamadı. Lütfen izinleri kontrol edin.');
        setIsGettingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
    );
  };

  const handleFormSubmit = async (data: TransactionFormData) => {
    try {
      await onSubmit({
        ...data,
        accountId: data.accountId || undefined,
        creditCardId: data.creditCardId === 'none' ? undefined : (data.creditCardId || undefined),
        location: location
      });
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-3">
      {/* Miktar */}
      <div>
        <label htmlFor="amount" className="block text-sm font-medium text-white mb-1">
          Miktar (₺)
        </label>
        <input
          type="number"
          step="0.01"
          min="0"
          id="amount"
          {...register('amount', {
            required: 'Miktar gereklidir',
            min: { value: 0.01, message: 'Miktar 0\'dan büyük olmalıdır' },
            valueAsNumber: true
          })}
          className="w-full px-3 py-2 border border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white placeholder-gray-400 bg-gray-800"
          style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
          placeholder="0.00"
        />
        {errors.amount && (
          <p className="mt-1 text-xs text-red-400">{errors.amount.message}</p>
        )}
      </div>

      {/* Kategori */}
      <div>
        <label htmlFor="category" className="block text-sm font-medium text-white mb-1">
          Kategori
        </label>
        <select
          id="category"
          {...register('category', { required: 'Kategori seçimi gereklidir' })}
          className="w-full px-3 py-2 border border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white bg-gray-800"
        >
          <option value="" className="text-gray-400">Kategori seçin</option>
          {categories.map((category) => (
            <option key={category.id} value={category.name} className="text-white">
              {category.icon} {category.name}
            </option>
          ))}
        </select>
        {errors.category && (
          <p className="mt-1 text-xs text-red-400">{errors.category.message}</p>
        )}
      </div>

      {/* Hesap Seçimi */}
      <div>
        <label htmlFor="accountId" className="block text-sm font-medium text-white mb-1">
          {type === 'income' ? 'Giriş Hesabı' : 'Hangi Hesaptan Çıkacak'} <span className="font-bold text-red-400 text-xs">(Zorunlu)</span>
        </label>
        <select
          id="accountId"
          {...register('accountId', { 
            validate: (val) => {
              if (!val) return 'Lütfen bir işlem hesabı seçin.';
              return true;
            }
          })}
          className={`w-full px-3 py-2 border ${errors.accountId ? 'border-red-500' : 'border-gray-600'} rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white bg-gray-800`}
        >
          <option value="">{accounts.length === 0 ? '❌ Önce Hesaplar sekmesinden bir hesap oluşturun!' : 'Hesap seçin...'}</option>
          {accounts.map((account) => (
            <option key={account.id} value={account.id}>
              {account.icon} {account.name} — {formatCurrency(account.balance)}
            </option>
          ))}
        </select>
        {errors.accountId && (
          <p className="mt-1 text-xs text-red-400 font-bold">{errors.accountId.message}</p>
        )}
      </div>

      {/* Kredi Kartı Seçimi (sadece gider için ve seçili hesaba kart bağlıysa) */}
      {type === 'expense' && watchedAccountId && availableLinkedCards.length > 0 && (
        <div className="animate-slide-up">
          <label htmlFor="creditCardId" className="block text-sm font-medium text-white mb-1">
            Ödeme Yöntemi <span className="text-gray-400 font-normal">(Zorunlu)</span>
          </label>
          <select
            id="creditCardId"
            {...register('creditCardId', {
              required: 'Lütfen bir harcama/ödeme yöntemi seçin'
            })}
            className={`w-full px-3 py-2 border ${errors.creditCardId ? 'border-red-500' : 'border-gray-600'} rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white bg-gray-800`}
          >
            <option value="">Harcama Yöntemi Seçin...</option>
            <option value="none" className="font-bold text-blue-400">💵 Doğrudan Hesap Bakiyesinden Düş</option>
            <optgroup label="💳 Veya Kredi Kartından Çek">
              {availableLinkedCards.map((card) => (
                <option key={card.id} value={card.id}>
                   {card.name} (Limitten Düş)
                </option>
              ))}
            </optgroup>
          </select>
          {errors.creditCardId && (
            <p className="mt-1 text-xs text-red-400 font-bold">{errors.creditCardId.message}</p>
          )}
        </div>
      )}

      {/* Açıklama */}
      <div>
        <label htmlFor="description" className="block text-sm font-medium text-white mb-1">
          Açıklama <span className="text-gray-400 font-normal">(isteğe bağlı)</span>
        </label>
        <input
          type="text"
          id="description"
          {...register('description')}
          className="w-full px-3 py-2 border border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white placeholder-gray-400 bg-gray-800"
          style={{ userSelect: 'text', WebkitUserSelect: 'text' }}
          placeholder="Ek açıklama..."
        />
      </div>

      {/* Tarih */}
      <div>
        <label htmlFor="date" className="block text-sm font-medium text-white mb-1">
          Tarih
        </label>
        <input
          type="date"
          id="date"
          {...register('date', { required: 'Tarih gereklidir' })}
          className="w-full px-3 py-2 border border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white bg-gray-800"
          style={{ colorScheme: 'dark' }}
        />
        {errors.date && (
          <p className="mt-1 text-xs text-red-400">{errors.date.message}</p>
        )}
      </div>

      {/* Tekrarlayan İşlem */}
      <div className="flex gap-4">
        <div className="flex-1">
          <div className="flex items-center">
            <input
              type="checkbox"
              id="isRecurring"
              {...register('isRecurring')}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-600 rounded bg-gray-700"
            />
            <label htmlFor="isRecurring" className="ml-2 block text-sm text-white">
              Tekrarlayan işlem
            </label>
          </div>

          {isRecurring && (
            <div className="mt-2">
              <select
                id="recurringFrequency"
                {...register('recurringFrequency')}
                className="w-full px-3 py-2 border border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors text-white bg-gray-800"
              >
                <option value="daily">Günlük</option>
                <option value="weekly">Haftalık</option>
                <option value="monthly">Aylık</option>
                <option value="yearly">Yıllık</option>
              </select>
            </div>
          )}
        </div>

        <div className="flex-1">
          <button
            type="button"
            onClick={handleGetLocation}
            className={`w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg border transition-all text-xs font-bold ${
              location 
                ? 'bg-blue-500/20 border-blue-500/50 text-blue-400' 
                : 'bg-gray-800 border-gray-700 text-gray-400 hover:border-gray-600'
            }`}
          >
            {isGettingLocation ? (
              <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
            ) : (
              <MapPinIcon className="w-4 h-4" />
            )}
            {location ? 'Konum Alındı' : 'Konum Ekle'}
          </button>
          
          {location && (
            <p className="mt-1 text-[8px] text-gray-500 text-center font-mono uppercase tracking-tighter">
              {location.lat.toFixed(4)}, {location.lng.toFixed(4)}
            </p>
          )}
        </div>
      </div>

      {/* Butonlar */}
      <div className="flex space-x-2 pt-3">
        <button
          type="button"
          onClick={onCancel}
          className="flex-1 px-3 py-2 text-sm font-medium text-gray-300 bg-gray-700 border border-gray-600 rounded-lg hover:bg-gray-600 transition-colors"
        >
          İptal
        </button>
        <button
          type="submit"
          disabled={isSubmitting}
          className={`flex-1 px-3 py-2 text-sm font-medium text-white rounded-lg transition-colors ${
            type === 'income'
              ? 'bg-green-600 hover:bg-green-700'
              : 'bg-red-600 hover:bg-red-700'
          } disabled:opacity-50 disabled:cursor-not-allowed`}
        >
          {isSubmitting ? 'Kaydediliyor...' : (type === 'income' ? 'Gelir Ekle' : 'Gider Ekle')}
        </button>
      </div>
    </form>
  );
}