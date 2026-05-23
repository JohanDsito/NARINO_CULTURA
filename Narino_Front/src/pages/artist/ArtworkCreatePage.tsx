import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm, useWatch } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft, ImagePlus, Music, Save, Upload } from 'lucide-react'
import { toast } from 'sonner'

import { createArtwork, getArtworkCategories } from '@/api/artworks.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { getApiErrorMessage } from '@/utils/apiError'

const currentYear = new Date().getFullYear()

const schema = z.object({
  title: z.string().min(1, 'El titulo es obligatorio.'),
  description: z.string().min(10, 'Describe la obra con al menos 10 caracteres.'),
  category: z.string().min(1, 'Selecciona una categoria.'),
  technique: z.string().optional(),
  price: z.coerce.number().positive('El precio debe ser mayor a 0.').optional().or(z.literal('')),
  dimensions: z.string().optional(),
  year: z.coerce
    .number()
    .int('El ano debe ser un numero entero.')
    .min(1000, 'Ingresa un ano valido.')
    .max(currentYear, 'El ano no puede ser futuro.')
    .optional()
    .or(z.literal('')),
  imageUrl: z.string().url('Debe ser una URL valida.').optional().or(z.literal('')),
  releaseDate: z.string().optional(),
  composer: z.string().optional(),
  genre: z.string().optional(),
  demo: z
    .custom<FileList>()
    .optional()
    .refine((files) => !files?.length || files[0]?.type === 'audio/mpeg', 'El demo debe ser un archivo MP3.'),
})

type FormValues = z.infer<typeof schema>

function isMusicCategoryName(value: string) {
  const normalized = value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()

  return normalized.includes('music')
}

export default function ArtworkCreatePage() {
  const navigate = useNavigate()

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: '',
      description: '',
      category: '',
      technique: '',
      price: '',
      dimensions: '',
      year: '',
      imageUrl: '',
      releaseDate: '',
      composer: '',
      genre: '',
      demo: undefined,
    },
    mode: 'onTouched',
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = form

  const { data: categories = [], isLoading: isLoadingCategories } = useQuery({
    queryKey: ['artwork-categories'],
    queryFn: getArtworkCategories,
  })

  const categoryId = useWatch({ control: form.control, name: 'category' })
  const selectedCategory = categories.find((category) => String(category.id) === categoryId)
  const selectedCategoryText = `${selectedCategory?.name ?? ''} ${selectedCategory?.slug ?? ''}`
  const isMusicCategory = isMusicCategoryName(selectedCategoryText)
  const demoFile = useWatch({ control: form.control, name: 'demo' })?.[0]

  const mutation = useMutation({
    mutationFn: (values: FormValues) => {
      const category = Number(values.category)

      if (isMusicCategory) {
        return createArtwork({
          title: values.title.trim(),
          description: values.description.trim(),
          category,
          release_date: values.releaseDate || undefined,
          composer: values.composer?.trim() || undefined,
          genre: values.genre?.trim() || undefined,
          demo: values.demo?.[0],
        })
      }

      return createArtwork({
        title: values.title.trim(),
        description: values.description.trim(),
        category,
        technique: values.technique?.trim() || undefined,
        price: values.price === '' ? undefined : values.price,
        dimensions: values.dimensions?.trim() || undefined,
        year: values.year === '' ? undefined : values.year,
        image_url: values.imageUrl?.trim() || undefined,
      })
    },
    onSuccess: () => {
      toast.success('Obra creada correctamente.')
      navigate('/dashboard/profile')
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error))
    },
  })

  const onSubmit = (values: FormValues) => {
    if (isMusicCategory) {
      let hasError = false

      if (!values.releaseDate) {
        form.setError('releaseDate', { message: 'La fecha de lanzamiento es obligatoria.' })
        hasError = true
      }
      if (!values.composer?.trim()) {
        form.setError('composer', { message: 'El compositor es obligatorio.' })
        hasError = true
      }
      if (!values.genre?.trim()) {
        form.setError('genre', { message: 'El genero es obligatorio.' })
        hasError = true
      }
      if (!values.demo?.length) {
        form.setError('demo', { message: 'Debes subir un demo en MP3.' })
        hasError = true
      }

      if (hasError) return
    } else {
      let hasError = false

      if (!values.technique?.trim()) {
        form.setError('technique', { message: 'La tecnica es obligatoria.' })
        hasError = true
      }
      if (values.price === '') {
        form.setError('price', { message: 'El precio es obligatorio.' })
        hasError = true
      }

      if (hasError) return
    }

    mutation.mutate(values)
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-6 px-6 py-8 md:px-10">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Nueva obra
            </h1>
          </div>
          <Button asChild variant="outline">
            <Link to="/dashboard/profile" className="gap-2">
              <ArrowLeft size={16} />
              Volver al panel
            </Link>
          </Button>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              {isMusicCategory ? <Music size={18} /> : <ImagePlus size={18} />}
              {isMusicCategory ? 'Datos de la musica' : 'Datos de la obra'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form
              className="grid gap-4 md:grid-cols-2"
              onSubmit={handleSubmit(onSubmit)}
              aria-label="Formulario de nueva obra"
            >
              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="title">Titulo</Label>
                <Input id="title" {...register('title')} />
                {errors.title ? <p className="text-xs text-destructive">{errors.title.message}</p> : null}
              </div>

              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="description">Descripcion</Label>
                <Textarea id="description" rows={5} {...register('description')} />
                {errors.description ? (
                  <p className="text-xs text-destructive">{errors.description.message}</p>
                ) : null}
              </div>

              <div className="space-y-1">
                <Label htmlFor="category">Categoria</Label>
                <Select id="category" {...register('category')} disabled={isLoadingCategories}>
                  <option value="">
                    {isLoadingCategories ? 'Cargando categorias...' : 'Selecciona una categoria'}
                  </option>
                  {categories.map((category) => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </Select>
                {errors.category ? <p className="text-xs text-destructive">{errors.category.message}</p> : null}
              </div>

              {isMusicCategory ? (
                <>
                  <div className="space-y-1">
                    <Label htmlFor="releaseDate">Fecha de lanzamiento</Label>
                    <Input id="releaseDate" type="date" {...register('releaseDate')} />
                    {errors.releaseDate ? (
                      <p className="text-xs text-destructive">{errors.releaseDate.message}</p>
                    ) : null}
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="composer">Compositor</Label>
                    <Input id="composer" {...register('composer')} />
                    {errors.composer ? (
                      <p className="text-xs text-destructive">{errors.composer.message}</p>
                    ) : null}
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="genre">Genero</Label>
                    <Input id="genre" {...register('genre')} />
                    {errors.genre ? <p className="text-xs text-destructive">{errors.genre.message}</p> : null}
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="demo">Subir demo MP3</Label>
                    <label className="flex min-h-10 cursor-pointer items-center justify-between gap-3 rounded-md border border-input bg-background px-3 py-2 text-sm text-muted-foreground transition-colors hover:border-tierra">
                      <span className="flex min-w-0 items-center gap-2">
                        <Upload size={16} />
                        <span className="truncate">
                          {demoFile?.name ?? 'Seleccionar archivo desde el equipo'}
                        </span>
                      </span>
                      <Input id="demo" type="file" accept="audio/mpeg,.mp3" className="sr-only" {...register('demo')} />
                    </label>
                    {errors.demo ? <p className="text-xs text-destructive">{errors.demo.message}</p> : null}
                  </div>
                </>
              ) : (
                <>
                  <div className="space-y-1">
                    <Label htmlFor="technique">Tecnica</Label>
                    <Input id="technique" {...register('technique')} />
                    {errors.technique ? (
                      <p className="text-xs text-destructive">{errors.technique.message}</p>
                    ) : null}
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="price">Precio</Label>
                    <Input id="price" type="number" min="0" step="1000" {...register('price')} />
                    {errors.price ? <p className="text-xs text-destructive">{errors.price.message}</p> : null}
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="year">Ano</Label>
                    <Input id="year" type="number" min="1000" max={currentYear} {...register('year')} />
                    {errors.year ? <p className="text-xs text-destructive">{errors.year.message}</p> : null}
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="dimensions">Dimensiones</Label>
                    <Input id="dimensions" placeholder="40 x 60 cm" {...register('dimensions')} />
                  </div>

                  <div className="space-y-1">
                    <Label htmlFor="imageUrl">URL de imagen (opcional)</Label>
                    <Input id="imageUrl" type="url" {...register('imageUrl')} />
                    {errors.imageUrl ? (
                      <p className="text-xs text-destructive">{errors.imageUrl.message}</p>
                    ) : null}
                  </div>
                </>
              )}

              <div className="md:col-span-2">
                <Button type="submit" className="gap-2" disabled={mutation.isPending || isLoadingCategories}>
                  {isMusicCategory ? <Music size={16} /> : <Save size={16} />}
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
