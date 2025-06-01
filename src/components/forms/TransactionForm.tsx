'use client';

import { useForm } from 'react-hook-form';
import { DEFAULT_CATEGORIES } from '@/lib/constants';

interface TransactionFormData {
  type: 'income' | 'expense';
  amount: number;
  category: string;
  description: string;
  date: string;
  isRecurring: boolean;
  recurringFrequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
}

interface TransactionFormProps {
  type: 'income' | 'expense';
  onSubmit: (data: TransactionFormData) => void;
  onCancel: () => void;
  initialData?: Partial<TransactionFormData>;
}

export default function TransactionForm({ 
  type, 
  onSubmit, 
  onCancel, 
  initialData 
}: TransactionFormProps) {
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
    }
  });

  const isRecurring = watch('isRecurring');
  const categories = DEFAULT_CATEGORIES.filter(cat => cat.type === type);

  const handleFormSubmit = async (data: TransactionFormData) => {
    try {
      await onSubmit(data);
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
        />
        {errors.date && (
          <p className="mt-1 text-xs text-red-400">{errors.date.message}</p>
        )}
      </div>

      {/* Tekrarlayan İşlem */}
      <div>
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