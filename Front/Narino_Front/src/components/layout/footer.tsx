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
    <footer className="nc-glass relative mt-auto border-t border-border">
      {/* Serpentina: el detalle de color del carnaval */}
      <div className="nc-serpentina absolute inset-x-0 top-0 h-[3px]" aria-hidden />
      <div className="flex w-full flex-col gap-6 px-6 py-6 md:px-10">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="space-y-1">
            <p className="font-display text-base font-extrabold text-text-primary">
              Nariño Cultura
            </p>
            <p className="max-w-md text-sm text-text-secondary">
              Ecosistema cultural y artístico del departamento de Nariño,
              Colombia.
            </p>
          </div>

          <nav
            className="flex flex-wrap gap-x-4 gap-y-2 text-sm"
            aria-label="Enlaces del sitio"
          >
            <Link to="/artists" className="text-text-secondary hover:text-azul">
              Artistas
            </Link>
            <Link to="/artworks" className="text-text-secondary hover:text-azul">
              Obras
            </Link>
            <Link to="/events" className="text-text-secondary hover:text-azul">
              Eventos
            </Link>
            <Link
              to="/marketplace"
              className="text-text-secondary hover:text-azul"
            >
              Marketplace
            </Link>
          </nav>
        </div>

        <div className="flex flex-col gap-3 border-t border-border pt-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-text-secondary">
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
                className="flex h-8 w-8 items-center justify-center rounded-full bg-bg-subtle text-text-primary transition-colors hover:bg-azul-fill hover:text-on-azul"
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
