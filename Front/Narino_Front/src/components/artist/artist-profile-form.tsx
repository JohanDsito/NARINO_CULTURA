import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Save, UserRound } from 'lucide-react'
import { toast } from 'sonner'

import { createArtistProfile, updateArtistProfile } from '@/api/artists.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import type { ArtistProfile, User } from '@/types'
import { getApiErrorMessage } from '@/utils/apiError'

interface ArtistProfileFormProps {
  /** Perfil existente; `null` si el artista aún no lo ha creado. */
  profile: ArtistProfile | null
  user: User | null
}

/**
 * Formulario para crear o editar el perfil de artista. El estado se inicializa
 * una sola vez desde `profile`; el padre le pasa un `key` para reiniciarlo
 * cuando cambia el perfil (por ejemplo, después de crearlo).
 */
export function ArtistProfileForm({ profile, user }: ArtistProfileFormProps) {
  const queryClient = useQueryClient()
  const [form, setForm] = useState(() => ({
    artistic_name:
      profile?.artistic_name ?? `${user?.first_name ?? ''} ${user?.last_name ?? ''}`.trim(),
    city: profile?.city ?? '',
    discipline: profile?.discipline ?? '',
    bio: profile?.bio ?? '',
  }))

  const saveMutation = useMutation({
    mutationFn: async () => {
      if (!form.artistic_name.trim()) {
        throw new Error('El nombre artístico es obligatorio.')
      }

      const payload = {
        artistic_name: form.artistic_name.trim(),
        city: form.city.trim(),
        discipline: form.discipline.trim(),
        bio: form.bio.trim(),
      }

      return profile
        ? updateArtistProfile(profile.slug, payload)
        : createArtistProfile(payload)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['artist-profile', 'me'] })
      toast.success('Perfil de artista guardado.')
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const updateField = (field: keyof typeof form, value: string) => {
    setForm((current) => ({ ...current, [field]: value }))
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
            <Label htmlFor="discipline">Disciplina</Label>
            <Input
              id="discipline"
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
