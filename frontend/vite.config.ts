/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// In development the Rails API runs on :3000 (override with API_URL); Vite proxies /api so the app uses relative URLs
// everywhere, exactly as in production where Rails serves the built SPA.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': process.env.API_URL ?? 'http://localhost:3000',
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
    // Form tests type character by character; under a full parallel run they can exceed the 5s default.
    testTimeout: 15_000,
  },
})
