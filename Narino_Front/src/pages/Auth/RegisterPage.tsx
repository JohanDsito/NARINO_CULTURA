import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'

export default function RegisterPage() {
  return (
    <PageShell
      title="Crear cuenta"
      description="Regístrate como artista, comprador, gestor cultural o administrador (según permisos)."
    >
      <Card className="mx-auto max-w-xl">
        <CardHeader>
          <CardTitle>Registro</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            En el siguiente paso se implementa el formulario con validación tipada (Zod), selección
            de tipo de usuario y mensaje de verificación por correo.
          </p>
          <div className="flex flex-wrap gap-3">
            <Button asChild aria-label="Ir a login">
              <a href="/login">Ya tengo cuenta</a>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}

