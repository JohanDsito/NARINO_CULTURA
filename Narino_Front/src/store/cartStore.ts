import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export interface CartItem {
  id: number
  artwork_id: number
  title: string
  artist_name: string
  price: number
  image: string
  quantity: number
}

export function getCartCount(items: CartItem[]) {
  return items.reduce((acc, item) => acc + item.quantity, 0)
}

export function getCartSubtotalCop(items: CartItem[]) {
  return items.reduce((acc, item) => acc + item.price * item.quantity, 0)
}

interface CartState {
  items: CartItem[]
  isOpen: boolean
  addItem: (item: Omit<CartItem, 'quantity'>) => void
  removeItem: (artwork_id: number) => void
  updateQuantity: (artwork_id: number, quantity: number) => void
  clearCart: () => void
  toggleCart: () => void
  total: () => number
  itemCount: () => number
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      isOpen: false,

      addItem: (item) => {
        const existing = get().items.find((i) => i.artwork_id === item.artwork_id)
        if (existing) return
        set((state) => ({ items: [...state.items, { ...item, quantity: 1 }] }))
      },

      removeItem: (artwork_id) =>
        set((state) => ({ items: state.items.filter((i) => i.artwork_id !== artwork_id) })),

      updateQuantity: (artwork_id, quantity) =>
        set((state) => ({
          items: state.items.map((i) =>
            i.artwork_id === artwork_id ? { ...i, quantity } : i
          ),
        })),

      clearCart: () => set({ items: [] }),

      toggleCart: () => set((state) => ({ isOpen: !state.isOpen })),

      total: () => get().items.reduce((acc, i) => acc + i.price * i.quantity, 0),

      itemCount: () => get().items.reduce((acc, i) => acc + i.quantity, 0),
    }),
    {
      name: 'cart-storage',
      partialize: (state) => ({ items: state.items }),
    }
  )
)