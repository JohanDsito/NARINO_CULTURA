import { Bell } from 'lucide-react'
import { PageShell } from '@/components/layout/page-shell'

export default function NotificationsPage() {
  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Notificaciones"
        subtitle="Centro de notificaciones de tu cuenta"
      />
      <main className="mx-auto max-w-2xl px-6 py-8">
        <div className="flex flex-col items-center gap-4 py-24 text-text-muted">
          <Bell size={48} className="opacity-30" />
          <p className="font-body text-center text-sm">
            Las notificaciones en tiempo real estarán disponibles próximamente.
          </p>
          <p className="font-body text-center text-[12px] text-text-muted/60">
            Recibirás alertas sobre pujas, ventas, nuevos seguidores y eventos culturales.
          </p>
        </div>
      </main>
    </div>
  )
}
