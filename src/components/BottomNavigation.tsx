'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  HomeIcon,
  BuildingLibraryIcon,
  CreditCardIcon,
  BanknotesIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline';
import {
  HomeIcon as HomeIconSolid,
  BuildingLibraryIcon as BuildingLibraryIconSolid,
  CreditCardIcon as CreditCardIconSolid,
  BanknotesIcon as BanknotesIconSolid,
  ChartBarIcon as ChartBarIconSolid,
} from '@heroicons/react/24/solid';

const NAV_ITEMS = [
  { href: '/', label: 'Ana Sayfa', icon: HomeIcon, activeIcon: HomeIconSolid },
  { href: '/accounts', label: 'Hesaplar', icon: BuildingLibraryIcon, activeIcon: BuildingLibraryIconSolid },
  { href: '/cards', label: 'Kartlar', icon: CreditCardIcon, activeIcon: CreditCardIconSolid },
  { href: '/loans', label: 'Krediler', icon: BanknotesIcon, activeIcon: BanknotesIconSolid },
  { href: '/statistics', label: 'İstatistik', icon: ChartBarIcon, activeIcon: ChartBarIconSolid },
];

export default function BottomNavigation() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 safe-area-bottom">
      <div
        className="glass-strong border-t border-gray-700/50"
        style={{ backdropFilter: 'blur(20px)' }}
      >
        <div className="flex items-stretch">
          {NAV_ITEMS.map((item) => {
            const isActive = pathname === item.href;
            const Icon = isActive ? item.activeIcon : item.icon;

            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex-1 flex flex-col items-center justify-center py-3 gap-1 transition-all duration-200 spring relative
                  ${isActive ? 'text-blue-400' : 'text-gray-500 hover:text-gray-300'}`}
              >
                {isActive && (
                  <span
                    className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-blue-400 rounded-full"
                    style={{ animation: 'slideInDown 0.3s ease-out' }}
                  />
                )}
                <Icon className="w-6 h-6" />
                <span className="text-xs font-medium">{item.label}</span>
              </Link>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
