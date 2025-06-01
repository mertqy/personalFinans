/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      animation: {
        'progress': 'progress 800ms ease-in-out',
        'bounce-delay-100': 'bounce 1s infinite 100ms',
        'bounce-delay-200': 'bounce 1s infinite 200ms',
        'spin-delay-75': 'spin 1s linear infinite 75ms',
      },
      keyframes: {
        progress: {
          '0%': { transform: 'translateX(-100%)' },
          '80%': { transform: 'translateX(-10%)' },
          '100%': { transform: 'translateX(0%)' },
        },
      },
      animationDelay: {
        '75': '75ms',
        '100': '100ms',
        '200': '200ms',
      }
    },
  },
  plugins: [],
} 