import { Search } from 'lucide-react'

import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { ROLE_LABELS } from '@/constants/labels'
import type { UserRole } from '@/types'

export type StatusFilter = 'all' | 'active' | 'suspended'

interface AdminUserFiltersProps {
  search: string
  role: UserRole | ''
  status: StatusFilter
  onSearchChange: (value: string) => void
  onRoleChange: (value: UserRole | '') => void
  onStatusChange: (value: StatusFilter) => void
}

/** Búsqueda y filtros por rol y por estado del listado de usuarios. */
export function AdminUserFilters({
  search,
  role,
  status,
  onSearchChange,
  onRoleChange,
  onStatusChange,
}: AdminUserFiltersProps) {
  return (
    <div className="mb-6 flex flex-wrap items-end gap-3">
      <div className="relative w-full max-w-sm">
        <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary" />
        <Input
          aria-label="Buscar usuarios"
          placeholder="Buscar por nombre o email…"
          className="pl-9"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
        />
      </div>
      <Select
        aria-label="Filtrar por rol"
        className="w-48"
        value={role}
        onChange={(e) => onRoleChange(e.target.value as UserRole | '')}
      >
        <option value="">Todos los roles</option>
        {(Object.keys(ROLE_LABELS) as UserRole[]).map((value) => (
          <option key={value} value={value}>
            {ROLE_LABELS[value]}
          </option>
        ))}
      </Select>
      <Select
        aria-label="Filtrar por estado"
        className="w-48"
        value={status}
        onChange={(e) => onStatusChange(e.target.value as StatusFilter)}
      >
        <option value="all">Todos los estados</option>
        <option value="active">Activas</option>
        <option value="suspended">Suspendidas</option>
      </Select>
    </div>
  )
}
