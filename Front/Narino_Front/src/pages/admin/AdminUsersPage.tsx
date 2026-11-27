import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Users } from 'lucide-react'
import { toast } from 'sonner'

import {
  deleteAdminUser,
  listAdminUsers,
  updateAdminUser,
  type AdminUserListItem,
} from '@/api/admin.api'
import { AdminUserFilters, type StatusFilter } from '@/components/admin/admin-user-filters'
import { AdminUserRow } from '@/components/admin/admin-user-row'
import { PageShell } from '@/components/layout/page-shell'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { ROLE_LABELS } from '@/constants/labels'
import { useAuthStore } from '@/store/authStore'
import type { UserRole } from '@/types'
import { getApiErrorMessage } from '@/utils/apiError'

type PendingChange =
  | { kind: 'role'; user: AdminUserListItem; role: UserRole }
  | { kind: 'active'; user: AdminUserListItem; active: boolean }

function userName(user: AdminUserListItem) {
  return `${user.first_name} ${user.last_name}`.trim() || user.email
}

export default function AdminUsersPage() {
  const queryClient = useQueryClient()
  const currentUserId = useAuthStore((s) => s.user?.id)
  const [search, setSearch] = useState('')
  const [role, setRole] = useState<UserRole | ''>('')
  const [status, setStatus] = useState<StatusFilter>('all')
  const [pending, setPending] = useState<PendingChange | null>(null)

  const filters = {
    role: role || undefined,
    is_active: status === 'all' ? undefined : status === 'active',
  }

  const { data: users = [], isLoading, isError } = useQuery({
    queryKey: ['admin-users', filters],
    queryFn: () => listAdminUsers(filters),
    staleTime: 30_000,
    refetchInterval: 30_000,
    retry: 1,
  })

  const refresh = async () => {
    await queryClient.invalidateQueries({ queryKey: ['admin-users'] })
    await queryClient.invalidateQueries({ queryKey: ['admin-metrics'] })
  }

  const deleteMutation = useMutation({
    mutationFn: deleteAdminUser,
    onSuccess: async () => {
      await refresh()
      toast.success('Usuario eliminado.')
    },
    // 409 (`user_has_sales`): el mensaje del backend sugiere suspenderlo
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: { role?: UserRole; is_active?: boolean } }) =>
      updateAdminUser(id, payload),
    onSuccess: async (_data, { payload }) => {
      await refresh()
      toast.success(
        payload.role
          ? 'Rol actualizado.'
          : payload.is_active
            ? 'Cuenta restaurada.'
            : 'Cuenta suspendida.',
      )
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
    onSettled: () => setPending(null),
  })

  const askRoleChange = (user: AdminUserListItem, next: UserRole) => {
    // Un admin no puede quitarse su propio rol (el backend no lo impide, se valida aquí)
    if (user.id === currentUserId) {
      toast.error('No puedes cambiar tu propio rol de administrador.')
      return
    }
    if (next !== user.role) setPending({ kind: 'role', user, role: next })
  }

  const askToggleActive = (user: AdminUserListItem) => {
    if (user.id === currentUserId) {
      toast.error('No puedes suspender tu propia cuenta.')
      return
    }
    setPending({ kind: 'active', user, active: !user.is_active })
  }

  const handleDelete = (user: AdminUserListItem) => {
    if (
      !window.confirm(
        `¿Eliminar permanentemente a "${user.email}"?\nEsta acción borrará su perfil y no se puede deshacer.`,
      )
    )
      return
    deleteMutation.mutate(user.id)
  }

  const confirmPending = () => {
    if (!pending) return
    updateMutation.mutate({
      id: pending.user.id,
      payload: pending.kind === 'role' ? { role: pending.role } : { is_active: pending.active },
    })
  }

  const term = search.trim().toLowerCase()
  const filtered = users.filter(
    (u) =>
      !term ||
      u.email.toLowerCase().includes(term) ||
      `${u.first_name} ${u.last_name}`.toLowerCase().includes(term),
  )
  const hasFilters = Boolean(term || role || status !== 'all')
  const busy = updateMutation.isPending || deleteMutation.isPending

  return (
    <div className="min-h-screen pt-16">
      <PageShell
        title="Gestión de Usuarios"
        subtitle={`${users.length} usuario${users.length === 1 ? '' : 's'} ${hasFilters ? 'encontrado' : 'registrado'}${users.length === 1 ? '' : 's'}`}
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        <AdminUserFilters
          search={search}
          role={role}
          status={status}
          onSearchChange={setSearch}
          onRoleChange={setRole}
          onStatusChange={setStatus}
        />

        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-14 animate-pulse rounded-lg border border-border bg-bg-subtle" />
            ))}
          </div>
        ) : isError ? (
          <div className="rounded-card border border-error/30 bg-error/5 p-6 text-sm text-error">
            No se pudo cargar el listado de usuarios. Intenta de nuevo más tarde.
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-secondary">
            <Users size={40} className="opacity-30" />
            <p className="text-sm">
              {hasFilters ? 'Sin resultados para tu búsqueda.' : 'No hay usuarios registrados.'}
            </p>
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
                  <AdminUserRow
                    key={user.id}
                    user={user}
                    isSelf={user.id === currentUserId}
                    busy={busy}
                    onRoleChange={askRoleChange}
                    onToggleActive={askToggleActive}
                    onDelete={handleDelete}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>

      <ConfirmDialog
        open={pending !== null}
        title={
          pending?.kind === 'role'
            ? 'Cambiar rol'
            : pending?.kind === 'active' && !pending.active
              ? 'Suspender cuenta'
              : 'Restaurar cuenta'
        }
        description={
          pending?.kind === 'role' ? (
            <p>
              ¿Cambiar el rol de <strong>{userName(pending.user)}</strong> de {ROLE_LABELS[pending.user.role]} a{' '}
              <strong>{ROLE_LABELS[pending.role]}</strong>? Sus permisos cambiarán de inmediato.
            </p>
          ) : pending?.kind === 'active' && !pending.active ? (
            <p>
              ¿Suspender la cuenta de <strong>{userName(pending.user)}</strong>? No podrá iniciar sesión hasta que
              la restaures. Sus datos y compras se conservan.
            </p>
          ) : pending ? (
            <p>
              ¿Restaurar la cuenta de <strong>{userName(pending.user)}</strong>? Podrá volver a iniciar sesión.
            </p>
          ) : undefined
        }
        confirmLabel={
          updateMutation.isPending
            ? 'Guardando…'
            : pending?.kind === 'role'
              ? 'Cambiar rol'
              : pending?.kind === 'active' && !pending.active
                ? 'Suspender'
                : 'Restaurar'
        }
        tone={pending?.kind === 'active' && !pending.active ? 'danger' : 'primary'}
        isPending={updateMutation.isPending}
        onConfirm={confirmPending}
        onCancel={() => setPending(null)}
      />
    </div>
  )
}
