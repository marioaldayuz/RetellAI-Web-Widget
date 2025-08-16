/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "./public/**/*.html"
  ],
  theme: {
    extend: {
      animation: {
        'pulse': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'speech-wave': 'speech-wave 1.5s ease-in-out infinite',
        'fade-in': 'fadeIn 0.3s ease-out'
      },
      keyframes: {
        'speech-wave': {
          '0%, 100%': { height: '4px' },
          '50%': { height: '16px' }
        },
        'fadeIn': {
          'from': { 
            opacity: '0',
            transform: 'translateY(10px)'
          },
          'to': { 
            opacity: '1',
            transform: 'translateY(0)'
          }
        }
      }
    },
  },
  plugins: [],
}
