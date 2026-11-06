import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'

import { verifyEmail } from '@/api/auth.api'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { getApiErrorMessage } from '@/utils/apiError'

type VerificationStatus = 'loading' | 'success' | 'error'

export default function VerifyEmailPage() {
  const [params] = useSearchParams()
  const token = params.get('token')

  const [status, setStatus] = useState<VerificationStatus>(() => {
    return token ? 'loading' : 'error'
  })
  const [message, setMessage] = useState(() => {
    return token
      ? 'Validando tu token de verificación...'
      : 'No se encontró el token de verificación en el enlace.'
  })

  useEffect(() => {
    if (!token) return

    let mounted = true

    void verifyEmail(token)
      .then((data) => {
        if (!mounted) return
        setStatus('success')
        setMessage(data.message)
      })
      .catch((error: unknown) => {
        if (!mounted) return
        setStatus('error')
        setMessage(getApiErrorMessage(error))
      })

    return () => {
      mounted = false
    }
  }, [token])

  const title =
    status === 'loading'
      ? 'Verificando correo'
      : status === 'success'
        ? 'Correo verificado'
        : 'No fue posible verificar el correo'

  return (
    <PageShell
      title={title}
      description="Confirma tu cuenta para poder iniciar sesión en Nariño Cultura."
    >
      <Card className="mx-auto max-w-xl">
        <CardHeader>
          <CardTitle>{title}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">{message}</p>
          <div className="flex flex-wrap gap-3">
            <Button asChild aria-label="Ir a iniciar sesión">
              <Link to="/login">Ir a iniciar sesión</Link>
            </Button>
            <Button variant="outline" asChild aria-label="Volver al inicio">
              <Link to="/">Volver al inicio</Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </PageShell>
  )
}
