import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Save, UserRound } from 'lucide-react'
import { toast } from 'sonner'

import {
  createMusicianProfile,
  getMusicGenres,
  updateMusicianProfile,
} from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { AGGREGATION_TYPE_LABELS } from '@/constants/labels'
import type { AggregationType, MusicianProfile, User } from '@/types'
import { getApiErrorMessage } from '@/utils/apiError'

const AGGREGATION_OPTIONS = Object.entries(AGGREGATION_TYPE_LABELS) as [AggregationType, string][]

interface MusicianProfileFormProps {
  /** Perfil existente; `null` si el músico aún no lo ha creado. */
  profile: MusicianProfile | null
  user: User | null
}

function formFromProfile(profile: MusicianProfile | null, user: User | null) {
  return {
    artistic_name:
      profile?.artistic_name ?? `${user?.first_name ?? ''} ${user?.last_name ?? ''}`.trim(),
    aggregation_type: (profile?.aggregation_type ?? 'SOLISTA') as AggregationType,
    city: profile?.city ?? '',
    region: profile?.region ?? '',
    bio: profile?.bio ?? '',
    spotify_url: profile?.spotify_url ?? '',
    youtube_url: profile?.youtube_url ?? '',
    soundcloud_url: profile?.soundcloud_url ?? '',
    instagram_handle: profile?.instagram_handle ?? '',
    genre_ids: profile?.genres.map((g) => g.id) ?? [],
  }
}

/**
 * Formulario para crear o editar el perfil de músico. El estado se inicializa
 * una sola vez; el padre le pasa un `key` para reiniciarlo cuando cambia el perfil.
 */
export function MusicianProfileForm({ profile, user }: MusicianProfileFormProps) {
  const queryClient = useQueryClient()
  const [form, setForm] = useState(() => formFromProfile(profile, user))

  const genresQuery = useQuery({
    queryKey: ['music-genres'],
    queryFn: () => getMusicGenres(),
    staleTime: Infinity,
  })
  const availableGenres = genresQuery.data ?? []

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (!form.artistic_name.trim()) {
        throw new Error('El nombre artístico es obligatorio.')
      }
      const payload = {
        artistic_name: form.artistic_name.trim(),
        aggregation_type: form.aggregation_type,
        city: form.city.trim(),
        region: form.region.trim(),
        bio: form.bio.trim(),
        spotify_url: form.spotify_url.trim(),
        youtube_url: form.youtube_url.trim(),
        soundcloud_url: form.soundcloud_url.trim(),
        instagram_handle: form.instagram_handle.trim(),
        genre_ids: form.genre_ids,
      }
      return profile
        ? updateMusicianProfile(profile.slug, payload)
        : createMusicianProfile(payload)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['musician-profile', 'me'] })
      toast.success('Perfil de músico guardado.')
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const updateField = <K extends keyof typeof form>(field: K, value: (typeof form)[K]) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  const toggleGenre = (id: number) => {
    setForm((current) => ({
      ...current,
      genre_ids: current.genre_ids.includes(id)
        ? current.genre_ids.filter((g) => g !== id)
        : [...current.genre_ids, id],
    }))
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <UserRound size={18} />
          {profile ? 'Editar perfil' : 'Crear perfil'}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <form
      className="grid gap-4 md:grid-cols-2"
      onSubmit={(event) => {
        event.preventDefault()
        saveMutation.mutate()
      }}
    >
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

          <div className="space-y-2 md:col-span-2">
            <Label>Géneros musicales</Label>
            {genresQuery.isLoading ? (
              <p className="text-xs text-text-secondary">Cargando géneros…</p>
            ) : (
              <div className="flex flex-wrap gap-2">
                {availableGenres.map((genre) => {
                  const selected = form.genre_ids.includes(genre.id)
                  return (
                    <button
                      key={genre.id}
                      type="button"
                      onClick={() => toggleGenre(genre.id)}
                      className={[
                        'flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium transition-colors',
                        selected
                          ? 'border-tierra bg-tierra text-on-tierra'
                          : 'border-border bg-bg text-text-primary hover:border-tierra/60 hover:bg-tierra/5',
                      ].join(' ')}
                    >
                      {genre.icon && <span>{genre.icon}</span>}
                      {genre.name}
                    </button>
                  )
                })}
              </div>
            )}
            {form.genre_ids.length > 0 && (
              <p className="text-xs text-text-secondary">
                {form.genre_ids.length} género{form.genre_ids.length !== 1 ? 's' : ''} seleccionado{form.genre_ids.length !== 1 ? 's' : ''}
              </p>
            )}
          </div>

          <div className="md:col-span-2">
            <Button type="submit" className="gap-2" disabled={saveMutation.isPending}>
              <Save size={16} />
              {saveMutation.isPending ? 'Guardando...' : 'Guardar perfil'}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
