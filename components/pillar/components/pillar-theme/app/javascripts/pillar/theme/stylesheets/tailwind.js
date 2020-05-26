const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  theme: {
    extend: {
      colors: {
        primary: {
          50:  '#E5FCED',
          100: '#E8F8EE',
          200: '#C6EED4',
          300: '#A4E3BB',
          400: '#5FCE87',
          500: '#1BB954',
          600: '#18A74C',
          700: '#106F32',
          800: '#0C5326',
          900: '#083819',
        },
        secondary: {
          50:  '#E9E9E9',
          100: '#E9E9E9',
          200: '#C7C7C8',
          300: '#A5A6A7',
          400: '#626365',
          450: '#404144',
          500: '#1E2023',
          600: '#1B1D20',
          700: '#121315',
          800: '#0E0E10',
          900: '#090A0B',
        },
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {},
  plugins: [
    require('@tailwindcss/ui'),
  ],
}
