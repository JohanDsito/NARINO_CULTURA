import { Link, useLocation } from 'react-router-dom'
import { LayoutDashboard, LogOut, Sun, Moon, ShoppingCart, Bell, Mountain } from 'lucide-react'
import { useTheme } from '@/hooks/useTheme'
import { useCartStore } from '@/store/cartStore'
import { useAuthStore } from '@/store/authStore'
import { useLogout } from '@/hooks/useAuth'

const links = [
  { to: '/artists',     label: 'Artistas' },
  { to: '/artworks',    label: 'Obras' },
  { to: '/marketplace', label: 'Marketplace' },
  { to: '/auctions',    label: 'Subastas' },
  { to: '/events',      label: 'Eventos' },
]

export function Navbar() {
  const { theme, toggle } = useTheme()
  const { pathname } = useLocation()
  const cartCount = useCartStore(s => s.items.length)
  const user = useAuthStore(s => s.user)
  const isAuthenticated = useAuthStore(s => s.isAuthenticated)
  const logout = useLogout()

  const accountPath =
    user?.role === 'admin'
      ? '/admin/dashboard'
      : user?.role === 'artist'
        ? '/dashboard/profile'
        : user?.role === 'cultural_manager'
          ? '/events'
          : '/marketplace'

  return (
    <nav
      className="fixed top-0 inset-x-0 z-50 flex items-center justify-between
                 px-6 md:px-10 h-16"
      style={{
        background: '#2D1B00',
        borderBottom: '1px solid rgba(201,146,26,0.2)',
      }}
    >
      {/* Logo */}
      <Link to="/" className="flex items-center gap-2 no-underline">
        <div className="w-8 h-8 rounded-lg bg-oro flex items-center justify-center">
          <Mountain size={16} color="#2D1B00" />
        </div>
        <span className="font-display font-bold text-[18px] text-oro-light tracking-wide">
          Nariño Cultura
        </span>
      </Link>

      {/* Links */}
      <ul className="hidden md:flex items-center gap-7 list-none">
        {links.map(({ to, label }) => (
          <li key={to}>
            <Link
              to={to}
              className="font-body font-medium text-[14px] no-underline transition-colors duration-300"
              style={{
                color: pathname.startsWith(to)
                  ? '#F0C060'
                  : 'rgba(245,239,229,0.75)',
              }}
            >
              {label}
            </Link>
          </li>
        ))}
      </ul>

      {/* Acciones */}
      <div className="flex items-center gap-4">
        {/* Carrito */}
        <Link to="/checkout" className="relative">
          <ShoppingCart size={20} color="rgba(245,239,229,0.75)" />
          {cartCount > 0 && (
            <span className="absolute -top-1.5 -right-1.5 w-4 h-4 rounded-full
                             bg-tierra text-white text-[10px] font-bold
                             flex items-center justify-center">
              {cartCount}
            </span>
          )}
        </Link>

        {/* Notificaciones */}
        <Link to="/notifications">
          <Bell size={20} color="rgba(245,239,229,0.75)" />
        </Link>

        {/* Toggle dark mode */}
        <button
          onClick={toggle}
          aria-label="Cambiar modo de color"
          className="w-8 h-8 rounded-full flex items-center justify-center
                     transition-colors duration-300 hover:bg-white/10"
        >
          {theme === 'light'
            ? <Moon size={18} color="#F0C060" />
            : <Sun  size={18} color="#F0C060" />
          }
        </button>

        {isAuthenticated ? (
          <>
            <Link
              to={accountPath}
              className="hidden md:inline-flex items-center gap-2 font-body font-semibold text-[13px]
                         bg-tierra text-white px-4 py-2 rounded-btn no-underline
                         transition-all duration-300 hover:bg-tierra-light hover:-translate-y-px"
            >
              <LayoutDashboard size={15} />
              Mi panel
            </Link>
            <button
              type="button"
              onClick={() => void logout()}
              aria-label="Cerrar sesión"
              className="hidden md:inline-flex h-9 w-9 items-center justify-center rounded-full transition-colors duration-300 hover:bg-white/10"
            >
              <LogOut size={18} color="rgba(245,239,229,0.75)" />
            </button>
          </>
        ) : (
          <Link
            to="/login"
            className="hidden md:inline-flex font-body font-semibold text-[13px]
                       bg-tierra text-white px-4 py-2 rounded-btn no-underline
                       transition-all duration-300 hover:bg-tierra-light hover:-translate-y-px"
          >
            Ingresar
          </Link>
        )}
      </div>
    </nav>
  )
}
