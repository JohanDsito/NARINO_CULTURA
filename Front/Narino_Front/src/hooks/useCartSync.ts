import { addCartItem } from '@/api/marketplace.api'
import { useCartStore } from '@/store/cartStore'

// Syncs the local (guest) cart to the backend server cart on login.
// Called once after setAuth() succeeds so guest items are preserved.
export async function syncCartToServer(): Promise<void> {
  const items = useCartStore.getState().items
  if (items.length === 0) return

  const results = await Promise.allSettled(
    items.map((item) => addCartItem(item.artwork_id)),
  )

  // Clear local cart regardless — items now live on the server
  const hasAtLeastOneSuccess = results.some((r) => r.status === 'fulfilled')
  if (hasAtLeastOneSuccess) {
    useCartStore.getState().clearCart()
  }
}
