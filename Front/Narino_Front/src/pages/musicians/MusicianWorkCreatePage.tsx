import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Music, Save } from 'lucide-react'
import { toast } from 'sonner'

import { createMusicalWork, type CreateMusicalWorkPayload } from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { ROUTES } from '@/constants/routes'
import { MUSICAL_WORK_TYPE_LABELS } from '@/constants/routes'

type WorkType = CreateMusicalWorkPayload['work_type']

const WORK_TYPE_OPTIONS = Object.entries(MUSICAL_WORK_TYPE_LABELS) as [WorkType, string][]

const initialForm: CreateMusicalWorkPayload = {
  title: '',
  work_type: 'STUDIO',
  youtube_url: '',
  soundcloud_embed: '',
  spotify_track_url: '',
  description: '',
  release_date: '',
}

export default function MusicianWorkCreatePage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [form, setForm] = useState(initialForm)

  const createMutation = useMutation({
    mutationFn: () => {
      if (!form.title.trim()) throw new Error('El título es obligatorio.')
      const payload: CreateMusicalWorkPayload = {
        title: form.title.trim(),
        work_type: form.work_type,
        youtube_url: form.youtube_url?.trim() || undefined,
        soundcloud_embed: form.soundcloud_embed?.trim() || undefined,
        spotify_track_url: form.spotify_track_url?.trim() || undefined,
        description: form.description?.trim() || undefined,
        release_date: form.release_date || undefined,
      }
      return createMusicalWork(payload)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['my-musical-works'] })
      toast.success('Obra musical creada.')
      navigate(ROUTES.DASHBOARD.MUSICIAN.WORKS)
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'No fue posible crear la obra.')
    },
  })

  const updateField = <K extends keyof CreateMusicalWorkPayload>(
    field: K,
    value: CreateMusicalWorkPayload[K],
  ) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel del músico</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Añadir obra musical
            </h1>
          </div>
          <Button asChild variant="outline">
            <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS}>← Volver a mis obras</Link>
          </Button>
        </section>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Music size={18} />
              Nueva obra
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form className="grid gap-4 md:grid-cols-2">
              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="title">Título *</Label>
                <Input
                  id="title"
                  value={form.title}
                  onChange={(e) => updateField('title', e.target.value)}
                  placeholder="Nombre de la canción, video o podcast"
                />
              </div>

              <div className="space-y-1">
                <Label htmlFor="workType">Tipo de obra</Label>
                <Select
                  id="workType"
                  value={form.work_type}
                  onChange={(e) => updateField('work_type', e.target.value as WorkType)}
                >
                  {WORK_TYPE_OPTIONS.map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </Select>
              </div>

              <div className="space-y-1">
                <Label htmlFor="releaseDate">Fecha de lanzamiento</Label>
                <Input
                  id="releaseDate"
                  type="date"
                  value={form.release_date ?? ''}
                  onChange={(e) => updateField('release_date', e.target.value)}
                />
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="youtube">URL de YouTube</Label>
                <Input
                  id="youtube"
                  placeholder="https://youtube.com/watch?v=..."
                  value={form.youtube_url ?? ''}
                  onChange={(e) => updateField('youtube_url', e.target.value)}
                />
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="spotify">URL de Spotify</Label>
                <Input
                  id="spotify"
                  placeholder="https://open.spotify.com/track/..."
                  value={form.spotify_track_url ?? ''}
                  onChange={(e) => updateField('spotify_track_url', e.target.value)}
                />
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="soundcloud">Embed de SoundCloud</Label>
                <Input
                  id="soundcloud"
                  placeholder="https://soundcloud.com/..."
                  value={form.soundcloud_embed ?? ''}
                  onChange={(e) => updateField('soundcloud_embed', e.target.value)}
                />
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="description">Descripción</Label>
                <Textarea
                  id="description"
                  rows={4}
                  placeholder="Cuéntanos sobre esta obra..."
                  value={form.description ?? ''}
                  onChange={(e) => updateField('description', e.target.value)}
                />
              </div>

              <div className="flex items-center gap-3 md:col-span-2">
                <Button
                  type="button"
                  className="gap-2"
                  disabled={createMutation.isPending}
                  onClick={() => createMutation.mutate()}
                >
                  <Save size={16} />
                  {createMutation.isPending ? 'Guardando...' : 'Guardar obra'}
                </Button>
                <Button asChild variant="outline">
                  <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS}>Cancelar</Link>
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
