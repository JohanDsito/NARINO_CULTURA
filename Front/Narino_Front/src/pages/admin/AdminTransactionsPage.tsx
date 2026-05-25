import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Receipt } from 'lucide-react'
import { getAdminTransactions } from '@/api/admin.api'
import { PageShell } from '@/components/layout/page-shell'
import { ORDER_STATUS_LABELS } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

export default function AdminTransactionsPage() {
  const { data: orders = [], isLoading } = useQuery({
    queryKey: ['admin-transactions'],
    queryFn: getAdminTransactions,
    staleTime: 60 * 1000,
  })

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Transacciones" subtitle="Auditoría de todas las órdenes de la plataforma" />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-16" />
            ))}
          </div>
        ) : orders.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Receipt size={40} className="opacity-30" />
            <p className="font-body text-sm">No hay transacciones registradas.</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-card border border-border">
            <table className="w-full text-left">
              <thead className="border-b border-border bg-surface">
                <tr>
                  {['Orden', 'Tipo', 'Total', 'Estado', 'Fecha'].map((h) => (
                    <th key={h} className="px-4 py-3 font-body text-[11px] uppercase tracking-widest text-text-muted">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {orders.map((order) => {
                  const statusInfo = ORDER_STATUS_LABELS[order.status] ?? { label: order.status, color: '' }
                  return (
                    <tr key={order.id} className="hover:bg-surface/50 transition-colors">
                      <td className="px-4 py-3 font-mono text-text-primary text-sm">
                        #{order.id.slice(0, 8).toUpperCase()}
                      </td>
                      <td className="px-4 py-3 font-body text-text-muted text-sm">
                        {order.order_type === 'COMPRA_DIRECTA' ? 'Directa' : 'Subasta'}
                      </td>
                      <td className="px-4 py-3 font-body font-semibold text-oro text-sm">
                        {formatPrice(parseFloat(order.total_amount))}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`rounded-tag px-2.5 py-0.5 font-body text-[11px] font-medium ${statusInfo.color}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="px-4 py-3 font-body text-text-muted text-sm">
                        {order.created_at
                          ? format(new Date(order.created_at), 'd MMM yyyy', { locale: es })
                          : '—'}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  )
}
