import { Link } from 'react-router-dom'

import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'

export default function UnderConstructionPage({
  title,
  description,
}: {
  title: string
  description?: string
}) {
  return (
    <PageShell title={title} description={description ?? 'Esta sección se está construyendo.'}>
      <Card>
        <CardContent className="space-y-4 pt-6">
          <p className="text-sm text-muted-foreground">
            El flujo de autenticación y la base de arquitectura ya están listos. En los siguientes
            pasos se implementa esta sección con datos reales del backend.
          </p>
          <div className="flex flex-wrap gap-3">
            <Button asChild aria-label="Volver al inicio">
              <Link to="/">Ir al inicio</Link>
            </Button>
            <Button variant="outline" asChild aria-label="Explorar obras">
              <Link to="/artworks">Explorar obras</Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}

