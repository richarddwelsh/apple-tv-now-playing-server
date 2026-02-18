import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Use relative paths in the built index.html so it can be opened from
  // a subdirectory or via file:// without broken asset links.
  base: './',
  server: {
    // Listen on all interfaces so machines on the LAN can reach the dev server.
    host: '0.0.0.0',
    // Restrict which hostnames are accepted to avoid DNS-rebinding issues.
    allowedHosts: ['zinc.local'],
    // Ensure the HMR websocket resolves correctly when accessed via the LAN hostname.
    hmr: { host: 'zinc.local' }
  }
})
