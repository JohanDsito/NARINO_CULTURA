import { PageShell } from '@/components/layout/page-shell'
import { Users } from 'lucide-react'

export default function AdminUsersPage() {
  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Gestión de Usuarios" subtitle="Administra roles y estados de usuario" />
      <main className="mx-auto max-w-5xl px-6 py-8">
        <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
          <Users size={40} className="opacity-30" />
          <p className="font-body text-sm">Panel de gestión de usuarios en construcción.</p>
          <p className="font-body text-[12px] text-text-muted/60">
            Usa el endpoint <code className="font-mono bg-surface px-1 rounded">/api/v1/admin/users/</code> para gestionar usuarios via API.
          </p>
        </div>
      </main>
    </div>
  )
}
