import { Link, useLocation } from 'react-router-dom'
import { CheckCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ROUTES } from '@/constants/routes'

export default function PaymentSuccessPage() {
  const { state } = useLocation() as { state?: { orderId?: string; total?: string } }

  return (
    <div className="min-h-screen bg-bg pt-16 flex items-center justify-center px-6">
      <div className="max-w-md w-full text-center space-y-6">
        <CheckCircle size={64} className="text-selva mx-auto" />
        <h1 className="font-display font-bold text-text-primary text-[32px]">
          ¡Pago exitoso!
        </h1>
        <p className="font-body text-text-muted">
          Tu orden ha sido procesada correctamente. Recibirás una confirmación pronto.
        </p>
        {state?.orderId && (
          <p className="font-mono text-text-muted text-sm">
            Orden: #{state.orderId.slice(0, 8).toUpperCase()}
          </p>
        )}
        <div className="flex flex-col gap-3">
          <Link to={ROUTES.ORDERS}>
            <Button variant="primary" className="w-full">Ver mis pedidos</Button>
          </Link>
          <Link to={ROUTES.ARTWORKS}>
            <Button variant="secondary" className="w-full">Seguir explorando</Button>
          </Link>
        </div>
      </div>
    </div>
  )
}
