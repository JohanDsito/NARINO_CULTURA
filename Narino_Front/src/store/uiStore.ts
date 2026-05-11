import { create } from 'zustand'

interface UIState {
  isSidebarOpen: boolean
  isChatOpen: boolean
  theme: 'light' | 'dark'
  toggleSidebar: () => void
  toggleChat: () => void
  setTheme: (theme: 'light' | 'dark') => void
}

export const useUIStore = create<UIState>((set) => ({
  isSidebarOpen: false,
  isChatOpen: false,
  theme: 'light',
  toggleSidebar: () => set((s) => ({ isSidebarOpen: !s.isSidebarOpen })),
  toggleChat: () => set((s) => ({ isChatOpen: !s.isChatOpen })),
  setTheme: (theme) => set({ theme }),
}))