import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { ImagePlus, Palette, Save, UserRound } from 'lucide-react'
import { toast } from 'sonner'

import { createArtistProfile, listArtistProfiles, updateArtistProfile } from '@/api/artists.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { useAuthStore } from '@/store/authStore'

export default function ArtistDashboardPage() {
  const user = useAuthStore((s) => s.user)
  const queryClient = useQueryClient()

  const profileQuery = useQuery({
    queryKey: ['artist-profile', 'me'],
    queryFn: listArtistProfiles,
    enabled: user?.role === 'artist',
  })

  const profile = useMemo(
    () => profileQuery.data?.find((item) => item.user_id === String(user?.id)) ?? null,
    [profileQuery.data, user?.id],
  )

  const initialForm = useMemo(() => {
    const defaultName = `${user?.first_name ?? ''} ${user?.last_name ?? ''}`.trim()
    return {
      artistic_name: profile?.artistic_name ?? user?.artistic_name ?? defaultName,
      city: profile?.city ?? user?.city ?? '',
      discipline: profile?.discipline ?? user?.category ?? '',
      bio: profile?.bio ?? user?.bio ?? '',
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
        city: form.city.trim() || undefined,
        discipline: form.discipline.trim() || undefined,
        bio: form.bio.trim() || undefined,
      }

      return profile
        ? updateArtistProfile(profile.slug, payload)
        : createArtistProfile(payload)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['artist-profile', 'me'] })
      toast.success('Perfil de artista guardado.')
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'No fue posible guardar el perfil.')
    },
  })

  const updateField = (field: keyof typeof form, value: string) => {
    setForm((current) => ({ ...current, [field]: value }))
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Perfil y portafolio
            </h1>
          </div>
          <Button asChild>
            <Link to="/dashboard/artworks/new" className="gap-2">
              <ImagePlus size={16} />
              Añadir obra
            </Link>
          </Button>
        </section>

        <section className="grid gap-5 lg:grid-cols-[1.4fr_0.8fr]">
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
                    onChange={(event) => updateField('artistic_name', event.target.value)}
                  />
                </div>
                <div className="space-y-1">
                  <Label htmlFor="city">Ciudad</Label>
                  <Input
                    id="city"
                    value={form.city}
                    onChange={(event) => updateField('city', event.target.value)}
                  />
                </div>
                <div className="space-y-1 md:col-span-2">
                  <Label htmlFor="category">Disciplina</Label>
                  <Input
                    id="category"
                    value={form.discipline}
                    onChange={(event) => updateField('discipline', event.target.value)}
                    placeholder="Música, pintura, artesanía..."
                  />
                </div>
                <div className="space-y-1 md:col-span-2">
                  <Label htmlFor="bio">Biografía</Label>
                  <Textarea
                    id="bio"
                    rows={5}
                    value={form.bio}
                    onChange={(event) => updateField('bio', event.target.value)}
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

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <Palette size={18} />
                Obras
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Administra tus obras publicadas, crea una nueva pieza o edita las existentes.
              </p>
              <div className="grid gap-3">
                <Button asChild variant="outline">
                  <Link to="/dashboard/artworks">Ver mis obras</Link>
                </Button>
                <Button asChild>
                  <Link to="/dashboard/artworks/new">Añadir obra</Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        </section>
      </main>
    </div>
  )
}
