import { Link } from 'react-router-dom'
import { XCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ROUTES } from '@/constants/routes'

export default function PaymentDeclinedPage() {
  return (
    <div className="min-h-screen bg-bg pt-16 flex items-center justify-center px-6">
      <div className="max-w-md w-full text-center space-y-6">
        <XCircle size={64} className="text-error mx-auto" />
        <h1 className="font-display font-bold text-text-primary text-[32px]">
          Pago rechazado
        </h1>
        <p className="font-body text-text-muted">
          Tu transacción no fue aprobada. Verifica los datos de tu método de pago e intenta de nuevo.
        </p>
        <div className="flex flex-col gap-3">
          <Link to={ROUTES.CHECKOUT}>
            <Button variant="primary" className="w-full">Intentar de nuevo</Button>
          </Link>
          <Link to={ROUTES.ARTWORKS}>
            <Button variant="secondary" className="w-full">Volver al catálogo</Button>
          </Link>
        </div>
      </div>
    </div>
  )
}
