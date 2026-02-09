import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Use relative paths in the built index.html so it can be opened from
  // a subdirectory or via file:// without broken asset links.
  base: './',
})
