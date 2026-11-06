import { useMemo } from 'react'

import {
  getCartCount,
  getCartSubtotalCop,
  useCartStore,
} from '@/store/cartStore'

export function useCart() {
  const items = useCartStore((s) => s.items)
  const addItem = useCartStore((s) => s.addItem)
  const removeItem = useCartStore((s) => s.removeItem)
  const setQuantity = useCartStore((s) => s.updateQuantity)
  const clear = useCartStore((s) => s.clearCart)

  return useMemo(
    () => ({
      items,
      count: getCartCount(items),
      subtotalCop: getCartSubtotalCop(items),
      addItem,
      removeItem,
      setQuantity,
      clear,
    }),
    [items, addItem, removeItem, setQuantity, clear],
  )
}

