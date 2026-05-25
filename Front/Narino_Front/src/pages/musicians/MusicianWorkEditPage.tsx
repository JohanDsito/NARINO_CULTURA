import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Music, Save } from 'lucide-react'
import { toast } from 'sonner'

import { getMusicalWork, updateMusicalWork, type CreateMusicalWorkPayload } from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PageLoader } from '@/components/layout/page-loader'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { ROUTES, MUSICAL_WORK_TYPE_LABELS } from '@/constants/routes'

type WorkType = CreateMusicalWorkPayload['work_type']

const WORK_TYPE_OPTIONS = Object.entries(MUSICAL_WORK_TYPE_LABELS) as [WorkType, string][]

const emptyForm: CreateMusicalWorkPayload = {
  title: '',
  work_type: 'STUDIO',
  youtube_url: '',
  soundcloud_embed: '',
  spotify_track_url: '',
  description: '',
  release_date: '',
}

export default function MusicianWorkEditPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [form, setForm] = useState(emptyForm)

  const { data: work, isLoading, isError } = useQuery({
    queryKey: ['musical-work', id],
    queryFn: () => getMusicalWork(id!),
    enabled: Boolean(id),
  })

  useEffect(() => {
    if (work) {
      setForm({
        title: work.title ?? '',
        work_type: work.work_type ?? 'STUDIO',
        youtube_url: work.youtube_url ?? '',
        soundcloud_embed: work.soundcloud_embed ?? '',
        spotify_track_url: work.spotify_track_url ?? '',
        description: work.description ?? '',
        release_date: work.release_date ?? '',
      })
    }
  }, [work])

  const updateMutation = useMutation({
    mutationFn: () => {
      if (!form.title.trim()) throw new Error('El título es obligatorio.')
      const payload: Partial<CreateMusicalWorkPayload> = {
        title: form.title.trim(),
        work_type: form.work_type,
        youtube_url: form.youtube_url?.trim() || undefined,
        soundcloud_embed: form.soundcloud_embed?.trim() || undefined,
        spotify_track_url: form.spotify_track_url?.trim() || undefined,
        description: form.description?.trim() || undefined,
        release_date: form.release_date || undefined,
      }
      return updateMusicalWork(id!, payload)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['my-musical-works'] })
      await queryClient.invalidateQueries({ queryKey: ['musical-work', id] })
      toast.success('Obra actualizada.')
      navigate(ROUTES.DASHBOARD.MUSICIAN.WORKS)
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'No fue posible actualizar la obra.')
    },
  })

  const updateField = <K extends keyof CreateMusicalWorkPayload>(
    field: K,
    value: CreateMusicalWorkPayload[K],
  ) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  if (isLoading) return <PageLoader label="Cargando obra..." />

  if (isError || !work) {
    return (
      <div className="min-h-screen bg-background pt-24 flex flex-col items-center gap-4">
        <p className="text-muted-foreground">No se encontró la obra.</p>
        <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS} className="text-sm hover:underline">
          ← Volver a mis obras
        </Link>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel del músico</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Editar obra musical
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
              {work.title}
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
                  disabled={updateMutation.isPending}
                  onClick={() => updateMutation.mutate()}
                >
                  <Save size={16} />
                  {updateMutation.isPending ? 'Guardando...' : 'Guardar cambios'}
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
