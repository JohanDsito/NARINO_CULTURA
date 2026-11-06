import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft, ImagePlus, Save } from 'lucide-react'
import { toast } from 'sonner'

import { createArtwork, getArtworkCategories } from '@/api/artworks.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { getApiErrorMessage } from '@/utils/apiError'

const schema = z.object({
  title: z.string().min(1, 'El título es obligatorio.'),
  description: z.string().min(10, 'Describe la obra con al menos 10 caracteres.'),
  category: z.string().optional(),
  technique: z.string().optional(),
  price: z.number().positive('El precio debe ser mayor a 0.').optional(),
  dimensions: z.string().optional(),
  material: z.string().optional(),
  main_image: z.custom<FileList>().optional(),
})

type FormValues = z.infer<typeof schema>

export default function ArtworkCreatePage() {
  const navigate = useNavigate()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: '',
      description: '',
      category: '',
      technique: '',
      price: undefined,
      dimensions: '',
      material: '',
    },
    mode: 'onTouched',
  })

  const { data: categories = [], isLoading: isLoadingCategories } = useQuery({
    queryKey: ['artwork-categories'],
    queryFn: getArtworkCategories,
  })

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      createArtwork({
        title: values.title.trim(),
        description: values.description.trim(),
        category: values.category ? Number(values.category) : undefined,
        technique: values.technique?.trim() || undefined,
        price: values.price,
        dimensions: values.dimensions?.trim() || undefined,
        material: values.material?.trim() || undefined,
        main_image: values.main_image?.[0],
      }),
    onSuccess: () => {
      toast.success('Obra creada correctamente.')
      navigate('/dashboard/artworks')
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error))
    },
  })

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-6 px-6 py-8 md:px-10">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">Nueva obra</h1>
          </div>
          <Button asChild variant="outline">
            <Link to="/dashboard/artworks" className="gap-2">
              <ArrowLeft size={16} />
              Volver
            </Link>
          </Button>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <ImagePlus size={18} />
              Datos de la obra
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form
              className="grid gap-4 md:grid-cols-2"
              onSubmit={handleSubmit((values) => mutation.mutate(values))}
            >
              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="title">Título *</Label>
                <Input id="title" {...register('title')} />
                {errors.title && <p className="text-xs text-destructive">{errors.title.message}</p>}
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="description">Descripción *</Label>
                <Textarea id="description" rows={5} {...register('description')} />
                {errors.description && (
                  <p className="text-xs text-destructive">{errors.description.message}</p>
                )}
              </div>

              <div className="space-y-1">
                <Label htmlFor="category">Categoría</Label>
                <Select id="category" {...register('category')} disabled={isLoadingCategories}>
                  <option value="">
                    {isLoadingCategories ? 'Cargando categorías...' : 'Sin categoría'}
                  </option>
                  {categories.map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                </Select>
              </div>

              <div className="space-y-1">
                <Label htmlFor="price">Precio (COP)</Label>
                <Input id="price" type="number" min="0" step="1000" {...register('price', { setValueAs: (v: string) => v === '' ? undefined : Number(v) })} />
                {errors.price && <p className="text-xs text-destructive">{errors.price.message}</p>}
              </div>

              <div className="space-y-1">
                <Label htmlFor="technique">Técnica</Label>
                <Input id="technique" placeholder="Ej: Óleo sobre lienzo" {...register('technique')} />
              </div>

              <div className="space-y-1">
                <Label htmlFor="dimensions">Dimensiones</Label>
                <Input id="dimensions" placeholder="Ej: 40 × 60 cm" {...register('dimensions')} />
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="material">Material</Label>
                <Input id="material" placeholder="Ej: Lienzo, madera" {...register('material')} />
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="main_image">Imagen principal</Label>
                <Input id="main_image" type="file" accept="image/*" {...register('main_image')} />
              </div>

              <div className="md:col-span-2">
                <Button type="submit" className="gap-2" disabled={mutation.isPending}>
                  <Save size={16} />
                  {mutation.isPending ? 'Guardando...' : 'Guardar obra'}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
