import { useQuery } from '@tanstack/react-query'

import { getServerCart } from '@/api/marketplace.api'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'

/**
 * Número de obras en el carrito. Con sesión iniciada el carrito vive en el
 * backend (el local se sincroniza y vacía al iniciar sesión); sin sesión se
 * usa el carrito local de invitado.
 */
export function useCartCount(): number {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const localCount = useCartStore((s) => s.items.length)

  const { data: serverCart } = useQuery({
    queryKey: ['server-cart'],
    queryFn: () => getServerCart(),
    enabled: isAuthenticated,
    staleTime: 30 * 1000,
  })

  return isAuthenticated ? (serverCart?.items.length ?? 0) : localCount
}
