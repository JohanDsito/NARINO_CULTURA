import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CalendarPlus, ImagePlus, Palette } from 'lucide-react'
import { toast } from 'sonner'

import {
  getArtistFollowers,
  getMyArtistProfile,
  getMyFollowing,
  uploadArtistProfileImage,
} from '@/api/artists.api'
import { ArtistProfileForm } from '@/components/artist/artist-profile-form'
import { FollowStatsCard } from '@/components/profile/follow-stats-card'
import { ProfileImageUpload } from '@/components/profile/profile-image-upload'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { useAuthStore } from '@/store/authStore'
import { getApiErrorMessage } from '@/utils/apiError'

export default function ArtistDashboardPage() {
  const user = useAuthStore((s) => s.user)
  const queryClient = useQueryClient()

  const profileQuery = useQuery({
    queryKey: ['artist-profile', 'me'],
    queryFn: () => getMyArtistProfile(),
    enabled: user?.role === 'artist',
  })
  const profile = profileQuery.data ?? null

  const uploadImageMutation = useMutation({
    mutationFn: (file: File) => {
      if (!profile?.slug) throw new Error('Guarda el perfil antes de subir una foto.')
      return uploadArtistProfileImage(profile.slug, file)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['artist-profile', 'me'] })
      toast.success('Foto de perfil actualizada.')
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  return (
    <div className="min-h-screen bg-bg pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-text-secondary">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-text-primary">
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

        <section className="grid gap-5 lg:grid-cols-[1.4fr_0.8fr] lg:items-start">
          {/* Left column: form + action cards */}
          <div className="flex flex-col gap-5">
            {profileQuery.isLoading ? (
              <Skeleton className="h-[420px] w-full rounded-card" />
            ) : (
              <ArtistProfileForm key={profile?.slug ?? 'nuevo'} profile={profile} user={user} />
            )}

            {/* Action cards */}
            <div className="grid gap-5 sm:grid-cols-2">
              <Card className="flex flex-col">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-lg">
                    <Palette size={18} />
                    Obras
                  </CardTitle>
                </CardHeader>
                <CardContent className="flex flex-1 flex-col justify-between gap-4">
                  <p className="text-sm text-text-secondary">
                    Administra tus obras publicadas, crea una nueva pieza o edita las existentes.
                  </p>
                  <div className="grid gap-2">
                    <Button asChild variant="outline">
                      <Link to="/dashboard/artworks">Ver mis obras</Link>
                    </Button>
                    <Button asChild>
                      <Link to="/dashboard/artworks/new">Añadir obra</Link>
                    </Button>
                  </div>
                </CardContent>
              </Card>

              <Card className="flex flex-col">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-lg">
                    <CalendarPlus size={18} />
                    Eventos
                  </CardTitle>
                </CardHeader>
                <CardContent className="flex flex-1 flex-col justify-between gap-4">
                  <p className="text-sm text-text-secondary">
                    Publica exposiciones, talleres o presentaciones. Será revisado por el
                    administrador antes de aparecer en el calendario.
                  </p>
                  <Button asChild className="w-full">
                    <Link to="/dashboard/events/new">Crear evento</Link>
                  </Button>
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Right column */}
          <div className="flex flex-col gap-5">
            <ProfileImageUpload
              currentUrl={profile?.profile_image_url || undefined}
              name={profile?.artistic_name || (user?.first_name ?? '?')}
              onUpload={(file) => uploadImageMutation.mutateAsync(file)}
              isPending={uploadImageMutation.isPending}
              disabled={!profile?.slug}
            />

            <FollowStatsCard
              followersCount={profile?.followers_count ?? 0}
              followersQueryKey={['artist-followers', profile?.slug]}
              fetchFollowers={() => getArtistFollowers(profile!.slug)}
              followingQueryKey={['artist-following', user?.id]}
              fetchFollowing={() => getMyFollowing()}
              enabled={Boolean(profile?.slug)}
            />
          </div>
        </section>
      </main>
    </div>
  )
}
