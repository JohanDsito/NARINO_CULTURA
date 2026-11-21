import { useMemo } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

import { addFavorite, getFavorites, removeFavorite, type FavoriteItem } from '@/api/marketplace.api'
import { useAuthStore } from '@/store/authStore'
import { getApiErrorMessage } from '@/utils/apiError'

export const FAVORITES_KEY = ['favorites'] as const

interface ToggleVars {
  artworkId: string
  favorite: boolean // estado actual: true = quitar, false = agregar
}

/**
 * Favoritos del usuario autenticado. El cambio es optimista: el corazón se actualiza al instante y,
 * si el servidor falla, vuelve a su estado anterior y se avisa con un toast.
 */
export function useFavorites() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: FAVORITES_KEY,
    queryFn: () => getFavorites(),
    enabled: isAuthenticated,
    staleTime: 60 * 1000,
  })
  const favorites = useMemo(() => (isAuthenticated ? (query.data ?? []) : []), [isAuthenticated, query.data])
  const ids = useMemo(() => new Set(favorites.map((f) => f.artwork_id)), [favorites])

  const mutation = useMutation({
    mutationFn: ({ artworkId, favorite }: ToggleVars) =>
      favorite ? removeFavorite(artworkId) : addFavorite(artworkId),
    onMutate: async ({ artworkId, favorite }) => {
      await queryClient.cancelQueries({ queryKey: FAVORITES_KEY })
      const previous = queryClient.getQueryData<FavoriteItem[]>(FAVORITES_KEY)
      queryClient.setQueryData<FavoriteItem[]>(FAVORITES_KEY, (current = []) =>
        favorite
          ? current.filter((f) => f.artwork_id !== artworkId)
          : [
              ...current,
              { id: `pendiente-${artworkId}`, artwork_id: artworkId, title: '', artwork_price: '', artwork_image_url: '' },
            ],
      )
      return { previous }
    },
    onError: (error, _vars, context) => {
      queryClient.setQueryData(FAVORITES_KEY, context?.previous)
      toast.error(getApiErrorMessage(error))
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: FAVORITES_KEY }),
  })

  return {
    favorites,
    isLoading: query.isLoading,
    isError: query.isError,
    refetch: query.refetch,
    isFavorite: (artworkId: string) => ids.has(artworkId),
    toggle: (artworkId: string) => mutation.mutate({ artworkId, favorite: ids.has(artworkId) }),
    pendingId: mutation.isPending ? mutation.variables?.artworkId : undefined,
  }
}
