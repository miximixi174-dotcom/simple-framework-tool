import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  // 使用相对路径，便于 build 后双击 dist/index.html 直接打开
  base: './',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    // 内联较小的资源，减少 dist 文件碎片
    assetsInlineLimit: 4096,
    cssCodeSplit: false,
    rollupOptions: {
      output: {
        manualChunks: undefined
      }
    }
  },
  server: {
    port: 5173,
    open: true
  }
})
