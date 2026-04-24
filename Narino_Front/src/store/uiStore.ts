import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export type ThemeMode = 'light' | 'dark' | 'system'

function applyTheme(mode: ThemeMode) {
  const root = document.documentElement
  const systemDark = window.matchMedia?.('(prefers-color-scheme: dark)').matches
  const shouldUseDark = mode === 'dark' || (mode === 'system' && systemDark)
  root.classList.toggle('dark', shouldUseDark)
}

interface UiState {
  theme: ThemeMode
  setTheme: (theme: ThemeMode) => void
  initTheme: () => void
}

export const useUiStore = create<UiState>()(
  persist(
    (set, get) => ({
      theme: 'system',
      setTheme: (theme) => {
        set({ theme })
        applyTheme(theme)
      },
      initTheme: () => {
        applyTheme(get().theme)
      },
    }),
    {
      name: 'narino_cultura_ui',
      version: 1,
      partialize: (state) => ({ theme: state.theme }),
    },
  ),
)

