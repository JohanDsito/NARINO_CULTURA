import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
<<<<<<< HEAD
import path from 'node:path'
=======
>>>>>>> 22dcc9d4de8fb95d562380bbf3d6905ae84f0518

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
<<<<<<< HEAD
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
=======
>>>>>>> 22dcc9d4de8fb95d562380bbf3d6905ae84f0518
})
