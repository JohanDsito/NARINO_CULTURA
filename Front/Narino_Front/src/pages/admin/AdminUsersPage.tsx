import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { Search, Trash2, Users } from 'lucide-react'
import { toast } from 'sonner'

import { deleteAdminUser, listAdminUsers } from '@/api/admin.api'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PageShell } from '@/components/layout/page-shell'

const ROLE_LABELS: Record<string, string> = {
  artist: 'Artista',
  buyer: 'Visitante',
  cultural_manager: 'Gestor cultural',
  admin: 'Administrador',
}

const ROLE_COLORS: Record<string, string> = {
  artist: 'indigo',
  buyer: 'secondary',
  cultural_manager: 'selva',
  admin: 'tierra',
}

export default function AdminUsersPage() {
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')

  const { data: users = [], isLoading, isError, error } = useQuery({
    queryKey: ['admin-users'],
    queryFn: listAdminUsers,
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
    <div className="min-h-screen bg-background pt-16">
      <PageShell
        title="Gestión de Usuarios"
        subtitle={`${users.length} usuario${users.length === 1 ? '' : 's'} registrado${users.length === 1 ? '' : 's'}`}
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {/* Search */}
        <div className="relative mb-6 max-w-sm">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
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
                className="h-14 animate-pulse rounded-lg border border-border bg-muted"
              />
            ))}
          </div>
        ) : isError ? (
          <div className="rounded-xl border border-amber-300 bg-amber-50 dark:bg-amber-950/20 p-6 space-y-3">
            <p className="text-sm font-semibold text-amber-800 dark:text-amber-300">
              El backend no expone el listado de usuarios
            </p>
            <p className="text-xs text-amber-700 dark:text-amber-400">
              El endpoint <code className="bg-amber-100 dark:bg-amber-900 px-1 py-0.5 rounded font-mono">/api/v1/admin/users/</code> responde con <strong>405 (Method Not Allowed)</strong>, lo que significa que el ViewSet en Django no tiene la acción <code className="font-mono">list</code> habilitada.
            </p>
            <div className="text-xs text-amber-700 dark:text-amber-400 space-y-1">
              <p className="font-semibold">Fix en el backend (Django):</p>
              <pre className="bg-amber-100 dark:bg-amber-900 rounded p-2 text-[11px] overflow-x-auto">{`# En el archivo donde está AdminUserViewSet,\n# asegúrate de que herede de ModelViewSet:\n\nfrom rest_framework import viewsets, permissions\n\nclass AdminUserViewSet(viewsets.ModelViewSet):\n    permission_classes = [permissions.IsAdminUser]\n    queryset = User.objects.all().order_by('-date_joined')\n    serializer_class = UserSerializer\n\n# En urls.py:\n# router.register(r'admin/users', AdminUserViewSet)`}</pre>
            </div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-muted-foreground">
            <Users size={40} className="opacity-30" />
            <p className="text-sm">{search ? 'Sin resultados para tu búsqueda.' : 'No hay usuarios registrados.'}</p>
          </div>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-border">
            <table className="w-full text-left">
              <thead className="border-b border-border bg-muted/40">
                <tr>
                  {['Usuario', 'Email', 'Rol', 'Registro', 'Acciones'].map((h) => (
                    <th
                      key={h}
                      className="px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.map((user) => (
                  <tr key={user.id} className="transition-colors hover:bg-muted/30">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 flex-none items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">
                          {user.first_name.charAt(0).toUpperCase()}
                        </div>
                        <span className="text-sm font-medium text-foreground">
                          {user.first_name} {user.last_name}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{user.email}</td>
                    <td className="px-4 py-3">
                      <Badge
                        variant={(ROLE_COLORS[user.role] as 'indigo' | 'secondary' | 'selva' | 'tierra') ?? 'secondary'}
                        className="text-[11px]"
                      >
                        {ROLE_LABELS[user.role] ?? user.role}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">
                      {user.date_joined
                        ? format(new Date(user.date_joined), 'd MMM yyyy', { locale: es })
                        : '—'}
                    </td>
                    <td className="px-4 py-3">
                      {user.role !== 'admin' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="gap-1.5 text-destructive hover:bg-destructive/10 hover:text-destructive"
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
