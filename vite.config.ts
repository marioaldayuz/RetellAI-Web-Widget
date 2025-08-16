import { defineConfig } from 'vite'
import { resolve } from 'path'

export default defineConfig({
  build: {
    lib: {
      entry: resolve(__dirname, 'src/widget.ts'),
      name: 'RetellWidget',
      fileName: 'retell-widget',
      formats: ['iife']
    },
    rollupOptions: {
      output: {
        entryFileNames: 'retell-widget.js',
        assetFileNames: 'retell-widget.css'
      }
    }
  },
  server: {
    open: '/index.html'
  },
  css: {
    postcss: './postcss.config.js'
  }
})
