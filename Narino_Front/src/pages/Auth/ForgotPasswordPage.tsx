import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'

export default function ForgotPasswordPage() {
  return (
    <PageShell
      title="Recuperar contraseña"
      description="Solicita un enlace de recuperación si olvidaste tu contraseña."
    >
      <Card className="mx-auto max-w-xl">
        <CardHeader>
          <CardTitle>Recuperación</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            En el siguiente paso se implementa el formulario (RHF + Zod) y el envío a{' '}
            <span className="font-medium">/auth/password-reset/</span>.
          </p>
          <div className="flex flex-wrap gap-3">
            <Button variant="outline" asChild aria-label="Volver a login">
              <a href="/login">Volver</a>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}

