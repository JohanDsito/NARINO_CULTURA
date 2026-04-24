import { Link } from 'react-router-dom'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { ForgotPasswordForm } from '@/components/auth/forgot-password-form'

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
          <ForgotPasswordForm />
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
