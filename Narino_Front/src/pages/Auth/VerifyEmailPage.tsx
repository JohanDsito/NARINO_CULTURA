import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'

import { verifyEmail } from '@/api/auth.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { getApiErrorMessage } from '@/utils/apiError'

type VerificationStatus = 'loading' | 'success' | 'error'

export default function VerifyEmailPage() {
  const [params] = useSearchParams()
  const [status, setStatus] = useState<VerificationStatus>('loading')
  const [message, setMessage] = useState('Validando tu token de verificación...')
  const token = params.get('token')

  useEffect(() => {
    if (!token) {
      setStatus('error')
      setMessage('No se encontró el token de verificación en el enlace.')
      return
    }

    let mounted = true

    void verifyEmail(token)
      .then((data) => {
        if (!mounted) return
        setStatus('success')
        setMessage(data.message)
      })
      .catch((error) => {
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
