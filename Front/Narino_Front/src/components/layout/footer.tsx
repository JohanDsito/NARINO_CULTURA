import { Link } from 'react-router-dom'
import { FaFacebookF, FaInstagram, FaTiktok } from 'react-icons/fa'

const socialLinks = [
  {
    href: 'https://www.instagram.com/',
    label: 'Instagram',
    icon: FaInstagram,
  },
  {
    href: 'https://www.facebook.com/',
    label: 'Facebook',
    icon: FaFacebookF,
  },
  {
    href: 'https://www.tiktok.com/',
    label: 'TikTok',
    icon: FaTiktok,
  },
]

export function Footer() {
  return (
    <footer
      className="mt-auto"
      style={{
        background: '#2D1B00',
        borderTop: '1px solid rgba(201,146,26,0.2)',
      }}
    >
      <div className="flex w-full flex-col gap-6 px-6 py-6 md:px-10">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="space-y-1">
            <p className="font-display text-base font-semibold text-oro-light">
              Nariño Cultura
            </p>
            <p className="max-w-md text-sm text-white/70">
              Ecosistema cultural y artístico del departamento de Nariño,
              Colombia.
            </p>
          </div>

          <nav
            className="flex flex-wrap gap-x-4 gap-y-2 text-sm"
            aria-label="Enlaces del sitio"
          >
            <Link to="/artists" className="text-white/70 hover:text-oro-light">
              Artistas
            </Link>
            <Link to="/artworks" className="text-white/70 hover:text-oro-light">
              Obras
            </Link>
            <Link to="/events" className="text-white/70 hover:text-oro-light">
              Eventos
            </Link>
            <Link
              to="/marketplace"
              className="text-white/70 hover:text-oro-light"
            >
              Marketplace
            </Link>
          </nav>
        </div>

        <div className="flex flex-col gap-3 border-t border-white/10 pt-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-white/70">
            Un proyecto de UCC y Corpocarnaval
          </p>

          <div className="flex items-center gap-3">
            {socialLinks.map(({ href, label, icon: Icon }) => (
              <a
                key={label}
                href={href}
                target="_blank"
                rel="noreferrer"
                aria-label={label}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-white/10 text-oro-light transition-colors hover:bg-oro hover:text-[#2D1B00]"
              >
                <Icon size={15} />
              </a>
            ))}
          </div>
        </div>
      </div>
    </footer>
  )
}
