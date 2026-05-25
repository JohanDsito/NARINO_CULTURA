import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Music, Plus, Trash2 } from 'lucide-react'
import { toast } from 'sonner'

import { deleteMusicalWork, listMyMusicalWorks } from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ROUTES } from '@/constants/routes'
import { MUSICAL_WORK_TYPE_LABELS } from '@/constants/routes'

export default function MusicianWorksPage() {
  const queryClient = useQueryClient()

  const { data: works = [], isLoading } = useQuery({
    queryKey: ['my-musical-works'],
    queryFn: listMyMusicalWorks,
  })

  const deleteMutation = useMutation({
    mutationFn: deleteMusicalWork,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['my-musical-works'] })
      toast.success('Obra eliminada.')
    },
    onError: () => toast.error('No se pudo eliminar la obra.'),
  })

  const handleDelete = (id: string, title: string) => {
    if (!window.confirm(`¿Eliminar "${title}"? Esta acción no se puede deshacer.`)) return
    deleteMutation.mutate(id)
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel del músico</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Mis obras musicales
            </h1>
          </div>
          <div className="flex items-center gap-3">
            <Button asChild variant="outline">
              <Link to={ROUTES.DASHBOARD.MUSICIAN.PROFILE}>← Volver al perfil</Link>
            </Button>
            <Button asChild>
              <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS_NEW} className="gap-2">
                <Plus size={16} />
                Añadir obra
              </Link>
            </Button>
          </div>
        </section>

        {isLoading && (
          <p className="text-sm text-muted-foreground">Cargando obras...</p>
        )}

        {!isLoading && works.length === 0 && (
          <Card>
            <CardContent className="flex flex-col items-center gap-4 py-12 text-center">
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-primary/10">
                <Music size={26} className="text-primary" />
              </div>
              <div>
                <p className="font-medium text-foreground">Aún no tienes obras</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  Añade tu primera canción, video o podcast.
                </p>
              </div>
              <Button asChild>
                <Link to={ROUTES.DASHBOARD.MUSICIAN.WORKS_NEW}>Añadir primera obra</Link>
              </Button>
            </CardContent>
          </Card>
        )}

        {works.length > 0 && (
          <div className="space-y-3">
            {works.map((work) => (
              <Card key={work.id}>
                <CardContent className="flex items-center gap-4 p-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 flex-none">
                    <Music size={18} className="text-primary" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-foreground line-clamp-1">{work.title}</p>
                    <div className="mt-1 flex items-center gap-2">
                      <Badge variant="secondary" className="text-xs">
                        {MUSICAL_WORK_TYPE_LABELS[work.work_type] ?? work.work_type}
                      </Badge>
                      {work.release_date && (
                        <span className="text-xs text-muted-foreground">
                          {work.release_date.slice(0, 4)}
                        </span>
                      )}
                      {work.is_featured && (
                        <Badge variant="outline" className="text-xs">
                          Destacada
                        </Badge>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-2 flex-none">
                    <span className="text-xs text-muted-foreground">
                      {work.views_count} visitas
                    </span>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-destructive hover:text-destructive"
                      onClick={() => handleDelete(work.id, work.title)}
                      disabled={deleteMutation.isPending}
                    >
                      <Trash2 size={15} />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
