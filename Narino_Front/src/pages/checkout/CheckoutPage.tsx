import { useQuery, useMutation } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { ShoppingCart, CreditCard } from 'lucide-react'
import { toast } from 'sonner'
import { getServerCart, checkout } from '@/api/marketplace.api'
import { Button } from '@/components/ui/button'
import { PageShell } from '@/components/layout/page-shell'
import { ROUTES } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

export default function CheckoutPage() {
  const navigate = useNavigate()

  const { data: cart, isLoading } = useQuery({
    queryKey: ['server-cart'],
    queryFn: getServerCart,
    staleTime: 30 * 1000,
  })

  const checkoutMutation = useMutation({
    mutationFn: () => checkout('COMPRA_DIRECTA'),
    onSuccess: (data) => {
      toast.success(`Orden #${data.order_id.slice(0, 8).toUpperCase()} creada`)
      navigate(ROUTES.PAYMENT_SUCCESS, { state: { orderId: data.order_id, total: data.total_amount } })
    },
    onError: () => {
      toast.error('No se pudo procesar la orden. Intenta de nuevo.')
    },
  })

  const items = cart?.items ?? []
  const total = items.reduce(
    (acc, item) => acc + parseFloat(item.artwork_price ?? '0'),
    0,
  )

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Checkout" subtitle="Revisa tu orden antes de confirmar" />

      <main className="mx-auto max-w-3xl px-6 py-8">
        {isLoading ? (
          <div className="space-y-4">
            {Array.from({ length: 2 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-20" />
            ))}
          </div>
        ) : items.length === 0 ? (
          <div className="flex flex-col items-center gap-4 py-24 text-text-muted">
            <ShoppingCart size={48} className="opacity-30" />
            <p className="font-body text-sm">Tu carrito está vacío.</p>
            <Button variant="primary" onClick={() => navigate(ROUTES.ARTWORKS)}>
              Explorar obras
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Items */}
            <div className="lg:col-span-2 space-y-3">
              <h2 className="font-display font-bold text-text-primary text-[18px] mb-4">
                Obras en tu carrito ({items.length})
              </h2>
              {items.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center gap-4 rounded-card border border-border bg-surface p-4"
                >
                  {item.artwork_main_image_url && (
                    <img
                      src={item.artwork_main_image_url}
                      alt=""
                      className="w-16 h-16 rounded-md object-cover flex-none"
                    />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-body font-semibold text-text-primary text-sm line-clamp-1">
                      {item.artwork_title ?? item.artwork}
                    </p>
                  </div>
                  <p className="font-body font-bold text-oro flex-none">
                    {formatPrice(parseFloat(item.artwork_price ?? '0'))}
                  </p>
                </div>
              ))}
            </div>

            {/* Resumen */}
            <div className="rounded-card border border-border bg-surface p-6 h-fit space-y-4">
              <h3 className="font-display font-bold text-text-primary text-[16px]">Resumen</h3>
              <div className="flex justify-between items-center py-3 border-t border-border">
                <span className="font-body text-text-muted text-sm">Total</span>
                <span className="font-display font-bold text-oro text-[22px]">
                  {formatPrice(total)}
                </span>
              </div>
              <Button
                variant="primary"
                className="w-full gap-2"
                onClick={() => checkoutMutation.mutate()}
                disabled={checkoutMutation.isPending}
              >
                <CreditCard size={18} />
                {checkoutMutation.isPending ? 'Procesando…' : 'Confirmar compra'}
              </Button>
              <p className="font-body text-[11px] text-text-muted text-center">
                Al confirmar, aceptas los términos de la plataforma.
              </p>
            </div>
          </div>
        )}
      </main>
    </div>
  )
}
