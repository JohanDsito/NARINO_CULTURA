import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation } from '@tanstack/react-query'
import { AxiosError } from 'axios'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { eventsApi, type CreateEventPayload } from '@/api/events.api'
import { X } from 'lucide-react'

const eventFormSchema = z.object({
  title: z.string().min(3, 'El título debe tener al menos 3 caracteres'),
  description: z.string().min(10, 'La descripción debe tener al menos 10 caracteres'),
  event_type: z.enum(['CONCIERTO', 'EXPOSICION', 'TALLER', 'FERIA', 'ESPECTACULO', 'OTRO']),
  start_date: z.string().min(1, 'Selecciona la fecha y hora de inicio'),
  end_date: z.string().min(1, 'Selecciona la fecha y hora de fin'),
  location: z.string().min(3, 'La ubicación debe tener al menos 3 caracteres'),
  image_url: z.string().url().optional().or(z.literal('')),
})

type EventFormData = z.infer<typeof eventFormSchema>

interface EventFormModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess?: () => void
}

export function EventFormModal({ open, onOpenChange, onSuccess }: EventFormModalProps) {
  const [isSubmitting, setIsSubmitting] = useState(false)
  
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<EventFormData>({
    resolver: zodResolver(eventFormSchema),
  })

  const mutation = useMutation({
    mutationFn: (data: EventFormData) => {
      const payload: CreateEventPayload = {
        ...data,
        start_date: new Date(data.start_date).toISOString(),
        end_date: new Date(data.end_date).toISOString(),
        is_published: true,
      }
      return eventsApi.createEvent(payload)
    },
    onSuccess: () => {
      toast.success('Evento creado exitosamente')
      reset()
      onOpenChange(false)
      onSuccess?.()
    },
    onError: (error: AxiosError<{ detail?: string }>) => {
      const message = error.response?.data?.detail ?? 'Error al crear el evento'
      toast.error(message)
    },
  })

  const onSubmit = async (data: EventFormData) => {
    setIsSubmitting(true)
    try {
      await mutation.mutateAsync(data)
    } finally {
      setIsSubmitting(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Crear nuevo evento</CardTitle>
          <button
            onClick={() => onOpenChange(false)}
            className="text-muted-foreground hover:text-foreground"
          >
            <X className="h-5 w-5" />
          </button>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {/* Título */}
            <div className="space-y-2">
              <Label htmlFor="title">Título del evento</Label>
              <Input
                id="title"
                placeholder="Ej: Concierto de música tradicional"
                {...register('title')}
                disabled={isSubmitting}
              />
              {errors.title && (
                <p className="text-sm text-destructive">{errors.title.message}</p>
              )}
            </div>

            {/* Descripción */}
            <div className="space-y-2">
              <Label htmlFor="description">Descripción</Label>
              <Textarea
                id="description"
                placeholder="Describe el evento en detalle..."
                rows={4}
                disabled={isSubmitting}
                {...register('description')}
              />
              {errors.description && (
                <p className="text-sm text-destructive">{errors.description.message}</p>
              )}
            </div>

            {/* Tipo de evento */}
            <div className="space-y-2">
              <Label htmlFor="event_type">Tipo de evento</Label>
              <select
                id="event_type"
                className="w-full px-3 py-2 border rounded-md bg-bg-subtle dark:bg-bg-subtle border-border dark:border-border"
                disabled={isSubmitting}
                {...register('event_type')}
              >
                <option value="">Selecciona un tipo</option>
                <option value="CONCIERTO">Concierto</option>
                <option value="EXPOSICION">Exposición</option>
                <option value="TALLER">Taller</option>
                <option value="FERIA">Feria</option>
                <option value="ESPECTACULO">Espectáculo</option>
                <option value="OTRO">Otro</option>
              </select>
              {errors.event_type && (
                <p className="text-sm text-destructive">{errors.event_type.message}</p>
              )}
            </div>

            {/* Ubicación */}
            <div className="space-y-2">
              <Label htmlFor="location">Ubicación</Label>
              <Input
                id="location"
                placeholder="Ej: Centro Cultural de Pasto"
                {...register('location')}
                disabled={isSubmitting}
              />
              {errors.location && (
                <p className="text-sm text-destructive">{errors.location.message}</p>
              )}
            </div>

            {/* Fecha y hora de inicio */}
            <div className="space-y-2">
              <Label htmlFor="start_date">Fecha y hora de inicio</Label>
              <Input
                id="start_date"
                type="datetime-local"
                {...register('start_date')}
                disabled={isSubmitting}
              />
              {errors.start_date && (
                <p className="text-sm text-destructive">{errors.start_date.message}</p>
              )}
            </div>

            {/* Fecha y hora de fin */}
            <div className="space-y-2">
              <Label htmlFor="end_date">Fecha y hora de fin</Label>
              <Input
                id="end_date"
                type="datetime-local"
                {...register('end_date')}
                disabled={isSubmitting}
              />
              {errors.end_date && (
                <p className="text-sm text-destructive">{errors.end_date.message}</p>
              )}
            </div>

            {/* URL de imagen (opcional) */}
            <div className="space-y-2">
              <Label htmlFor="image_url">URL de la imagen (opcional)</Label>
              <Input
                id="image_url"
                type="url"
                placeholder="https://ejemplo.com/imagen.jpg"
                {...register('image_url')}
                disabled={isSubmitting}
              />
              {errors.image_url && (
                <p className="text-sm text-destructive">{errors.image_url.message}</p>
              )}
            </div>

            {/* Botones */}
            <div className="flex gap-3 justify-end border-t pt-6">
              <Button
                type="button"
                variant="outline"
                onClick={() => onOpenChange(false)}
                disabled={isSubmitting}
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                disabled={isSubmitting || mutation.isPending}
              >
                {isSubmitting || mutation.isPending ? 'Creando...' : 'Crear evento'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
