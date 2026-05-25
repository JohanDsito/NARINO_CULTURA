import { Link } from 'react-router-dom'
import { Clock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ROUTES } from '@/constants/routes'

export default function PaymentPendingPage() {
  return (
    <div className="min-h-screen bg-bg pt-16 flex items-center justify-center px-6">
      <div className="max-w-md w-full text-center space-y-6">
        <Clock size={64} className="text-oro mx-auto" />
        <h1 className="font-display font-bold text-text-primary text-[32px]">
          Pago en proceso
        </h1>
        <p className="font-body text-text-muted">
          Tu transacción está siendo verificada. Esto puede tomar unos minutos.
          Te notificaremos cuando se confirme.
        </p>
        <div className="flex flex-col gap-3">
          <Link to={ROUTES.ORDERS}>
            <Button variant="primary" className="w-full">Revisar mis pedidos</Button>
          </Link>
          <Link to={ROUTES.HOME}>
            <Button variant="secondary" className="w-full">Volver al inicio</Button>
          </Link>
        </div>
      </div>
    </div>
  )
}
