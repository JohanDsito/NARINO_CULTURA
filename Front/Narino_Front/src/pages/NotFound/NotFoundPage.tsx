import { Link } from 'react-router-dom'

import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'

export default function NotFoundPage() {
  return (
    <PageShell
      title="Página no encontrada"
      description="La ruta que intentas abrir no existe o fue movida."
    >
      <div className="space-y-4">
        <p className="text-sm text-muted-foreground">
          Revisa la URL o vuelve al inicio para continuar explorando Nariño Cultura.
        </p>
        <div className="flex flex-wrap gap-3">
          <Button asChild aria-label="Ir al inicio">
            <Link to="/">Ir al inicio</Link>
          </Button>
          <Button variant="outline" asChild aria-label="Ir a login">
            <Link to="/login">Iniciar sesión</Link>
          </Button>
        </div>
      </div>
    </PageShell>
  )
}

