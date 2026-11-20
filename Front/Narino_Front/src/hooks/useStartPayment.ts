import { useMutation } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'

import { buildWompiCheckoutUrl, initiatePayment } from '@/api/payments.api'
import { ROUTES } from '@/constants/routes'
import { getApiErrorMessage } from '@/utils/apiError'

/**
 * Inicia el pago de una orden PENDIENTE y redirige al Web Checkout de Wompi.
 * Wompi vuelve a `/payment/pending`; el estado final llega por webhook.
 */
export function useStartPayment() {
  const navigate = useNavigate()

  return useMutation({
    mutationFn: (orderId: string) => initiatePayment(orderId),
    onSuccess: (payment, orderId) => {
      const redirectUrl = `${window.location.origin}${ROUTES.PAYMENT_PENDING}`
      const url = buildWompiCheckoutUrl(payment, redirectUrl)
      if (!url) {
        toast.error('La pasarela de pago no está configurada. Intenta más tarde.')
        navigate(ROUTES.ORDERS, { state: { orderId } })
        return
      }
      window.location.assign(url)
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })
}
