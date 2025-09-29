import defaultTheme from 'tailwindcss/defaultTheme'
import forms from '@tailwindcss/forms'
import typography from '@tailwindcss/typography'

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './resources/views/**/*.blade.php',
    './resources/js/**/*.js',
    './resources/js/**/*.ts',
    './resources/js/**/*.vue',
    './resources/js/**/*.tsx',
    './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
    './storage/framework/views/*.php'
  ],
  safelist: [
    'bg-emerald-500',
    'text-emerald-600',
    'bg-amber-500',
    'text-amber-500',
    'from-emerald-500',
    'to-emerald-700'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          navy: '#1C3D5A',
          mist: '#F7F9FC',
          gold: '#F0A500',
          amber: '#FCDFA6',
          evergreen: '#3D9A74',
          slate: '#334155',
          ash: '#64748B'
        }
      },
      fontFamily: {
        display: ['var(--font-display)', ...defaultTheme.fontFamily.serif],
        sans: ['var(--font-sans)', ...defaultTheme.fontFamily.sans]
      },
      boxShadow: {
        'xl-soft': '0 25px 50px -12px rgba(15, 23, 42, 0.25)'
      },
      keyframes: {
        'fade-in-up': {
          '0%': { opacity: 0, transform: 'translateY(20px)' },
          '100%': { opacity: 1, transform: 'translateY(0)' }
        },
        marquee: {
          '0%': { transform: 'translateX(0)' },
          '100%': { transform: 'translateX(-50%)' }
        }
      },
      animation: {
        'fade-in-up': 'fade-in-up 0.6s ease-out forwards',
        marquee: 'marquee 25s linear infinite'
      }
    }
  },
  plugins: [forms, typography]
}
