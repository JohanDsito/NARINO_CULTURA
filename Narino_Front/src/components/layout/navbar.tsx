import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import {
  Bell,
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
import { useTheme } from '@/hooks/useTheme'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'

const links = [
  { to: '/artists', label: 'Artistas' },
  { to: '/artworks', label: 'Obras' },
  { to: '/marketplace', label: 'Marketplace' },
  { to: '/auctions', label: 'Subastas' },
  { to: '/events', label: 'Eventos' },
]

export function Navbar() {
  const { theme, toggle } = useTheme()
  const { pathname } = useLocation()
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const cartCount = useCartStore((s) => s.items.length)
  const user = useAuthStore((s) => s.user)
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const logout = useLogout()

  const accountPath =
    user?.role === 'admin'
      ? '/admin/dashboard'
      : user?.role === 'artist'
        ? '/dashboard/profile'
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
            isActive ? 'text-oro-light' : 'text-[#f5efe5bf] hover:text-oro-light'
          } ${className}`}
        >
          {label}
        </Link>
      )
    })

  return (
    <nav className="fixed inset-x-0 top-0 z-50 border-b border-oro/20 bg-[#2D1B00] px-4 md:px-10">
      <div className="flex h-16 items-center justify-between gap-4">
        <Link to="/" className="flex items-center gap-2 no-underline" onClick={closeMenu}>
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-oro">
            <Mountain size={16} className="text-[#2D1B00]" />
          </div>
          <span className="font-display text-lg font-bold tracking-wide text-oro-light">
            Nariño Cultura
          </span>
        </Link>

        <div className="hidden items-center gap-7 md:flex">{renderLinks('')}</div>

        <div className="flex items-center gap-2 md:gap-4">
          <Link
            to="/checkout"
            aria-label={`Carrito de compras${cartCount > 0 ? `, ${cartCount} productos` : ''}`}
            className="relative inline-flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-white/10"
          >
            <ShoppingCart size={20} className="text-[#f5efe5bf]" />
            {cartCount > 0 && (
              <span className="absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-tierra px-1 text-[10px] font-bold text-white">
                {cartCount}
              </span>
            )}
          </Link>

          <Link
            to="/notifications"
            aria-label="Notificaciones"
            className="inline-flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-white/10"
          >
            <Bell size={20} className="text-[#f5efe5bf]" />
          </Link>

          <button
            type="button"
            onClick={toggle}
            aria-label="Cambiar modo de color"
            className="flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-white/10"
          >
            {theme === 'light' ? (
              <Moon size={18} className="text-oro-light" />
            ) : (
              <Sun size={18} className="text-oro-light" />
            )}
          </button>

          {isAuthenticated ? (
            <>
              <Link
                to={accountPath}
                className="hidden items-center gap-2 rounded-btn bg-tierra px-4 py-2 font-body text-[13px] font-semibold text-white no-underline transition-all duration-300 hover:-translate-y-px hover:bg-tierra-light md:inline-flex"
              >
                <LayoutDashboard size={15} />
                Mi panel
              </Link>
              <button
                type="button"
                onClick={() => void logout()}
                aria-label="Cerrar sesión"
                className="hidden h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-white/10 md:inline-flex"
              >
                <LogOut size={18} className="text-[#f5efe5bf]" />
              </button>
            </>
          ) : (
            <Link
              to="/login"
              className="hidden rounded-btn bg-tierra px-4 py-2 font-body text-[13px] font-semibold text-white no-underline transition-all duration-300 hover:-translate-y-px hover:bg-tierra-light md:inline-flex"
            >
              Ingresar
            </Link>
          )}

          <button
            type="button"
            onClick={() => setIsMenuOpen((current) => !current)}
            aria-label={isMenuOpen ? 'Cerrar menú' : 'Abrir menú'}
            aria-expanded={isMenuOpen}
            className="flex h-9 w-9 items-center justify-center rounded-full text-oro-light transition-colors duration-300 hover:bg-white/10 md:hidden"
          >
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

      {isMenuOpen && (
        <div className="grid gap-2 border-t border-oro/20 py-4 md:hidden">
          {renderLinks('rounded-btn px-3 py-2 hover:bg-white/10')}
          {isAuthenticated ? (
            <>
              <Link
                to={accountPath}
                onClick={closeMenu}
                className="flex items-center gap-2 rounded-btn px-3 py-2 font-body text-sm font-semibold text-white no-underline transition-colors duration-300 hover:bg-white/10"
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
                className="flex items-center gap-2 rounded-btn px-3 py-2 text-left font-body text-sm font-semibold text-white transition-colors duration-300 hover:bg-white/10"
              >
                <LogOut size={16} />
                Cerrar sesión
              </button>
            </>
          ) : (
            <Link
              to="/login"
              onClick={closeMenu}
              className="rounded-btn bg-tierra px-3 py-2 text-center font-body text-sm font-semibold text-white no-underline transition-colors duration-300 hover:bg-tierra-light"
            >
              Ingresar
            </Link>
          )}
        </div>
      )}
    </nav>
  )
}
