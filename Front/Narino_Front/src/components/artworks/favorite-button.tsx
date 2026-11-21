import { Heart } from 'lucide-react'
import { useLocation, useNavigate } from 'react-router-dom'

import { Button } from '@/components/ui/button'
import { ROUTES } from '@/constants/routes'
import { useFavorites } from '@/hooks/useFavorites'
import { useAuthStore } from '@/store/authStore'
import { cn } from '@/utils'

interface FavoriteButtonProps {
  artworkId: string
  className?: string
}

/** Agrega o quita una obra de favoritos. Sin sesión lleva al login y luego regresa a la obra. */
export function FavoriteButton({ artworkId, className }: FavoriteButtonProps) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const navigate = useNavigate()
  const location = useLocation()
  const { isFavorite, toggle, pendingId } = useFavorites()
  const active = isAuthenticated && isFavorite(artworkId)

  const handleClick = () => {
    if (!isAuthenticated) {
      navigate(ROUTES.LOGIN, { state: { from: location.pathname } })
      return
    }
    toggle(artworkId)
  }

  return (
    <Button
      type="button"
      variant="secondary"
      className={cn('w-full gap-2', className)}
      onClick={handleClick}
      disabled={pendingId === artworkId}
      aria-pressed={active}
    >
      <Heart size={18} className={cn(active && 'fill-current')} />
      {active ? 'En tus favoritos' : 'Guardar en favoritos'}
    </Button>
  )
}
