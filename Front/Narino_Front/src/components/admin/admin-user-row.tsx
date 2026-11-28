import { Ban, RotateCcw, Trash2 } from 'lucide-react'

import type { AdminUserListItem } from '@/api/admin.api'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Select } from '@/components/ui/select'
import { ROLE_LABELS } from '@/constants/labels'
import type { UserRole } from '@/types'

const ROLES = Object.keys(ROLE_LABELS) as UserRole[]

interface AdminUserRowProps {
  user: AdminUserListItem
  /** Es la cuenta de quien está administrando: no puede cambiarse el rol ni suspenderse. */
  isSelf: boolean
  busy: boolean
  onRoleChange: (user: AdminUserListItem, role: UserRole) => void
  onToggleActive: (user: AdminUserListItem) => void
  onDelete: (user: AdminUserListItem) => void
}

export function AdminUserRow({ user, isSelf, busy, onRoleChange, onToggleActive, onDelete }: AdminUserRowProps) {
  const fullName = `${user.first_name} ${user.last_name}`.trim()

  return (
    <tr className="transition-colors hover:bg-bg-subtle/30">
      <td className="px-4 py-3">
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 flex-none items-center justify-center rounded-full bg-azul-tint text-sm font-bold text-azul">
            {(user.first_name || user.email).charAt(0).toUpperCase()}
          </div>
          <span className="text-sm font-medium text-text-primary">
            {fullName}
            {isSelf && <span className="ml-2 text-xs font-normal text-text-secondary">(tú)</span>}
          </span>
        </div>
      </td>
      <td className="px-4 py-3 text-sm text-text-secondary">{user.email}</td>
      <td className="px-4 py-3">
        <Select
          aria-label={`Rol de ${user.email}`}
          className="h-9 w-44 text-[13px]"
          value={user.role}
          disabled={isSelf || busy}
          title={isSelf ? 'No puedes cambiar tu propio rol' : undefined}
          onChange={(e) => onRoleChange(user, e.target.value as UserRole)}
        >
          {ROLES.map((role) => (
            <option key={role} value={role}>
              {ROLE_LABELS[role]}
            </option>
          ))}
        </Select>
      </td>
      <td className="px-4 py-3">
        {!user.is_active ? (
          <Badge variant="tomate">Suspendida</Badge>
        ) : user.is_verified ? (
          <Badge variant="verde">Verificado</Badge>
        ) : (
          <Badge variant="secondary">Sin verificar</Badge>
        )}
      </td>
      <td className="px-4 py-3">
        <div className="flex flex-wrap gap-1">
          {!isSelf && (
            <Button variant="ghost" size="sm" className="gap-1.5" disabled={busy} onClick={() => onToggleActive(user)}>
              {user.is_active ? <Ban size={13} /> : <RotateCcw size={13} />}
              {user.is_active ? 'Suspender' : 'Restaurar'}
            </Button>
          )}
          {user.role !== 'admin' && (
            <Button
              variant="ghost"
              size="sm"
              className="gap-1.5 text-tomate hover:bg-tomate-tint hover:text-tomate"
              onClick={() => onDelete(user)}
              disabled={busy}
            >
              <Trash2 size={13} />
              Eliminar
            </Button>
          )}
        </div>
      </td>
    </tr>
  )
}
