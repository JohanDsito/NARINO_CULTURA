import { useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { ArrowLeft, CalendarPlus, ImagePlus, Save, X, Link2 } from 'lucide-react'
import { toast } from 'sonner'

import { eventsApi } from '@/api/events.api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { getApiErrorMessage } from '@/utils/apiError'
import { EVENT_TYPES } from '@/constants/routes'
import { getArtistDiscipline } from '@/utils/artistDiscipline'
import { useAuthStore } from '@/store/authStore'

const schema = z.object({
  title: z.string().min(1, 'El nombre del evento es obligatorio.'),
  event_type: z.string().min(1, 'Selecciona un tipo de evento.'),
  location: z.string().min(1, 'El lugar es obligatorio.'),
  start_date: z.string().min(1, 'La fecha es obligatoria.'),
  end_date: z.string().optional(),
  description: z.string().optional(),
  ticket_url: z.string().url('Ingresa una URL válida.').optional().or(z.literal('')),
})

type FormValues = z.infer<typeof schema>

export default function ArtistEventCreatePage() {
  const navigate = useNavigate()
  const userId = useAuthStore((s) => s.user?.id ?? '')
  const discipline = getArtistDiscipline(userId)
  const backPath = discipline === 'musico' ? '/dashboard/musician/profile' : '/dashboard/profile'

  const [flyerFile, setFlyerFile] = useState<File | null>(null)
  const [flyerPreview, setFlyerPreview] = useState<string | null>(null)
  const [flyerTab, setFlyerTab] = useState<'url' | 'file'>('url')
  const [flyerUrl, setFlyerUrl] = useState('')
  const fileInputRef = useRef<HTMLInputElement>(null)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: '',
      event_type: '',
      location: '',
      start_date: '',
      end_date: '',
      description: '',
      ticket_url: '',
    },
    mode: 'onTouched',
  })

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      eventsApi.createArtistEvent({
        title: values.title.trim(),
        event_type: values.event_type,
        location: values.location.trim(),
        start_date: values.start_date,
        end_date: values.end_date || values.start_date,
        description: values.description?.trim() || '',
        ticket_url: values.ticket_url?.trim() || undefined,
        flyer: flyerTab === 'file' ? (flyerFile ?? undefined) : undefined,
        image_url: flyerTab === 'url' && flyerUrl.trim() ? flyerUrl.trim() : undefined,
        is_published: false,
      }),
    onSuccess: () => {
      toast.success('Evento enviado para aprobación', {
        description:
          'Tu evento fue recibido correctamente. El administrador lo revisará antes de publicarlo en el calendario.',
        duration: 6000,
      })
      navigate(backPath)
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error))
    },
  })

  const handleFlyerChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setFlyerFile(file)
    setFlyerPreview(URL.createObjectURL(file))
  }

  const removeFlyerFile = () => {
    setFlyerFile(null)
    setFlyerPreview(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Crear evento
            </h1>
          </div>
          <Button asChild variant="outline">
            <Link to={backPath} className="gap-2">
              <ArrowLeft size={16} />
              Volver
            </Link>
          </Button>
        </section>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <CalendarPlus size={18} />
              Información del evento
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form
              className="grid gap-4 md:grid-cols-2"
              onSubmit={handleSubmit((values) => mutation.mutate(values))}
            >
              {/* Nombre */}
              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="title">Nombre del evento *</Label>
                <Input id="title" placeholder="Ej: Concierto de música andina" {...register('title')} />
                {errors.title && <p className="text-xs text-destructive">{errors.title.message}</p>}
              </div>

              {/* Tipo */}
              <div className="space-y-1">
                <Label htmlFor="event_type">Tipo de evento *</Label>
                <Select id="event_type" {...register('event_type')}>
                  <option value="">Selecciona un tipo</option>
                  {EVENT_TYPES.map((t) => (
                    <option key={t.value} value={t.value}>
                      {t.label}
                    </option>
                  ))}
                </Select>
                {errors.event_type && (
                  <p className="text-xs text-destructive">{errors.event_type.message}</p>
                )}
              </div>

              {/* Lugar */}
              <div className="space-y-1">
                <Label htmlFor="location">Lugar *</Label>
                <Input id="location" placeholder="Ej: Teatro Imperial, Pasto" {...register('location')} />
                {errors.location && (
                  <p className="text-xs text-destructive">{errors.location.message}</p>
                )}
              </div>

              {/* Fecha inicio */}
              <div className="space-y-1">
                <Label htmlFor="start_date">Fecha y hora de inicio *</Label>
                <Input id="start_date" type="datetime-local" {...register('start_date')} />
                {errors.start_date && (
                  <p className="text-xs text-destructive">{errors.start_date.message}</p>
                )}
              </div>

              {/* Fecha fin */}
              <div className="space-y-1">
                <Label htmlFor="end_date">Fecha y hora de fin</Label>
                <Input id="end_date" type="datetime-local" {...register('end_date')} />
              </div>

              {/* Descripción */}
              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="description">Descripción</Label>
                <Textarea
                  id="description"
                  rows={4}
                  placeholder="Cuéntanos sobre tu evento..."
                  {...register('description')}
                />
              </div>

              {/* Link de entradas */}
              <div className="space-y-1 md:col-span-2">
                <Label htmlFor="ticket_url">
                  Link de compra de entradas{' '}
                  <span className="text-muted-foreground font-normal">(opcional)</span>
                </Label>
                <Input
                  id="ticket_url"
                  type="url"
                  placeholder="https://tuboleta.com/..."
                  {...register('ticket_url')}
                />
                {errors.ticket_url && (
                  <p className="text-xs text-destructive">{errors.ticket_url.message}</p>
                )}
              </div>

              {/* Flyer */}
              <div className="space-y-2 md:col-span-2">
                <Label>
                  Flyer promocional{' '}
                  <span className="text-muted-foreground font-normal">(opcional)</span>
                </Label>

                {/* Pestañas URL / Archivo */}
                <div className="flex gap-1 rounded-lg border border-border bg-muted/40 p-1 w-fit">
                  <button
                    type="button"
                    onClick={() => setFlyerTab('url')}
                    className={[
                      'flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-colors',
                      flyerTab === 'url'
                        ? 'bg-background text-foreground shadow-sm'
                        : 'text-muted-foreground hover:text-foreground',
                    ].join(' ')}
                  >
                    <Link2 size={12} /> URL de imagen
                  </button>
                  <button
                    type="button"
                    onClick={() => setFlyerTab('file')}
                    className={[
                      'flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-colors',
                      flyerTab === 'file'
                        ? 'bg-background text-foreground shadow-sm'
                        : 'text-muted-foreground hover:text-foreground',
                    ].join(' ')}
                  >
                    <ImagePlus size={12} /> Subir archivo
                  </button>
                </div>

                {flyerTab === 'url' ? (
                  <div className="space-y-2">
                    <Input
                      type="url"
                      placeholder="https://drive.google.com/... o enlace directo a la imagen"
                      value={flyerUrl}
                      onChange={(e) => setFlyerUrl(e.target.value)}
                    />
                    {flyerUrl && (
                      <div className="relative w-full max-w-xs">
                        <img
                          src={flyerUrl}
                          alt="Vista previa"
                          className="w-full rounded-lg border border-border object-cover"
                          style={{ maxHeight: '200px' }}
                          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                        />
                      </div>
                    )}
                  </div>
                ) : (
                  <>
                    {flyerPreview ? (
                      <div className="relative w-full max-w-xs">
                        <img
                          src={flyerPreview}
                          alt="Vista previa del flyer"
                          className="w-full rounded-lg border border-border object-cover"
                          style={{ maxHeight: '240px' }}
                        />
                        <button
                          type="button"
                          onClick={removeFlyerFile}
                          className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-destructive text-white hover:bg-destructive/80"
                        >
                          <X size={12} />
                        </button>
                        <p className="mt-1 text-xs text-muted-foreground truncate">{flyerFile?.name}</p>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        className="flex w-full cursor-pointer flex-col items-center gap-2 rounded-lg border-2 border-dashed border-border px-6 py-8 text-center transition-colors hover:border-primary hover:bg-primary/5"
                      >
                        <ImagePlus size={28} className="text-muted-foreground" />
                        <span className="text-sm font-medium text-foreground">
                          Subir flyer desde tu computador
                        </span>
                        <span className="text-xs text-muted-foreground">
                          PNG, JPG o WEBP · máx. 5 MB
                        </span>
                      </button>
                    )}
                    <p className="text-xs text-amber-600 dark:text-amber-400">
                      ⚠ La subida de archivos requiere activación en el servidor. Usa la opción URL mientras tanto.
                    </p>
                  </>
                )}

                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={handleFlyerChange}
                />
              </div>

              {/* Aviso de aprobación */}
              <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 md:col-span-2 dark:border-amber-900 dark:bg-amber-950/30 dark:text-amber-300">
                <strong>Nota:</strong> Tu evento será revisado por un administrador antes de
                aparecer en el calendario público. Recibirás una notificación cuando sea aprobado.
              </div>

              {/* Botones */}
              <div className="flex items-center gap-3 md:col-span-2">
                <Button type="submit" className="gap-2" disabled={mutation.isPending}>
                  <Save size={16} />
                  {mutation.isPending ? 'Enviando...' : 'Enviar evento'}
                </Button>
                <Button asChild variant="outline">
                  <Link to={backPath}>Cancelar</Link>
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
