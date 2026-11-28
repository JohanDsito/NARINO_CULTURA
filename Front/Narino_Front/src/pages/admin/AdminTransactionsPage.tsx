import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Receipt } from 'lucide-react'
import { getAdminTransactions } from '@/api/admin.api'
import { PageShell } from '@/components/layout/page-shell'
import { TRANSACTION_STATUS_LABELS } from '@/constants/labels'
import { formatCurrency } from '@/utils'

export default function AdminTransactionsPage() {
  const { data: transactions = [], isLoading } = useQuery({
    queryKey: ['admin-transactions'],
    queryFn: () => getAdminTransactions(),
    staleTime: 60 * 1000,
  })

  return (
    <div className="min-h-screen pt-16">
      <PageShell title="Transacciones" subtitle="Auditoría de los pagos de la plataforma" />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-bg-card animate-pulse h-16" />
            ))}
          </div>
        ) : transactions.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Receipt size={40} className="opacity-30" />
            <p className="font-body text-sm">No hay transacciones registradas.</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-card border border-border">
            <table className="w-full text-left">
              <thead className="border-b border-border bg-bg-card">
                <tr>
                  {['Orden', 'Comprador', 'Tipo', 'Monto', 'Pago', 'Fecha'].map((h) => (
                    <th key={h} className="px-4 py-3 font-body text-[11px] uppercase tracking-widest text-text-muted">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {transactions.map((tx) => {
                  const statusInfo = TRANSACTION_STATUS_LABELS[tx.status] ?? { label: tx.status, color: '' }
                  return (
                    <tr key={tx.id} className="hover:bg-bg-card/50 transition-colors">
                      <td className="px-4 py-3 font-mono text-text-primary text-sm">
                        #{tx.order_id.slice(0, 8).toUpperCase()}
                      </td>
                      <td className="px-4 py-3 font-body text-text-secondary text-sm">{tx.buyer_email}</td>
                      <td className="px-4 py-3 font-body text-text-muted text-sm">
                        {tx.order_type === 'COMPRA_DIRECTA' ? 'Directa' : 'Subasta'}
                      </td>
                      <td className="px-4 py-3 font-body font-semibold text-oro text-sm">
                        {formatCurrency(parseFloat(tx.amount))}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`rounded-tag px-2.5 py-0.5 font-body text-[11px] font-medium ${statusInfo.color}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="px-4 py-3 font-body text-text-muted text-sm">
                        {tx.created_at
                          ? format(new Date(tx.created_at), 'd MMM yyyy', { locale: es })
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
