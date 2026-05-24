import { useEffect, useMemo } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Camera, Music, Paintbrush, Scissors, Box } from 'lucide-react'

import { listArtistProfiles } from '@/api/artists.api'
import { getMyMusicianProfile } from '@/api/musicians.api'
import { Card, CardContent } from '@/components/ui/card'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { ROUTES } from '@/constants/routes'

const disciplines = [
  {
    key: 'artesano',
    label: 'Artesano',
    icon: Scissors,
    description: 'Trabajos en materiales tradicionales, tejidos y manualidades',
    href: ROUTES.DASHBOARD.PROFILE,
  },
  {
    key: 'fotografo',
    label: 'Fotógrafo',
    icon: Camera,
    description: 'Fotografía artística, retratos y documentación visual',
    href: ROUTES.DASHBOARD.PROFILE,
  },
  {
    key: 'escultor',
    label: 'Escultor',
    icon: Box,
    description: 'Esculturas, instalaciones y arte tridimensional',
    href: ROUTES.DASHBOARD.PROFILE,
  },
  {
    key: 'pintor',
    label: 'Pintor',
    icon: Paintbrush,
    description: 'Pinturas, acuarelas, óleos y técnicas mixtas',
    href: ROUTES.DASHBOARD.PROFILE,
  },
  {
    key: 'musico',
    label: 'Músico',
    icon: Music,
    description: 'Artistas musicales, bandas, DJs y colectivos',
    href: ROUTES.DASHBOARD.MUSICIAN.PROFILE,
  },
] as const

export default function ArtistRoleSelectPage() {
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)

  // Check for existing musician profile
  const musicianQuery = useQuery({
    queryKey: ['musician-profile', 'me'],
    queryFn: async () => {
      try {
        return await getMyMusicianProfile()
      } catch {
        return null
      }
    },
    retry: false,
    staleTime: 30_000,
  })

  // Check for existing artist profile
  const artistQuery = useQuery({
    queryKey: ['artist-profile', 'me'],
    queryFn: listArtistProfiles,
    staleTime: 30_000,
  })

  const musicianProfile = musicianQuery.data ?? null
  const artistProfile = useMemo(
    () => artistQuery.data?.find((p) => p.user_id === String(user?.id)) ?? null,
    [artistQuery.data, user?.id],
  )

  const isLoading = musicianQuery.isLoading || artistQuery.isLoading

  // If profile already exists, skip the selector and go straight to the dashboard
  useEffect(() => {
    if (isLoading) return
    if (musicianProfile) {
      navigate(ROUTES.DASHBOARD.MUSICIAN.PROFILE, { replace: true })
    } else if (artistProfile) {
      navigate(ROUTES.DASHBOARD.PROFILE, { replace: true })
    }
  }, [isLoading, musicianProfile, artistProfile, navigate])

  if (isLoading) {
    return <PageLoader label="Cargando panel..." />
  }

  // Only new users (no profile yet) reach this selector
  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-8 px-6 py-12 md:px-10">
        <section>
          <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
          <h1 className="text-3xl font-semibold tracking-tight text-foreground">
            ¿Cuál es tu perfil artístico?
          </h1>
          <p className="mt-2 text-muted-foreground">
            Selecciona tu disciplina para acceder a las herramientas de tu panel.
          </p>
        </section>

        <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          {disciplines.map(({ key, label, icon: Icon, description, href }) => (
            <Link key={key} to={href} className="focus-visible:outline-none">
              <Card className="h-full cursor-pointer transition-all duration-200 hover:border-primary hover:shadow-md hover:-translate-y-0.5">
                <CardContent className="flex flex-col gap-4 p-6">
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
                    <Icon size={22} className="text-primary" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-foreground">{label}</h3>
                    <p className="mt-1 text-sm text-muted-foreground leading-relaxed">
                      {description}
                    </p>
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      </main>
    </div>
  )
}
