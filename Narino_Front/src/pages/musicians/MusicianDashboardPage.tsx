import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Music, Save, UserRound } from 'lucide-react'
import { toast } from 'sonner'

import {
  createMusicianProfile,
  getMyMusicianProfile,
  updateMusicianProfile,
} from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { useAuthStore } from '@/store/authStore'
import { ROUTES } from '@/constants/routes'
import { AGGREGATION_TYPE_LABELS } from '@/constants/routes'
import type { AggregationType } from '@/types/auth'

const AGGREGATION_OPTIONS = Object.entries(AGGREGATION_TYPE_LABELS) as [
  AggregationType,
  string,
][]

export default function MusicianDashboardPage() {
  const user = useAuthStore((s) => s.user)
  const queryClient = useQueryClient()

  const profileQuery = useQuery({
    queryKey: ['musician-profile', 'me'],
    queryFn: async () => {
      try {
        return await getMyMusicianProfile()
      } catch {
        return null
      }
    },
    retry: false,
  })

  const profile = profileQuery.data ?? null

  const initialForm = useMemo(() => {
    const defaultName = `${user?.first_name ?? ''} ${user?.last_name ?? ''}`.trim()
    return {
      artistic_name: profile?.artistic_name ?? defaultName,
      aggregation_type: (profile?.aggregation_type ?? 'SOLISTA') as AggregationType,
      city: profile?.city ?? '',
      region: profile?.region ?? '',
      bio: profile?.bio ?? '',
      spotify_url: profile?.spotify_url ?? '',
      youtube_url: profile?.youtube_url ?? '',
      soundcloud_url: profile?.soundcloud_url ?? '',
      instagram_handle: profile?.instagram_handle ?? '',
    }
  }, [profile, user])

  const [form, setForm] = useState(initialForm)

  useEffect(() => {
    setForm(initialForm)
  }, [initialForm])

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (!form.artistic_name.trim()) {
        throw new Error('El nombre artístico es obligatorio.')
      }
      const payload = {
        artistic_name: form.artistic_name.trim(),
        aggregation_type: form.aggregation_type,
        city: form.city.trim() || undefined,
        region: form.region.trim() || undefined,
        bio: form.bio.trim() || undefined,
        spotify_url: form.spotify_url.trim() || undefined,
        youtube_url: form.youtube_url.trim() || undefined,
        soundcloud_url: form.soundcloud_url.trim() || undefined,
        instagram_handle: form.instagram_handle.trim() || undefined,
      }
      return profile
        ? updateMusicianProfile(profile.slug, payload)
        : createMusicianProfile(payload)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['musician-profile', 'me'] })
      toast.success('Perfil de músico guardado.')
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'No fue posible guardar el perfil.')
    },
  })

  const updateField = <K extends keyof typeof form>(field: K, value: (typeof form)[K]) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel del músico</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Perfil musical
            </h1>
          </div>
          <div className="flex items-center gap-3">
            <Button asChild variant="outline">
              <Link to={ROUTES.DASHBOARD.SELECT}>← Cambiar disciplina</Link>
            </Button>
            <Button asChild>
              <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS_NEW} className="gap-2">
                <Music size={16} />
                Añadir obra musical
              </Link>
            </Button>
          </div>
        </section>

        <section className="grid gap-5 lg:grid-cols-[1.4fr_0.8fr]">
          {/* Profile form */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <UserRound size={18} />
                Crear o editar perfil
              </CardTitle>
            </CardHeader>
            <CardContent>
              <form className="grid gap-4 md:grid-cols-2">
                <div className="space-y-1">
                  <Label htmlFor="artisticName">Nombre artístico</Label>
                  <Input
                    id="artisticName"
                    value={form.artistic_name}
                    onChange={(e) => updateField('artistic_name', e.target.value)}
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="aggregationType">Tipo de agrupación</Label>
                  <Select
                    id="aggregationType"
                    value={form.aggregation_type}
                    onChange={(e) =>
                      updateField('aggregation_type', e.target.value as AggregationType)
                    }
                  >
                    {AGGREGATION_OPTIONS.map(([value, label]) => (
                      <option key={value} value={value}>
                        {label}
                      </option>
                    ))}
                  </Select>
                </div>

                <div className="space-y-1">
                  <Label htmlFor="city">Ciudad</Label>
                  <Input
                    id="city"
                    value={form.city}
                    onChange={(e) => updateField('city', e.target.value)}
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="region">Región / Departamento</Label>
                  <Input
                    id="region"
                    value={form.region}
                    onChange={(e) => updateField('region', e.target.value)}
                  />
                </div>

                <div className="space-y-1 md:col-span-2">
                  <Label htmlFor="bio">Biografía</Label>
                  <Textarea
                    id="bio"
                    rows={4}
                    value={form.bio}
                    onChange={(e) => updateField('bio', e.target.value)}
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="spotify">Spotify</Label>
                  <Input
                    id="spotify"
                    placeholder="https://open.spotify.com/..."
                    value={form.spotify_url}
                    onChange={(e) => updateField('spotify_url', e.target.value)}
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="youtube">YouTube</Label>
                  <Input
                    id="youtube"
                    placeholder="https://youtube.com/..."
                    value={form.youtube_url}
                    onChange={(e) => updateField('youtube_url', e.target.value)}
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="soundcloud">SoundCloud</Label>
                  <Input
                    id="soundcloud"
                    placeholder="https://soundcloud.com/..."
                    value={form.soundcloud_url}
                    onChange={(e) => updateField('soundcloud_url', e.target.value)}
                  />
                </div>

                <div className="space-y-1">
                  <Label htmlFor="instagram">Instagram</Label>
                  <Input
                    id="instagram"
                    placeholder="@usuario"
                    value={form.instagram_handle}
                    onChange={(e) => updateField('instagram_handle', e.target.value)}
                  />
                </div>

                <div className="md:col-span-2">
                  <Button
                    type="button"
                    className="gap-2"
                    disabled={saveMutation.isPending || profileQuery.isLoading}
                    onClick={() => saveMutation.mutate()}
                  >
                    <Save size={16} />
                    {saveMutation.isPending ? 'Guardando...' : 'Guardar perfil'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>

          {/* Works card */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <Music size={18} />
                Obras musicales
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Administra tus obras musicales publicadas, añade canciones, videos o podcasts.
              </p>
              <div className="grid gap-3">
                <Button asChild variant="outline">
                  <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS}>Ver mis obras</Link>
                </Button>
                <Button asChild>
                  <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS_NEW}>Añadir obra</Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        </section>
      </main>
    </div>
  )
}
