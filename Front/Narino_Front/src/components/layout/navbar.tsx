import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import {
  Bell,
  Heart,
  LayoutDashboard,
  LogOut,
  Menu,
  Moon,
  Mountain,
  ShoppingCart,
  Sun,
  X,
} from 'lucide-react'

import { useLogout } from '@/hooks/useAuth'
import { useAuthStore } from '@/store/authStore'
import { useCartCount } from '@/hooks/useCartCount'
import { useUnreadNotifications } from '@/hooks/useUnreadNotifications'
import { useThemeStore } from '@/store/themeStore'
import { getArtistDashboardPath } from '@/utils/artistDiscipline'

const links = [
  { to: '/artists', label: 'Artistas' },
  { to: '/artworks', label: 'Obras' },
  { to: '/musicians', label: 'Músicos' },
  { to: '/marketplace', label: 'Marketplace' },
  { to: '/auctions', label: 'Subastas' },
  { to: '/events', label: 'Eventos' },
]

export function Navbar() {
  const { theme, toggle } = useThemeStore()
  const { pathname } = useLocation()
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const cartCount = useCartCount()
  const unreadCount = useUnreadNotifications()
  const user = useAuthStore((s) => s.user)
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const logout = useLogout()

  const artistDashboardPath = user?.id ? getArtistDashboardPath(user.id) : '/dashboard'

  const accountPath =
    user?.role === 'admin'
      ? '/admin/dashboard'
      : user?.role === 'artist'
        ? artistDashboardPath
        : user?.role === 'cultural_manager'
          ? '/events'
          : '/marketplace'

  const closeMenu = () => setIsMenuOpen(false)

  const renderLinks = (className: string) =>
    links.map(({ to, label }) => {
      const isActive = pathname.startsWith(to)

      return (
        <Link
          key={to}
          to={to}
          onClick={closeMenu}
          aria-current={isActive ? 'page' : undefined}
          className={`font-body text-sm font-medium no-underline transition-colors duration-300 ${
            isActive ? 'text-azul font-semibold' : 'text-text-secondary hover:text-text-primary'
          } ${className}`}
        >
          {label}
        </Link>
      )
    })

  return (
    <nav className="nc-glass fixed inset-x-0 top-0 z-50 border-b border-border px-4 md:px-10">
      <div className="flex h-16 items-center justify-between gap-4">
        <Link to="/" className="flex items-center gap-2 no-underline" onClick={closeMenu}>
          <div className="nc-brand flex h-8 w-8 items-center justify-center rounded-[10px]">
            <Mountain size={16} className="text-white" />
          </div>
          {/* En pantallas angostas solo queda el logo (el nombre sigue disponible para lectores de pantalla) */}
          <span className="sr-only whitespace-nowrap font-display text-lg font-extrabold text-text-primary min-[430px]:not-sr-only">
            Nariño Cultura
          </span>
        </Link>

        <div className="hidden items-center gap-7 md:flex">{renderLinks('')}</div>

        <div className="flex items-center gap-2 md:gap-4">
          {isAuthenticated && (
            <Link
              to="/favorites"
              aria-label="Mis favoritos"
              className="inline-flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-bg-subtle"
            >
              <Heart size={20} className="text-text-primary" />
            </Link>
          )}

          <Link
            to="/checkout"
            aria-label={`Carrito de compras${cartCount > 0 ? `, ${cartCount} productos` : ''}`}
            className="relative inline-flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-bg-subtle"
          >
            <ShoppingCart size={20} className="text-text-primary" />
            {cartCount > 0 && (
              <span className="absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-tomate-fill px-1 text-[10px] font-bold text-on-tomate">
                {cartCount}
              </span>
            )}
          </Link>

          <Link
            to="/notifications"
            aria-label={`Notificaciones${unreadCount > 0 ? `, ${unreadCount} sin leer` : ''}`}
            className="relative inline-flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-bg-subtle"
          >
            <Bell size={20} className="text-text-primary" />
            {unreadCount > 0 && (
              <span className="absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-tomate-fill px-1 text-[10px] font-bold text-on-tomate">
                {unreadCount > 99 ? '99+' : unreadCount}
              </span>
            )}
          </Link>

          <button
            type="button"
            onClick={toggle}
            aria-label="Cambiar modo de color"
            className="flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-bg-subtle"
          >
            {theme === 'light' ? (
              <Moon size={18} className="text-text-primary" />
            ) : (
              <Sun size={18} className="text-text-primary" />
            )}
          </button>

          {isAuthenticated ? (
            <>
              <Link
                to={accountPath}
                className="hidden items-center gap-2 rounded-btn bg-azul-fill px-4 py-2 font-body text-[13px] font-semibold text-on-azul no-underline transition-all duration-200 ease-spring active:scale-[0.96] hover:bg-azul-fill/90 md:inline-flex"
              >
                <LayoutDashboard size={15} />
                Mi panel
              </Link>
              <button
                type="button"
                onClick={() => void logout()}
                aria-label="Cerrar sesión"
                className="hidden h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-bg-subtle md:inline-flex"
              >
                <LogOut size={18} className="text-text-primary" />
              </button>
            </>
          ) : (
            <Link
              to="/login"
              className="hidden rounded-btn bg-azul-fill px-4 py-2 font-body text-[13px] font-semibold text-on-azul no-underline transition-all duration-200 ease-spring active:scale-[0.96] hover:bg-azul-fill/90 md:inline-flex"
            >
              Ingresar
            </Link>
          )}

          <button
            type="button"
            onClick={() => setIsMenuOpen((current) => !current)}
            aria-label={isMenuOpen ? 'Cerrar menú' : 'Abrir menú'}
            aria-expanded={isMenuOpen}
            className="flex h-9 w-9 items-center justify-center rounded-full text-text-primary transition-colors duration-300 hover:bg-bg-subtle md:hidden"
          >
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

      {isMenuOpen && (
        <div className="grid gap-2 border-t border-border py-4 md:hidden">
          {renderLinks('rounded-btn px-3 py-2 hover:bg-bg-subtle')}
          {isAuthenticated ? (
            <>
              <Link
                to={accountPath}
                onClick={closeMenu}
                className="flex items-center gap-2 rounded-btn px-3 py-2 font-body text-sm font-semibold text-text-primary no-underline transition-colors duration-300 hover:bg-bg-subtle"
              >
                <LayoutDashboard size={16} />
                Mi panel
              </Link>
              <button
                type="button"
                onClick={() => {
                  closeMenu()
                  void logout()
                }}
                className="flex items-center gap-2 rounded-btn px-3 py-2 text-left font-body text-sm font-semibold text-text-primary transition-colors duration-300 hover:bg-bg-subtle"
              >
                <LogOut size={16} />
                Cerrar sesión
              </button>
            </>
          ) : (
            <Link
              to="/login"
              onClick={closeMenu}
              className="rounded-btn bg-azul-fill px-3 py-2 text-center font-body text-sm font-semibold text-on-azul no-underline transition-colors duration-300 hover:bg-azul-fill/90"
            >
              Ingresar
            </Link>
          )}
        </div>
      )}
    </nav>
  )
}
