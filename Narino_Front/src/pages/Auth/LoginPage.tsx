import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'

export default function LoginPage() {
  return (
    <PageShell
      title="Iniciar sesión"
      description="Accede con tu cuenta para comprar, publicar obras, gestionar eventos o administrar la plataforma."
    >
      <Card className="mx-auto max-w-xl">
        <CardHeader>
          <CardTitle>Autenticación</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            En el siguiente paso se implementa el formulario con React Hook Form + Zod, manejo de JWT
            y redirección por rol.
          </p>
          <div className="flex flex-wrap gap-3">
            <Button asChild aria-label="Ir a registro">
              <a href="/register">Crear cuenta</a>
            </Button>
            <Button variant="outline" asChild aria-label="Recuperar contraseña">
              <a href="/forgot-password">Olvidé mi contraseña</a>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}

