import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { CreditCard, FileText, ShoppingBag } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { getOrders } from '@/api/marketplace.api'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { ORDER_STATUS_LABELS, ORDER_TYPE_LABELS, PAYMENT_METHOD_LABELS } from '@/constants/labels'
import { useStartPayment } from '@/hooks/useStartPayment'
import { formatCurrency } from '@/utils'

export default function OrdersPage() {
  const { data: orders = [], isLoading } = useQuery({
    queryKey: ['orders'],
    queryFn: () => getOrders(),
    staleTime: 2 * 60 * 1000,
  })
  const startPayment = useStartPayment()
  // Hora de referencia para los plazos, tomada al abrir la página (el render debe ser puro)
  const [now] = useState(() => Date.now())

  return (
    <div className="min-h-screen pt-16">
      <PageShell eyebrow="Tienda" accent="naranja" title="Mis pedidos" subtitle="Historial de órdenes y estados de compra" />

      <main className="mx-auto max-w-4xl px-6 py-8">
        {isLoading ? (
          <div className="space-y-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-bg-card animate-pulse h-28" />
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
                color: 'bg-bg-subtle text-text-muted',
              }
              const dueAt = order.payment_due_at ? new Date(order.payment_due_at) : null
              const isPending = order.status === 'PENDIENTE'
              // La tarea del servidor cancela la orden unos minutos después; mientras tanto no se puede pagar
              const dueExpired = isPending && dueAt !== null && dueAt.getTime() <= now
              const method = order.payment?.payment_method
              const receiptUrl = order.status === 'PAGADO' ? order.payment?.receipt_url : ''

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
                      <p className="font-display font-extrabold text-naranja text-[20px]">
                        {formatCurrency(order.total_amount)}
                      </p>
                      <div className="flex gap-2 mt-1 justify-end">
                        <span className={`rounded-tag px-2.5 py-0.5 font-body text-[11px] font-medium ${statusInfo.color}`}>
                          {statusInfo.label}
                        </span>
                        <span className="rounded-tag bg-bg-card border border-border px-2.5 py-0.5 font-body text-[11px] text-text-muted">
                          {ORDER_TYPE_LABELS[order.order_type] ?? order.order_type}
                        </span>
                      </div>
                    </div>
                  </div>

                  {isPending && dueAt && (
                    <p className="mt-3 font-body text-[12px] text-text-muted">
                      {dueExpired
                        ? 'El plazo para pagar venció: las obras volvieron al catálogo.'
                        : `Paga antes del ${format(dueAt, "d 'de' MMMM, h:mm a", { locale: es })} o las obras volverán al catálogo.`}
                    </p>
                  )}

                  {(method || receiptUrl) && (
                    <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                      {method && order.status === 'PAGADO' && (
                        <p className="font-body text-[12px] text-text-muted">
                          Pagado con {PAYMENT_METHOD_LABELS[method] ?? method}
                        </p>
                      )}
                      {receiptUrl && (
                        <a
                          href={receiptUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1.5 font-body text-[13px] font-semibold text-azul hover:underline"
                        >
                          <FileText size={14} />
                          Ver comprobante
                        </a>
                      )}
                    </div>
                  )}

                  {isPending && !dueExpired && (
                    <div className="mt-4 flex justify-end">
                      <Button
                        size="sm"
                        className="gap-1.5"
                        disabled={startPayment.isPending}
                        onClick={() => startPayment.mutate(order.id)}
                      >
                        <CreditCard size={14} />
                        {startPayment.isPending && startPayment.variables === order.id
                          ? 'Abriendo pago…'
                          : 'Pagar ahora'}
                      </Button>
                    </div>
                  )}

                  {order.items.length > 0 && (
                    <div className="mt-4 pt-4 border-t border-border">
                      <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-2">
                        {order.items.length} {order.items.length === 1 ? 'obra' : 'obras'}
                      </p>
                      <div className="space-y-1">
                        {order.items.map((item) => (
                          <div key={item.id} className="flex justify-between items-center">
                            <p className="font-body text-text-primary text-sm line-clamp-1">
                              {item.artwork_title ?? 'Obra'}
                            </p>
                            <p className="font-body font-semibold text-text-primary text-sm flex-none ml-4">
                              {formatCurrency(item.price)}
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
