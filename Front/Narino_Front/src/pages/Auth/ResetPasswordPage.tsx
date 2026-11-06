import { useSearchParams, Link } from 'react-router-dom'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { ResetPasswordForm } from '@/components/auth/reset-password-form'

export default function ResetPasswordPage() {
  const [params] = useSearchParams()
  const token = params.get('token') ?? undefined

  return (
    <PageShell
      title="Restablecer contraseña"
      description="Ingresa el token recibido por correo y define una nueva contraseña."
    >
      <Card className="mx-auto max-w-xl">
        <CardHeader>
          <CardTitle>Nueva contraseña</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <ResetPasswordForm initialToken={token} />
          <div className="flex flex-wrap gap-3">
            <Button variant="outline" asChild aria-label="Volver a login">
              <Link to="/login">Volver</Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}

