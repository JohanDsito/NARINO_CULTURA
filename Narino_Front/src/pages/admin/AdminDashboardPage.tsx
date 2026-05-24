import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import {
  AlertCircle,
  CalendarClock,
  CheckCircle2,
  Image,
  Receipt,
  RefreshCw,
  ShoppingBag,
  Users,
  Gavel,
  TrendingUp,
  ArrowRight,
} from 'lucide-react'

import {
  getAdminMetrics,
  getPendingArtworks,
  getPendingEvents,
  getAdminTransactions,
} from '@/api/admin.api'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ORDER_STATUS_LABELS } from '@/constants/routes'

const REFETCH_INTERVAL = 30_000

function formatCOP(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n)
}

function StatCard({
  icon: Icon,
  label,
  value,
  sub,
  color,
  href,
}: {
  icon: typeof Users
  label: string
  value: number | string
  sub?: string
  color: string
  href?: string
}) {
  const content = (
    <Card className="relative overflow-hidden transition-shadow hover:shadow-md">
      <CardContent className="flex items-center gap-4 p-5">
        <div
          className={`flex h-12 w-12 flex-none items-center justify-center rounded-xl ${color}`}
        >
          <Icon size={22} className="text-white" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-xs font-medium text-muted-foreground">{label}</p>
          <p className="text-2xl font-bold leading-tight text-foreground">{value}</p>
          {sub && <p className="text-[11px] text-muted-foreground">{sub}</p>}
        </div>
        {href && <ArrowRight size={16} className="flex-none text-muted-foreground" />}
      </CardContent>
    </Card>
  )
  return href ? <Link to={href}>{content}</Link> : content
}

export default function AdminDashboardPage() {
  const metricsQuery = useQuery({
    queryKey: ['admin-metrics'],
    queryFn: getAdminMetrics,
    staleTime: 0,
    refetchInterval: REFETCH_INTERVAL,
  })

  const pendingArtworksQuery = useQuery({
    queryKey: ['admin-pending-artworks'],
    queryFn: getPendingArtworks,
    staleTime: 0,
    refetchInterval: REFETCH_INTERVAL,
  })

  const pendingEventsQuery = useQuery({
    queryKey: ['admin-pending-events'],
    queryFn: getPendingEvents,
    staleTime: 0,
    refetchInterval: REFETCH_INTERVAL,
  })

  const transactionsQuery = useQuery({
    queryKey: ['admin-transactions'],
    queryFn: getAdminTransactions,
    staleTime: 0,
    refetchInterval: REFETCH_INTERVAL,
  })

  const m = metricsQuery.data
  const pendingArtworks = pendingArtworksQuery.data ?? []
  const pendingEvents = pendingEventsQuery.data ?? []
  const transactions = (transactionsQuery.data ?? []).slice(0, 6)

  const totalPending = pendingArtworks.length + pendingEvents.length
  const isRefetching =
    metricsQuery.isFetching ||
    pendingArtworksQuery.isFetching ||
    pendingEventsQuery.isFetching ||
    transactionsQuery.isFetching

  const refetchAll = () => {
    void metricsQuery.refetch()
    void pendingArtworksQuery.refetch()
    void pendingEventsQuery.refetch()
    void transactionsQuery.refetch()
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-7xl flex-col gap-8 px-6 py-8 md:px-10">

        {/* Header */}
        <section className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Sistema</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Panel de Administración
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Control y supervisión de la plataforma en tiempo real
            </p>
          </div>
          <Button
            variant="outline"
            size="sm"
            className="gap-2 self-start sm:self-auto"
            onClick={refetchAll}
            disabled={isRefetching}
          >
            <RefreshCw size={14} className={isRefetching ? 'animate-spin' : ''} />
            Actualizar
          </Button>
        </section>

        {/* Stats */}
        <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          <StatCard
            icon={Users}
            label="Usuarios totales"
            value={m?.total_users ?? '—'}
            href="/admin/users"
            color="bg-indigo-500"
          />
          <StatCard
            icon={Image}
            label="Obras publicadas"
            value={m?.total_artworks ?? '—'}
            href="/admin/artworks"
            color="bg-tierra"
          />
          <StatCard
            icon={ShoppingBag}
            label="Transacciones"
            value={m?.total_transactions ?? '—'}
            href="/admin/transactions"
            color="bg-selva"
          />
          <StatCard
            icon={TrendingUp}
            label="Ingresos (30d)"
            value={m ? formatCOP(m.revenue_last_30_days) : '—'}
            color="bg-emerald-600"
          />
          <StatCard
            icon={Gavel}
            label="Nuevos usuarios (30d)"
            value={m?.new_users_last_30_days ?? '—'}
            color="bg-oro"
          />
        </section>

        {/* Middle: Pending + Quick Actions */}
        <section className="grid gap-6 lg:grid-cols-[1fr_320px]">

          {/* Pending approvals */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="flex items-center gap-2 text-base">
                <AlertCircle size={18} className="text-amber-500" />
                Pendientes de aprobación
                {totalPending > 0 && (
                  <span className="ml-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-amber-500 px-1.5 text-[10px] font-bold text-white">
                    {totalPending}
                  </span>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">

              {/* Pending events */}
              <div>
                <div className="mb-2 flex items-center justify-between">
                  <p className="text-sm font-semibold text-foreground flex items-center gap-1.5">
                    <CalendarClock size={14} className="text-amber-500" />
                    Eventos por aprobar
                    <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-700 dark:bg-amber-950 dark:text-amber-300">
                      {pendingEvents.length}
                    </span>
                  </p>
                  <Link
                    to="/admin/events"
                    className="text-xs text-primary hover:underline flex items-center gap-1"
                  >
                    Gestionar <ArrowRight size={11} />
                  </Link>
                </div>
                {pendingEvents.length === 0 ? (
                  <p className="rounded-lg bg-muted/40 py-3 text-center text-xs text-muted-foreground">
                    No hay eventos pendientes
                  </p>
                ) : (
                  <div className="space-y-2">
                    {pendingEvents.slice(0, 3).map((ev) => (
                      <div
                        key={ev.id}
                        className="flex items-center gap-3 rounded-lg border border-border bg-muted/30 px-3 py-2.5"
                      >
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-sm font-medium text-foreground">{ev.title}</p>
                          <p className="text-[11px] text-muted-foreground">
                            {ev.location} ·{' '}
                            {format(new Date(ev.start_date), 'd MMM yyyy', { locale: es })}
                          </p>
                        </div>
                        <Badge variant="secondary" className="text-[10px] flex-none">
                          {ev.event_type}
                        </Badge>
                      </div>
                    ))}
                    {pendingEvents.length > 3 && (
                      <Link
                        to="/admin/events"
                        className="block text-center text-xs text-primary hover:underline pt-1"
                      >
                        Ver {pendingEvents.length - 3} más →
                      </Link>
                    )}
                  </div>
                )}
              </div>

              <div className="border-t border-border" />

              {/* Pending artworks */}
              <div>
                <div className="mb-2 flex items-center justify-between">
                  <p className="text-sm font-semibold text-foreground flex items-center gap-1.5">
                    <Image size={14} className="text-tierra" />
                    Obras por moderar
                    <span className="rounded-full bg-orange-100 px-2 py-0.5 text-[11px] font-bold text-orange-700 dark:bg-orange-950 dark:text-orange-300">
                      {pendingArtworks.length}
                    </span>
                  </p>
                  <Link
                    to="/admin/artworks"
                    className="text-xs text-primary hover:underline flex items-center gap-1"
                  >
                    Gestionar <ArrowRight size={11} />
                  </Link>
                </div>
                {pendingArtworks.length === 0 ? (
                  <p className="rounded-lg bg-muted/40 py-3 text-center text-xs text-muted-foreground">
                    No hay obras pendientes
                  </p>
                ) : (
                  <div className="space-y-2">
                    {pendingArtworks.slice(0, 3).map((art) => (
                      <div
                        key={art.id}
                        className="flex items-center gap-3 rounded-lg border border-border bg-muted/30 px-3 py-2.5"
                      >
                        {(art.main_image_url || art.images?.[0]?.image_url) && (
                          <img
                            src={art.main_image_url || art.images?.[0]?.image_url}
                            alt={art.title}
                            className="h-9 w-9 flex-none rounded object-cover"
                          />
                        )}
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-sm font-medium text-foreground">{art.title}</p>
                          <p className="text-[11px] text-muted-foreground">
                            {art.category?.name ?? 'Sin categoría'}
                          </p>
                        </div>
                        <Badge variant="tierra" className="text-[10px] flex-none">
                          {art.status}
                        </Badge>
                      </div>
                    ))}
                    {pendingArtworks.length > 3 && (
                      <Link
                        to="/admin/artworks"
                        className="block text-center text-xs text-primary hover:underline pt-1"
                      >
                        Ver {pendingArtworks.length - 3} más →
                      </Link>
                    )}
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Quick actions */}
          <div className="flex flex-col gap-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Acciones rápidas</CardTitle>
              </CardHeader>
              <CardContent className="grid gap-2">
                {[
                  { to: '/admin/users', icon: Users, label: 'Gestionar usuarios', color: 'text-indigo-500' },
                  { to: '/admin/artworks', icon: Image, label: 'Moderar obras', color: 'text-tierra', badge: pendingArtworks.length },
                  { to: '/admin/events', icon: CalendarClock, label: 'Aprobar eventos', color: 'text-amber-500', badge: pendingEvents.length },
                  { to: '/admin/transactions', icon: Receipt, label: 'Ver transacciones', color: 'text-selva' },
                ].map(({ to, icon: Icon, label, color, badge }) => (
                  <Link
                    key={to}
                    to={to}
                    className="flex items-center gap-3 rounded-lg border border-border px-3 py-2.5 transition-colors hover:bg-muted/50"
                  >
                    <Icon size={16} className={color} />
                    <span className="flex-1 text-sm font-medium text-foreground">{label}</span>
                    {badge ? (
                      <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-amber-500 px-1 text-[10px] font-bold text-white">
                        {badge}
                      </span>
                    ) : (
                      <ArrowRight size={14} className="text-muted-foreground" />
                    )}
                  </Link>
                ))}
              </CardContent>
            </Card>

            {/* Platform status */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">Estado de la plataforma</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {[
                  { label: 'API backend', ok: true },
                  { label: 'Pagos (Wompi)', ok: true },
                  { label: 'Almacenamiento', ok: true },
                ].map(({ label, ok }) => (
                  <div key={label} className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">{label}</span>
                    <span className={`flex items-center gap-1 text-xs font-medium ${ok ? 'text-emerald-600' : 'text-destructive'}`}>
                      <CheckCircle2 size={12} />
                      {ok ? 'Operativo' : 'Error'}
                    </span>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Recent transactions */}
        <section>
          <Card>
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="flex items-center gap-2 text-base">
                <Receipt size={18} />
                Transacciones recientes
              </CardTitle>
              <Link
                to="/admin/transactions"
                className="text-xs text-primary hover:underline flex items-center gap-1"
              >
                Ver todas <ArrowRight size={11} />
              </Link>
            </CardHeader>
            <CardContent>
              {transactions.length === 0 ? (
                <p className="py-6 text-center text-sm text-muted-foreground">
                  No hay transacciones registradas.
                </p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left">
                    <thead>
                      <tr className="border-b border-border">
                        {['Orden', 'Tipo', 'Total', 'Estado', 'Fecha'].map((h) => (
                          <th
                            key={h}
                            className="pb-2 pr-4 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
                          >
                            {h}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {transactions.map((order) => {
                        const statusInfo = ORDER_STATUS_LABELS[order.status] ?? {
                          label: order.status,
                          color: '',
                        }
                        return (
                          <tr key={order.id} className="hover:bg-muted/30 transition-colors">
                            <td className="py-2.5 pr-4 font-mono text-xs text-foreground">
                              #{(order.id ?? '').slice(0, 8).toUpperCase()}
                            </td>
                            <td className="py-2.5 pr-4 text-xs text-muted-foreground">
                              {order.order_type === 'COMPRA_DIRECTA' ? 'Directa' : 'Subasta'}
                            </td>
                            <td className="py-2.5 pr-4 text-xs font-semibold text-foreground">
                              {order.total_amount ? formatCOP(parseFloat(order.total_amount)) : '—'}
                            </td>
                            <td className="py-2.5 pr-4">
                              <span
                                className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${statusInfo.color}`}
                              >
                                {statusInfo.label}
                              </span>
                            </td>
                            <td className="py-2.5 text-xs text-muted-foreground">
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
            </CardContent>
          </Card>
        </section>

      </main>
    </div>
  )
}
