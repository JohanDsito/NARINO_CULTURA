import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { TrendingUp, ShoppingBag, DollarSign } from 'lucide-react'

import { getSales } from '@/api/marketplace.api'
import { PageShell } from '@/components/layout/page-shell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

function formatCOP(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n)
}

export default function ArtistAnalyticsPage() {
  const { data: sales = [], isLoading } = useQuery({
    queryKey: ['artist-sales'],
    queryFn: getSales,
    staleTime: 5 * 60 * 1000,
  })

  const paid = useMemo(() => sales.filter((o) => o.status === 'PAGADO'), [sales])

  const totalRevenue = useMemo(
    () => paid.reduce((acc, o) => acc + parseFloat(o.total_amount), 0),
    [paid],
  )

  const byMonth = useMemo(() => {
    const map = new Map<string, number>()
    for (const order of paid) {
      const key = format(new Date(order.created_at), 'MMM yyyy', { locale: es })
      map.set(key, (map.get(key) ?? 0) + parseFloat(order.total_amount))
    }
    return Array.from(map.entries())
      .slice(-6)
      .map(([month, total]) => ({ month, total }))
  }, [paid])

  const recentSales = useMemo(() => [...sales].reverse().slice(0, 10), [sales])

  if (isLoading) {
    return (
      <div className="min-h-screen bg-bg pt-16">
        <PageShell title="Analíticas" subtitle="Resumen de ventas y rendimiento" />
        <main className="mx-auto max-w-5xl px-6 py-8 space-y-6">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-32" />
          ))}
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Analíticas" subtitle="Resumen de ventas y rendimiento" />

      <main className="mx-auto max-w-5xl px-6 py-8 space-y-6">
        {/* KPI cards */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <Card>
            <CardContent className="flex items-center gap-4 p-5">
              <div className="rounded-full bg-oro/10 p-3 text-oro">
                <DollarSign size={20} />
              </div>
              <div>
                <p className="font-body text-[11px] uppercase tracking-widest text-text-muted">
                  Ingresos totales
                </p>
                <p className="font-display text-2xl font-semibold text-text-primary">
                  {formatCOP(totalRevenue)}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="flex items-center gap-4 p-5">
              <div className="rounded-full bg-selva/10 p-3 text-selva">
                <ShoppingBag size={20} />
              </div>
              <div>
                <p className="font-body text-[11px] uppercase tracking-widest text-text-muted">
                  Ventas completadas
                </p>
                <p className="font-display text-2xl font-semibold text-text-primary">
                  {paid.length}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="flex items-center gap-4 p-5">
              <div className="rounded-full bg-tierra/10 p-3 text-tierra">
                <TrendingUp size={20} />
              </div>
              <div>
                <p className="font-body text-[11px] uppercase tracking-widest text-text-muted">
                  Promedio por venta
                </p>
                <p className="font-display text-2xl font-semibold text-text-primary">
                  {paid.length > 0 ? formatCOP(totalRevenue / paid.length) : '—'}
                </p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Revenue chart */}
        <Card>
          <CardHeader>
            <CardTitle className="font-body text-base text-text-primary">
              Ingresos por mes (últimos 6 meses)
            </CardTitle>
          </CardHeader>
          <CardContent>
            {byMonth.length === 0 ? (
              <p className="py-8 text-center font-body text-sm text-text-muted">
                No hay datos suficientes para mostrar el gráfico.
              </p>
            ) : (
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={byMonth} margin={{ top: 4, right: 8, left: 8, bottom: 4 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
                  <XAxis
                    dataKey="month"
                    tick={{ fontSize: 11, fill: 'var(--color-text-muted)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    tickFormatter={(v: number) =>
                      v >= 1_000_000 ? `${(v / 1_000_000).toFixed(1)}M` : `${(v / 1_000).toFixed(0)}K`
                    }
                    tick={{ fontSize: 11, fill: 'var(--color-text-muted)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    formatter={(value: number) => [formatCOP(value), 'Ingresos']}
                    contentStyle={{
                      background: 'var(--color-surface)',
                      border: '1px solid var(--color-border)',
                      borderRadius: '8px',
                      fontSize: '12px',
                    }}
                  />
                  <Bar dataKey="total" fill="var(--color-oro)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Recent sales table */}
        <Card>
          <CardHeader>
            <CardTitle className="font-body text-base text-text-primary">Ventas recientes</CardTitle>
          </CardHeader>
          <CardContent>
            {sales.length === 0 ? (
              <p className="py-6 text-center font-body text-sm text-text-muted">
                Aún no tienes ventas registradas.
              </p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="border-b border-border">
                    <tr>
                      {['Orden', 'Tipo', 'Total', 'Estado', 'Fecha'].map((h) => (
                        <th
                          key={h}
                          className="pb-2 font-body text-[11px] uppercase tracking-widest text-text-muted"
                        >
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {recentSales.map((order) => (
                      <tr key={order.id}>
                        <td className="py-3 font-mono text-sm text-text-primary">
                          #{order.id.slice(0, 8).toUpperCase()}
                        </td>
                        <td className="py-3 font-body text-sm text-text-muted">
                          {order.order_type === 'COMPRA_DIRECTA' ? 'Directa' : 'Subasta'}
                        </td>
                        <td className="py-3 font-body font-semibold text-oro text-sm">
                          {formatCOP(parseFloat(order.total_amount))}
                        </td>
                        <td className="py-3">
                          <span
                            className={`rounded-tag px-2 py-0.5 font-body text-[11px] font-medium ${
                              order.status === 'PAGADO'
                                ? 'bg-selva/10 text-selva'
                                : order.status === 'CANCELADO' || order.status === 'REEMBOLSADO'
                                ? 'bg-error/10 text-error'
                                : 'bg-tierra/10 text-tierra'
                            }`}
                          >
                            {order.status}
                          </span>
                        </td>
                        <td className="py-3 font-body text-sm text-text-muted">
                          {format(new Date(order.created_at), 'd MMM yyyy', { locale: es })}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
