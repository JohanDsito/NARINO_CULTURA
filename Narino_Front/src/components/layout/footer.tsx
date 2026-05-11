import { Link } from 'react-router-dom'

export function Footer() {
  return (
    <footer className="mt-auto border-t bg-background">
      <div className="mx-auto flex max-w-5xl flex-col gap-3 px-4 py-8 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-1">
          <p className="font-display text-base font-semibold text-primary">Nariño Cultura</p>
          <p className="text-sm text-muted-foreground">
            Ecosistema cultural y artístico del departamento de Nariño, Colombia.
          </p>
        </div>
        <nav className="flex flex-wrap gap-x-4 gap-y-2 text-sm" aria-label="Enlaces del sitio">
          <Link to="/artists" className="text-muted-foreground hover:text-foreground">
            Artistas
          </Link>
          <Link to="/artworks" className="text-muted-foreground hover:text-foreground">
            Obras
          </Link>
          <Link to="/events" className="text-muted-foreground hover:text-foreground">
            Eventos
          </Link>
          <Link to="/marketplace" className="text-muted-foreground hover:text-foreground">
            Marketplace
          </Link>
        </nav>
      </div>
    </footer>
  )
}

