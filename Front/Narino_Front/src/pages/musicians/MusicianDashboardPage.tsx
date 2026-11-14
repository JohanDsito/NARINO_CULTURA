import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { CalendarPlus, Music } from 'lucide-react'
import { toast } from 'sonner'

import {
  getMusicianFollowers,
  getMyMusicianFollowing,
  getMyMusicianProfile,
  uploadMusicianProfileImage,
} from '@/api/musicians.api'
import { MusicianProfileForm } from '@/components/musician/musician-profile-form'
import { FollowStatsCard } from '@/components/profile/follow-stats-card'
import { ProfileImageUpload } from '@/components/profile/profile-image-upload'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { ROUTES } from '@/constants/routes'
import { useAuthStore } from '@/store/authStore'
import { getApiErrorMessage } from '@/utils/apiError'

export default function MusicianDashboardPage() {
  const user = useAuthStore((s) => s.user)
  const queryClient = useQueryClient()

  const profileQuery = useQuery({
    queryKey: ['musician-profile', 'me'],
    queryFn: () => getMyMusicianProfile(),
  })

  const profile = profileQuery.data ?? null

  const uploadImageMutation = useMutation({
    mutationFn: (file: File) => {
      if (!profile?.slug) throw new Error('Guarda el perfil antes de subir una foto.')
      return uploadMusicianProfileImage(profile.slug, file)
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['musician-profile', 'me'] })
      toast.success('Foto de perfil actualizada.')
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  return (
    <div className="min-h-screen bg-bg pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-text-secondary">Panel del músico</p>
            <h1 className="text-3xl font-semibold tracking-tight text-text-primary">
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
          {/* Left column: form + action cards */}
          <div className="flex flex-col gap-5">
          {profileQuery.isLoading ? (
            <Skeleton className="h-[560px] w-full rounded-card" />
          ) : (
            <MusicianProfileForm key={profile?.slug ?? 'nuevo'} profile={profile} user={user} />
          )}

          {/* Action cards below the form */}
          <div className="grid gap-5 sm:grid-cols-2">
            <Card className="flex flex-col">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <Music size={18} />
                  Obras musicales
                </CardTitle>
              </CardHeader>
              <CardContent className="flex flex-1 flex-col justify-between gap-4">
                <p className="text-sm text-text-secondary">
                  Administra tus obras publicadas, añade canciones, videos o podcasts.
                </p>
                <div className="grid gap-2">
                  <Button asChild variant="outline">
                    <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS}>Ver mis obras</Link>
                  </Button>
                  <Button asChild>
                    <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS_NEW}>Añadir obra</Link>
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
                  Publica conciertos o presentaciones. Será revisado por el administrador antes de
                  aparecer en el calendario.
                </p>
                <Button asChild className="w-full">
                  <Link to={ROUTES.DASHBOARD.EVENTS_NEW}>Crear evento</Link>
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
              followersQueryKey={['musician-followers', profile?.slug]}
              fetchFollowers={() => getMusicianFollowers(profile!.slug)}
              followingQueryKey={['musician-following', user?.id]}
              fetchFollowing={() => getMyMusicianFollowing()}
              enabled={Boolean(profile?.slug)}
            />
          </div>
        </section>
      </main>
    </div>
  )
}
