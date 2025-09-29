import { defineConfig } from 'vite'
import laravel from 'laravel-vite-plugin'
import path from 'path'

export default defineConfig({
  plugins: [
    laravel({
      input: ['resources/css/app.css', 'resources/js/app.js'],
      refresh: ['resources/views/**', 'resources/js/**', 'app/Http/Controllers/**', 'routes/**']
    })
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'resources/js')
    }
  },
  server: {
    host: '0.0.0.0',
    port: 5173,
    hmr: {
      host: 'localhost'
    }
  },
  build: {
    chunkSizeWarningLimit: 1200
  }
})
