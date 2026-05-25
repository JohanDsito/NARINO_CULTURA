import { useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { getArtworkById, updateArtwork, deleteArtwork, getArtworkCategories } from '@/api/artworks.api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { PageShell } from '@/components/layout/page-shell'
import { PageLoader } from '@/components/layout/page-loader'
import { ROUTES } from '@/constants/routes'

const schema = z.object({
  title: z.string().min(1, 'El título es requerido'),
  description: z.string().min(10, 'La descripción debe tener al menos 10 caracteres'),
  category: z.string().optional(),
  price: z.number().positive('El precio debe ser positivo').optional(),
  technique: z.string().optional(),
  dimensions: z.string().optional(),
  material: z.string().optional(),
  main_image: z.custom<FileList>().optional(),
})

type FormData = z.infer<typeof schema>

export default function ArtworkEditPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  const { data: categories = [] } = useQuery({
    queryKey: ['artwork-categories'],
    queryFn: getArtworkCategories,
    staleTime: 60 * 60 * 1000,
  })

  const { data: artwork, isLoading } = useQuery({
    queryKey: ['artwork', id],
    queryFn: () => getArtworkById(id!),
    enabled: Boolean(id),
  })

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isDirty },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  useEffect(() => {
    if (artwork) {
      reset({
        title: artwork.title,
        description: artwork.description,
        category: artwork.category ? String(artwork.category) : '',
        price: parseFloat(artwork.price),
        technique: artwork.technique,
        dimensions: artwork.dimensions,
        material: artwork.material,
      })
    }
  }, [artwork, reset])

  const updateMutation = useMutation({
    mutationFn: (data: FormData) =>
      updateArtwork(id!, {
        ...data,
        category: data.category ? Number(data.category) : undefined,
        main_image: data.main_image?.[0],
      }),
    onSuccess: () => {
      toast.success('Obra actualizada correctamente')
      navigate(ROUTES.DASHBOARD.ARTWORKS)
    },
    onError: () => toast.error('No se pudo actualizar la obra.'),
  })

  const deleteMutation = useMutation({
    mutationFn: () => deleteArtwork(id!),
    onSuccess: () => {
      toast.success('Obra eliminada')
      navigate(ROUTES.DASHBOARD.ARTWORKS)
    },
    onError: () => toast.error('No se pudo eliminar la obra.'),
  })

  const handleDelete = () => {
    if (window.confirm('¿Estás seguro de que deseas eliminar esta obra? Esta acción no se puede deshacer.')) {
      deleteMutation.mutate()
    }
  }

  if (isLoading) return <PageLoader label="Cargando obra…" />

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Editar obra"
        subtitle={artwork?.title ?? ''}
      />

      <main className="mx-auto max-w-2xl px-6 py-8">
        <form onSubmit={handleSubmit((data) => updateMutation.mutate(data))} className="space-y-5">
          <div className="space-y-1.5">
            <Label htmlFor="title">Título *</Label>
            <Input id="title" {...register('title')} />
            {errors.title && <p className="font-body text-[12px] text-error">{errors.title.message}</p>}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="description">Descripción *</Label>
            <Textarea id="description" rows={4} {...register('description')} />
            {errors.description && <p className="font-body text-[12px] text-error">{errors.description.message}</p>}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="category">Categoría</Label>
              <select
                id="category"
                {...register('category')}
                className="w-full rounded-input border border-border bg-surface px-3 py-2 font-body text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-oro/50"
              >
                <option value="">Sin categoría</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>{cat.name}</option>
                ))}
              </select>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="price">Precio (COP)</Label>
              <Input id="price" type="number" min={0} step={1000} {...register('price', { setValueAs: (v: string) => v === '' ? undefined : Number(v) })} />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="technique">Técnica</Label>
              <Input id="technique" placeholder="Ej: Óleo sobre lienzo" {...register('technique')} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="dimensions">Dimensiones</Label>
              <Input id="dimensions" placeholder="Ej: 40x60 cm" {...register('dimensions')} />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="material">Material</Label>
            <Input id="material" placeholder="Ej: Lienzo, madera" {...register('material')} />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="main_image">Cambiar imagen principal</Label>
            <Input id="main_image" type="file" accept="image/*" {...register('main_image')} />
          </div>

          <div className="flex gap-3 pt-2">
            <Button
              type="submit"
              variant="primary"
              className="flex-1"
              disabled={!isDirty || updateMutation.isPending}
            >
              {updateMutation.isPending ? 'Guardando…' : 'Guardar cambios'}
            </Button>
            <Button
              type="button"
              variant="secondary"
              className="text-error border-error/30 hover:bg-error/5"
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
            >
              {deleteMutation.isPending ? 'Eliminando…' : 'Eliminar obra'}
            </Button>
          </div>
        </form>
      </main>
    </div>
  )
}
