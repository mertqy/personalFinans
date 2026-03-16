'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  HomeIcon,
  ChartBarIcon,
  CreditCardIcon,
  ScaleIcon,
  PlusIcon,
} from '@heroicons/react/24/outline';
import {
  HomeIcon as HomeIconSolid,
  ChartBarIcon as ChartBarIconSolid,
  CreditCardIcon as CreditCardIconSolid,
  ScaleIcon as ScaleIconSolid,
} from '@heroicons/react/24/solid';

const NAV_ITEMS = [
  { href: '/', label: 'Ana Sayfa', icon: HomeIcon, activeIcon: HomeIconSolid },
  { href: '/statistics', label: 'İstatistik', icon: ChartBarIcon, activeIcon: ChartBarIconSolid },
  { href: '__fab__', label: '', icon: PlusIcon, activeIcon: PlusIcon },
  { href: '/payments', label: 'Ödemeler', icon: CreditCardIcon, activeIcon: CreditCardIconSolid },
  { href: '/budget', label: 'Bütçe', icon: ScaleIcon, activeIcon: ScaleIconSolid },
];

export default function BottomNavigation() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 safe-area-bottom">
      <div
        className="glass-strong"
        style={{ borderTop: '1px solid rgba(99, 102, 241, 0.1)' }}
      >
        <div className="flex items-end justify-around px-2">
          {NAV_ITEMS.map((item) => {
            if (item.href === '__fab__') {
              return (
                <Link
                  key="fab"
                  href="/"
                  className="relative -top-5 w-14 h-14 rounded-2xl flex items-center justify-center shadow-2xl shadow-indigo-500/40 btn-bounce"
                  style={{ background: 'linear-gradient(135deg, #6C5CE7, #3B82F6)' }}
                >
                  <PlusIcon className="w-7 h-7 text-white stroke-[3]" />
                </Link>
              );
            }

            const isActive = pathname === item.href;
            const Icon = isActive ? item.activeIcon : item.icon;

            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex-1 flex flex-col items-center justify-center py-3 gap-1 transition-all duration-200 spring relative
                  ${isActive ? 'text-indigo-400' : 'text-[#64748B] hover:text-[#94A3B8]'}`}
              >
                {isActive && (
                  <span
                    className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 rounded-full"
                    style={{ background: 'linear-gradient(90deg, #6C5CE7, #3B82F6)', animation: 'slideInDown 0.3s ease-out' }}
                  />
                )}
                <Icon className="w-6 h-6" />
                <span className="text-[10px] font-bold">{item.label}</span>
              </Link>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
