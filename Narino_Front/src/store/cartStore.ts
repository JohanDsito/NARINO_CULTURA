import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export interface CartItem {
  id: string
  title: string
  priceCop: number
  imageUrl?: string
  quantity: number
}

interface CartState {
  items: CartItem[]
  addItem: (item: Omit<CartItem, 'quantity'> & { quantity?: number }) => void
  removeItem: (id: string) => void
  setQuantity: (id: string, quantity: number) => void
  clear: () => void
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      items: [],
      addItem: (item) => {
        const quantity = Math.max(1, item.quantity ?? 1)
        const items = get().items
        const existing = items.find((i) => i.id === item.id)
        if (existing) {
          set({
            items: items.map((i) =>
              i.id === item.id ? { ...i, quantity: i.quantity + quantity } : i,
            ),
          })
          return
        }
        set({ items: [...items, { ...item, quantity }] })
      },
      removeItem: (id) => set({ items: get().items.filter((i) => i.id !== id) }),
      setQuantity: (id, quantity) => {
        const next = Math.max(1, quantity)
        set({
          items: get().items.map((i) => (i.id === id ? { ...i, quantity: next } : i)),
        })
      },
      clear: () => set({ items: [] }),
    }),
    {
      name: 'narino_cultura_cart',
      version: 1,
      partialize: (state) => ({ items: state.items }),
    },
  ),
)

export function getCartCount(items: CartItem[]) {
  return items.reduce((acc, item) => acc + item.quantity, 0)
}

export function getCartSubtotalCop(items: CartItem[]) {
  return items.reduce((acc, item) => acc + item.priceCop * item.quantity, 0)
}

