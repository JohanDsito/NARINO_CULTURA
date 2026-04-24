import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { ShoppingBag, Bell, LogOut, LogIn, Palette } from 'lucide-react'
import { toast } from 'sonner'
import type { ReactNode } from 'react'

import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { useAuthStore } from '@/store/authStore'
import { useCart } from '@/hooks/useCart'
import { useTheme } from '@/hooks/useTheme'
import { logout as logoutApi } from '@/api/auth.api'

export function Navbar() {
  const location = useLocation()
  const navigate = useNavigate()
  const { count } = useCart()
  const { theme, setTheme } = useTheme()

  const accessToken = useAuthStore((s) => s.accessToken)
  const refreshToken = useAuthStore((s) => s.refreshToken)
  const user = useAuthStore((s) => s.user)
  const logoutLocal = useAuthStore((s) => s.logout)

  const logoutMutation = useMutation({
    mutationFn: async () => {
      if (refreshToken) await logoutApi(refreshToken)
    },
    onSuccess: () => {
      logoutLocal()
      toast.success('Sesión cerrada.')
      navigate('/login', { replace: true })
    },
    onError: () => {
      logoutLocal()
      navigate('/login', { replace: true })
    },
  })

  const isActive = (path: string) => location.pathname === path

  return (
    <header className="sticky top-0 z-40 w-full border-b bg-background/80 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-5xl items-center justify-between px-4">
        <Link to="/" className="flex items-center gap-2" aria-label="Ir a inicio">
          <span className="font-display text-xl font-semibold text-primary">Nariño Cultura</span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex" aria-label="Navegación principal">
          <NavLink to="/artists" active={isActive('/artists')}>
            Artistas
          </NavLink>
          <NavLink to="/artworks" active={isActive('/artworks')}>
            Obras
          </NavLink>
          <NavLink to="/marketplace" active={isActive('/marketplace')}>
            Marketplace
          </NavLink>
          <NavLink to="/auctions" active={isActive('/auctions')}>
            Subastas
          </NavLink>
          <NavLink to="/events" active={isActive('/events')}>
            Eventos
          </NavLink>
        </nav>

        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            aria-label="Cambiar tema"
          >
            <Palette className="h-5 w-5" />
          </Button>

          <Link to="/notifications" aria-label="Notificaciones">
            <Button variant="ghost" size="icon">
              <Bell className="h-5 w-5" />
            </Button>
          </Link>

          <Link to="/checkout" aria-label="Carrito">
            <Button variant="ghost" size="icon" className="relative">
              <ShoppingBag className="h-5 w-5" />
              {count > 0 ? (
                <span className="absolute -right-1 -top-1 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-secondary px-1 text-xs font-semibold text-secondary-foreground">
                  {count}
                </span>
              ) : null}
            </Button>
          </Link>

          {accessToken ? (
            <Button
              variant="outline"
              onClick={() => logoutMutation.mutate()}
              disabled={logoutMutation.isPending}
              aria-label="Cerrar sesión"
            >
              <LogOut className="h-4 w-4" />
              <span className="hidden sm:inline">Salir</span>
            </Button>
          ) : (
            <Button
              asChild
              variant="outline"
              aria-label="Ir a iniciar sesión"
              className="gap-2"
            >
              <Link to="/login" state={{ from: location.pathname }}>
                <LogIn className="h-4 w-4" />
                <span className="hidden sm:inline">Entrar</span>
              </Link>
            </Button>
          )}

          {user ? (
            <span className="hidden text-sm text-muted-foreground lg:inline">
              {user.firstName || user.email}
            </span>
          ) : null}
        </div>
      </div>
    </header>
  )
}

function NavLink({
  to,
  active,
  children,
}: {
  to: string
  active: boolean
  children: ReactNode
}) {
  return (
    <Link
      to={to}
      className={cn(
        'rounded-md px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground',
        active && 'bg-muted text-foreground',
      )}
    >
      {children}
    </Link>
  )
}
