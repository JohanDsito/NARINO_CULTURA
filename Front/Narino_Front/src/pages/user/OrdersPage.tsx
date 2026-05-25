import { useQuery } from '@tanstack/react-query'
import { ShoppingBag } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { getOrders } from '@/api/marketplace.api'
import { Card } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { ORDER_STATUS_LABELS } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

const ORDER_TYPE_LABELS: Record<string, string> = {
  COMPRA_DIRECTA: 'Compra directa',
  SUBASTA: 'Subasta',
}

export default function OrdersPage() {
  const { data: orders = [], isLoading } = useQuery({
    queryKey: ['orders'],
    queryFn: getOrders,
    staleTime: 2 * 60 * 1000,
  })

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Mis pedidos" subtitle="Historial de órdenes y estados de compra" />

      <main className="mx-auto max-w-4xl px-6 py-8">
        {isLoading ? (
          <div className="space-y-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-28" />
            ))}
          </div>
        ) : orders.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <ShoppingBag size={40} className="opacity-30" />
            <p className="font-body text-sm">Aún no has realizado ningún pedido.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {orders.map((order) => {
              const statusInfo = ORDER_STATUS_LABELS[order.status] ?? {
                label: order.status,
                color: 'bg-muted text-text-muted',
              }

              return (
                <Card key={order.id} className="p-5">
                  <div className="flex flex-wrap items-start justify-between gap-4">
                    <div>
                      <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">
                        Orden
                      </p>
                      <p className="font-mono text-text-primary text-sm font-semibold">
                        #{order.id.slice(0, 8).toUpperCase()}
                      </p>
                      <p className="font-body text-text-muted text-[12px] mt-0.5">
                        {format(new Date(order.created_at), "d 'de' MMMM yyyy", { locale: es })}
                      </p>
                    </div>

                    <div className="text-right">
                      <p className="font-display font-bold text-oro text-[20px]">
                        {formatPrice(parseFloat(order.total_amount))}
                      </p>
                      <div className="flex gap-2 mt-1 justify-end">
                        <span className={`rounded-tag px-2.5 py-0.5 font-body text-[11px] font-medium ${statusInfo.color}`}>
                          {statusInfo.label}
                        </span>
                        <span className="rounded-tag bg-surface border border-border px-2.5 py-0.5 font-body text-[11px] text-text-muted">
                          {ORDER_TYPE_LABELS[order.order_type] ?? order.order_type}
                        </span>
                      </div>
                    </div>
                  </div>

                  {order.items.length > 0 && (
                    <div className="mt-4 pt-4 border-t border-border">
                      <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-2">
                        {order.items.length} {order.items.length === 1 ? 'obra' : 'obras'}
                      </p>
                      <div className="space-y-1">
                        {order.items.map((item) => (
                          <div key={item.id} className="flex justify-between items-center">
                            <p className="font-body text-text-primary text-sm line-clamp-1">
                              {item.artwork}
                            </p>
                            <p className="font-body font-semibold text-text-primary text-sm flex-none ml-4">
                              {formatPrice(parseFloat(item.price))}
                            </p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </Card>
              )
            })}
          </div>
        )}
      </main>
    </div>
  )
}
