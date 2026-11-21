import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Search, Trash2, Users } from 'lucide-react'
import { toast } from 'sonner'

import { deleteAdminUser, listAdminUsers } from '@/api/admin.api'
import { Badge, type BadgeVariant } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PageShell } from '@/components/layout/page-shell'
import { ROLE_LABELS } from '@/constants/labels'

const ROLE_COLORS: Record<string, BadgeVariant> = {
  artist: 'indigo',
  buyer: 'secondary',
  cultural_manager: 'selva',
  admin: 'tierra',
}

export default function AdminUsersPage() {
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')

  const { data: users = [], isLoading, isError } = useQuery({
    queryKey: ['admin-users'],
    queryFn: () => listAdminUsers(),
    staleTime: 30_000,
    refetchInterval: 30_000,
    retry: 1,
  })

  const deleteMutation = useMutation({
    mutationFn: deleteAdminUser,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['admin-users'] })
      await queryClient.invalidateQueries({ queryKey: ['admin-metrics'] })
      toast.success('Usuario eliminado.')
    },
    onError: () => toast.error('No se pudo eliminar el usuario.'),
  })

  const handleDelete = (id: string, email: string) => {
    if (
      !window.confirm(
        `¿Eliminar permanentemente a "${email}"?\nEsta acción borrará su perfil y no se puede deshacer.`,
      )
    )
      return
    deleteMutation.mutate(id)
  }

  const filtered = users.filter(
    (u) =>
      !search ||
      u.email.toLowerCase().includes(search.toLowerCase()) ||
      `${u.first_name} ${u.last_name}`.toLowerCase().includes(search.toLowerCase()),
  )

  return (
    <div className="min-h-screen pt-16">
      <PageShell
        title="Gestión de Usuarios"
        subtitle={`${users.length} usuario${users.length === 1 ? '' : 's'} registrado${users.length === 1 ? '' : 's'}`}
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {/* Search */}
        <div className="relative mb-6 max-w-sm">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary" />
          <Input
            placeholder="Buscar por nombre o email…"
            className="pl-9"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="h-14 animate-pulse rounded-lg border border-border bg-bg-subtle"
              />
            ))}
          </div>
        ) : isError ? (
          <div className="rounded-card border border-error/30 bg-error/5 p-6 text-sm text-error">
            No se pudo cargar el listado de usuarios. Intenta de nuevo más tarde.
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-secondary">
            <Users size={40} className="opacity-30" />
            <p className="text-sm">{search ? 'Sin resultados para tu búsqueda.' : 'No hay usuarios registrados.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-border">
            <table className="w-full text-left">
              <thead className="border-b border-border bg-bg-subtle/40">
                <tr>
                  {['Usuario', 'Email', 'Rol', 'Estado', 'Acciones'].map((h) => (
                    <th
                      key={h}
                      className="px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-text-secondary"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.map((user) => (
                  <tr key={user.id} className="transition-colors hover:bg-bg-subtle/30">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 flex-none items-center justify-center rounded-full bg-tierra/10 text-sm font-bold text-tierra">
                          {(user.first_name || user.email).charAt(0).toUpperCase()}
                        </div>
                        <span className="text-sm font-medium text-text-primary">
                          {user.first_name} {user.last_name}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-text-secondary">{user.email}</td>
                    <td className="px-4 py-3">
                      <Badge
                        variant={ROLE_COLORS[user.role] ?? 'secondary'}
                        className="text-[11px]"
                      >
                        {ROLE_LABELS[user.role] ?? user.role}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-sm text-text-secondary">
                      {!user.is_active ? 'Inactivo' : user.is_verified ? 'Verificado' : 'Sin verificar'}
                    </td>
                    <td className="px-4 py-3">
                      {user.role !== 'admin' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="gap-1.5 text-error hover:bg-error/10 hover:text-error"
                          onClick={() => handleDelete(user.id, user.email)}
                          disabled={deleteMutation.isPending}
                        >
                          <Trash2 size={13} />
                          Eliminar
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  )
}
