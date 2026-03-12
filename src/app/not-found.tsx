'use client';

import Link from 'next/link';
import { HomeIcon } from '@heroicons/react/24/outline';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#0a0a0f] flex flex-col items-center justify-center px-6 text-center">
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
        <div className="absolute -top-24 -left-24 w-96 h-96 bg-blue-600/10 rounded-full blur-[120px]" />
        <div className="absolute -bottom-24 -right-24 w-96 h-96 bg-purple-600/10 rounded-full blur-[120px]" />
      </div>

      <div className="relative z-10 animate-fade-in">
        <h1 className="text-8xl font-black text-white/10 mb-4 tracking-tighter">404</h1>
        <h2 className="text-3xl font-black text-white mb-2 tracking-tight">Sayfa Bulunamadı</h2>
        <p className="text-gray-500 mb-10 max-w-xs mx-auto leading-relaxed">
          Aradığınız sayfa mevcut değil veya taşınmış olabilir.
        </p>
        
        <Link 
          href="/"
          className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-8 py-4 rounded-2xl font-black btn-bounce shadow-xl shadow-blue-600/20"
        >
          <HomeIcon className="w-5 h-5" />
          Ana Sayfaya Dön
        </Link>
      </div>
    </div>
  );
}
