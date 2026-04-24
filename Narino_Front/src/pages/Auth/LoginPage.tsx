import { Link } from 'react-router-dom'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { LoginForm } from '@/components/auth/login-form'

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
          <LoginForm />
          <div className="flex flex-wrap gap-3">
            <Button asChild aria-label="Ir a registro">
              <Link to="/register">Crear cuenta</Link>
            </Button>
            <Button variant="outline" asChild aria-label="Recuperar contraseña">
              <Link to="/forgot-password">Olvidé mi contraseña</Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}
