import { Link } from 'react-router-dom'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { RegisterForm } from '@/components/auth/register-form'

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
          <RegisterForm />
          <div className="flex flex-wrap gap-3">
            <Button asChild aria-label="Ir a login">
              <Link to="/login">Ya tengo cuenta</Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}
