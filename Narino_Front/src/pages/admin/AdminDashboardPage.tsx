import { useQuery } from '@tanstack/react-query'
import { Users, Image, ShoppingBag, Gavel } from 'lucide-react'
import { getAdminMetrics } from '@/api/admin.api'
import { Card } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'

function StatCard({ icon: Icon, label, value, color }: { icon: typeof Users; label: string; value: number | string; color: string }) {
  return (
    <Card className="p-6">
      <div className="flex items-center gap-4">
        <div className={`w-12 h-12 rounded-card flex items-center justify-center ${color}`}>
          <Icon size={22} className="text-white" />
        </div>
        <div>
          <p className="font-body text-text-muted text-sm">{label}</p>
          <p className="font-display font-bold text-text-primary text-[28px] leading-tight">{value}</p>
        </div>
      </div>
    </Card>
  )
}

export default function AdminDashboardPage() {
  const { data: metrics, isLoading } = useQuery({
    queryKey: ['admin-metrics'],
    queryFn: getAdminMetrics,
    staleTime: 2 * 60 * 1000,
  })

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Panel de Administración" subtitle="Métricas y actividad de la plataforma" />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-28" />
            ))}
          </div>
        ) : metrics ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <StatCard icon={Users} label="Usuarios totales" value={metrics.total_users ?? 0} color="bg-indigo-500" />
            <StatCard icon={Image} label="Obras totales" value={metrics.total_artworks ?? 0} color="bg-tierra" />
            <StatCard icon={ShoppingBag} label="Transacciones" value={metrics.total_transactions ?? 0} color="bg-selva" />
            <StatCard icon={Gavel} label="Nuevos usuarios (30d)" value={metrics.new_users_last_30_days ?? 0} color="bg-oro" />
          </div>
        ) : (
          <p className="text-text-muted font-body text-center py-12">No se pudieron cargar las métricas.</p>
        )}
      </main>
    </div>
  )
}
