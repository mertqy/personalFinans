export const EXCHANGE_RATES: Record<string, number> = {
  TRY: 1,
  USD: 38.5,
  EUR: 41.2,
  GOLD: 3200, // 1 Gram Altın = 3200 TL (örnek)
};

export function convertToBaseCurrency(amount: number, fromCurrency: string = 'TRY', toCurrency: string = 'TRY'): number {
  if (fromCurrency === toCurrency) return amount;
  const inTRY = amount * (EXCHANGE_RATES[fromCurrency] || 1);
  return inTRY / (EXCHANGE_RATES[toCurrency] || 1);
}

export function formatCurrency(amount: number, currency: string = 'TRY'): string {
  // Altın için özel format (gram)
  if (currency === 'GOLD') {
    return `${amount.toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} gr`;
  }

  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatDate(date: Date | string): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  return dateObj.toLocaleDateString('tr-TR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  });
}

export function generateId(): string {
  return Math.random().toString(36).substr(2, 9);
} 