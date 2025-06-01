'use client';

import { useEffect, useRef } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

export default function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
      document.body.style.overflow = 'hidden'; // Prevent background scroll
      
      return () => {
        document.removeEventListener('keydown', handleEscape);
        document.body.style.overflow = 'unset';
      };
    }
  }, [isOpen, onClose]);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (modalRef.current && !modalRef.current.contains(e.target as Node)) {
        onClose();
      }
    };

    if (isOpen) {
      // Add slight delay to prevent immediate closure
      setTimeout(() => {
        document.addEventListener('mousedown', handleClickOutside);
      }, 100);
      
      return () => {
        document.removeEventListener('mousedown', handleClickOutside);
      };
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <>
      {/* Backdrop */}
      <div className="fixed inset-0 z-50 overflow-y-auto">
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm animate-fade-in" />
        
        {/* Modal Container */}
        <div className="flex min-h-full items-center justify-center p-4">
          <div
            ref={modalRef}
            className="relative w-full max-w-md transform overflow-hidden rounded-2xl 
              glass-strong shadow-2xl transition-all duration-300 animate-bounce-in
              border border-gray-600/30"
          >
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-600/30">
              <h3 className="text-xl font-bold text-white animate-slide-right">
                {title}
              </h3>
              <button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-white transition-all duration-200 
                  hover:bg-gray-700/50 rounded-full btn-bounce"
              >
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            {/* Content */}
            <div className="p-6 animate-fade-in" style={{ animationDelay: '0.1s' }}>
              {children}
            </div>

            {/* Decorative gradient overlay */}
            <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 to-purple-500 opacity-50" />
          </div>
        </div>
      </div>
    </>
  );
} 