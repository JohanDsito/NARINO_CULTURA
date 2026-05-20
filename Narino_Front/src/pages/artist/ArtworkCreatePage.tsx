import { Link, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft, ImagePlus, Save } from 'lucide-react'
import { toast } from 'sonner'

import { createArtwork } from '@/api/artworks.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { ARTWORK_CATEGORIES } from '@/constants/routes'
import { getApiErrorMessage } from '@/utils/apiError'

const currentYear = new Date().getFullYear()

const schema = z.object({
  title: z.string().min(1, 'El titulo es obligatorio.'),
  description: z.string().min(10, 'Describe la obra con al menos 10 caracteres.'),
  category: z.enum([
    'PINTURA',
    'ESCULTURA',
    'FOTOGRAFIA',
    'ARTESANIA',
    'TEXTIL',
    'CERAMICA',
    'GRABADO',
    'DIGITAL',
    'OTRO',
  ]),
  technique: z.string().min(1, 'La tecnica es obligatoria.'),
  price: z.coerce.number().positive('El precio debe ser mayor a 0.'),
  dimensions: z.string().optional(),
  year: z.coerce
    .number()
    .int('El año debe ser un numero entero.')
    .min(1000, 'Ingresa un año valido.')
    .max(currentYear, 'El año no puede ser futuro.')
    .optional()
    .or(z.literal('')),
  imageUrl: z.string().url('Debe ser una URL valida.').optional().or(z.literal('')),
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
      category: 'PINTURA',
      technique: '',
      price: 0,
      dimensions: '',
      year: '',
      imageUrl: '',
    },
    mode: 'onTouched',
  })

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      createArtwork({
        title: values.title.trim(),
        description: values.description.trim(),
        category: values.category,
        technique: values.technique.trim(),
        price: values.price,
        dimensions: values.dimensions?.trim() || undefined,
        year: values.year === '' ? undefined : values.year,
        image_url: values.imageUrl?.trim() || undefined,
      }),
    onSuccess: () => {
      toast.success('Obra creada correctamente.')
      navigate('/dashboard/profile')
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
              <ImagePlus size={18} />
              Datos de la obra
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form
              className="grid gap-4 md:grid-cols-2"
              onSubmit={handleSubmit((values) => mutation.mutate(values))}
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
                <Select id="category" {...register('category')}>
                  {ARTWORK_CATEGORIES.map((category) => (
                    <option key={category.value} value={category.value}>
                      {category.label}
                    </option>
                  ))}
                </Select>
                {errors.category ? <p className="text-xs text-destructive">{errors.category.message}</p> : null}
              </div>

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
                <Label htmlFor="year">Año</Label>
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
