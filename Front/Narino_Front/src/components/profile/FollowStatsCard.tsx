import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Users, ChevronDown, ChevronUp } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { FollowItem } from '@/api/artists.api'

interface FollowStatsCardProps {
  followersCount: number
  followersQueryKey: unknown[]
  fetchFollowers: () => Promise<FollowItem[]>
  followingQueryKey: unknown[]
  fetchFollowing: () => Promise<FollowItem[]>
  enabled: boolean
}

function Avatar({ item }: { item: FollowItem }) {
  const name = item.artistic_name
    ?? `${item.first_name ?? ''} ${item.last_name ?? ''}`.trim()
    ?? '?'
  const initial = name.charAt(0).toUpperCase()

  return (
    <div className="flex items-center gap-2.5">
      {item.avatar_url ? (
        <img
          src={item.avatar_url}
          alt={name}
          className="h-8 w-8 rounded-full object-cover flex-none"
        />
      ) : (
        <div className="flex h-8 w-8 flex-none items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">
          {initial}
        </div>
      )}
      <span className="text-sm text-foreground truncate">{name}</span>
    </div>
  )
}

function FollowList({
  queryKey,
  fetcher,
  label,
  enabled,
}: {
  queryKey: unknown[]
  fetcher: () => Promise<FollowItem[]>
  label: string
  enabled: boolean
}) {
  const [open, setOpen] = useState(false)

  const { data = [], isLoading, isError } = useQuery({
    queryKey,
    queryFn: fetcher,
    enabled: enabled && open,
    retry: 1,
  })

  return (
    <div>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between py-1 text-left text-sm text-primary hover:underline"
      >
        <span>Ver {label}</span>
        {open ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
      </button>

      {open && (
        <div className="mt-2 space-y-2">
          {isLoading && (
            <div className="space-y-2">
              {[1, 2, 3].map((i) => (
                <div key={i} className="flex items-center gap-2.5">
                  <div className="h-8 w-8 animate-pulse rounded-full bg-muted flex-none" />
                  <div className="h-3 w-24 animate-pulse rounded bg-muted" />
                </div>
              ))}
            </div>
          )}
          {isError && (
            <p className="text-xs text-amber-600 dark:text-amber-400">
              El servidor aún no tiene este endpoint activo. Contacta al administrador.
            </p>
          )}
          {!isLoading && !isError && data.length === 0 && (
            <p className="text-xs text-muted-foreground">No hay {label} aún.</p>
          )}
          {!isLoading && data.slice(0, 8).map((item) => (
            <Avatar key={item.id} item={item} />
          ))}
          {data.length > 8 && (
            <p className="text-xs text-muted-foreground">
              y {data.length - 8} más…
            </p>
          )}
        </div>
      )}
    </div>
  )
}

export function FollowStatsCard({
  followersCount,
  followersQueryKey,
  fetchFollowers,
  followingQueryKey,
  fetchFollowing,
  enabled,
}: FollowStatsCardProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Users size={18} />
          Comunidad
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Stats row */}
        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-xl bg-primary/5 px-4 py-3 text-center">
            <p className="text-2xl font-bold leading-none text-primary">{followersCount}</p>
            <p className="mt-1 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
              Seguidores
            </p>
          </div>
          <div className="rounded-xl bg-muted/60 px-4 py-3 text-center">
            <p className="text-2xl font-bold leading-none text-muted-foreground">—</p>
            <p className="mt-1 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
              Siguiendo
            </p>
          </div>
        </div>

        <div className="border-t border-border pt-3 space-y-3">
          <FollowList
            queryKey={followersQueryKey}
            fetcher={fetchFollowers}
            label="seguidores"
            enabled={enabled}
          />
          <FollowList
            queryKey={followingQueryKey}
            fetcher={fetchFollowing}
            label="siguiendo"
            enabled={enabled}
          />
        </div>
      </CardContent>
    </Card>
  )
}
