import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useForm, useWatch } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'

import { register as registerApi } from '@/api/auth.api'
import type { Role } from '@/types/auth'
import { mapRoleToBackendRole } from '@/types/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { getApiErrorMessage } from '@/utils/apiError'
import { setPendingArtistProfile } from '@/utils/pendingArtistProfile'

const schema = z
  .object({
    email: z.string().email('Ingresa un email válido.'),
    password: z.string().min(8, 'Mínimo 8 caracteres.'),
    firstName: z.string().min(1, 'El nombre es obligatorio.'),
    lastName: z.string().min(1, 'El apellido es obligatorio.'),
    role: z.enum(['buyer', 'artist', 'cultural_manager'] as const satisfies readonly Role[], {
      message: 'Selecciona un tipo de usuario.',
    }),
    phone: z.string().optional(),
    avatarUrl: z.string().url('Debe ser una URL válida.').optional().or(z.literal('')),
    artisticName: z.string().optional(),
    discipline: z.string().optional(),
    city: z.string().optional(),
  })
  .superRefine((values, ctx) => {
    if (values.role === 'artist') {
      if (!values.artisticName?.trim()) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'El nombre artístico es obligatorio.',
          path: ['artisticName'],
        })
      }
      if (!values.city?.trim()) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'La ciudad es obligatoria.',
          path: ['city'],
        })
      }
    }
  })

type FormValues = z.infer<typeof schema>

export function RegisterForm() {
  const navigate = useNavigate()

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      email: '',
      password: '',
      firstName: '',
      lastName: '',
      role: 'buyer',
      phone: '',
      avatarUrl: '',
      artisticName: '',
      discipline: '',
      city: '',
    },
    mode: 'onTouched',
  })

  const role = useWatch({ control: form.control, name: 'role' })

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => {
      if (values.role === 'artist') {
        const artistic_name = values.artisticName?.trim() ?? ''
        const discipline = values.discipline?.trim() || undefined
        const city = values.city?.trim() || undefined
        if (artistic_name) setPendingArtistProfile({ artistic_name, discipline, city })
      }

      return await registerApi({
        email: values.email,
        password: values.password,
        first_name: values.firstName,
        last_name: values.lastName,
        role: mapRoleToBackendRole(values.role),
        phone: values.phone?.trim() || undefined,
        avatar_url: values.avatarUrl?.trim() || undefined,
      })
    },
    onSuccess: (data) => {
      toast.success('Registro exitoso.', { description: data.detail })
      navigate('/login', { replace: true })
    },
    onError: (err) => {
      toast.error(getApiErrorMessage(err))
    },
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = form

  return (
    <form
      className="space-y-4"
      onSubmit={handleSubmit((values) => mutation.mutate(values))}
      aria-label="Formulario de registro"
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="firstName">Nombre</Label>
          <Input id="firstName" autoComplete="given-name" {...register('firstName')} />
          {errors.firstName ? (
            <p className="text-sm text-destructive">{errors.firstName.message}</p>
          ) : null}
        </div>
        <div className="space-y-2">
          <Label htmlFor="lastName">Apellido</Label>
          <Input id="lastName" autoComplete="family-name" {...register('lastName')} />
          {errors.lastName ? (
            <p className="text-sm text-destructive">{errors.lastName.message}</p>
          ) : null}
        </div>
      </div>

      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" autoComplete="email" {...register('email')} />
        {errors.email ? <p className="text-sm text-destructive">{errors.email.message}</p> : null}
      </div>

      <div className="space-y-2">
        <Label htmlFor="password">Contraseña</Label>
        <Input id="password" type="password" autoComplete="new-password" {...register('password')} />
        {errors.password ? (
          <p className="text-sm text-destructive">{errors.password.message}</p>
        ) : null}
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="role">Tipo de usuario</Label>
          <Select id="role" {...register('role')} aria-label="Seleccionar tipo de usuario">
            <option value="buyer">Comprador</option>
            <option value="artist">Artista</option>
            <option value="cultural_manager">Gestor cultural</option>
          </Select>
          {errors.role ? <p className="text-sm text-destructive">{errors.role.message}</p> : null}
        </div>
        <div className="space-y-2">
          <Label htmlFor="phone">Teléfono (opcional)</Label>
          <Input id="phone" autoComplete="tel" {...register('phone')} />
        </div>
      </div>

      {role === 'artist' ? (
        <div className="rounded-lg border bg-muted/30 p-4">
          <p className="mb-3 text-sm font-medium">Información de artista</p>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="artisticName">Nombre artístico</Label>
              <Input id="artisticName" {...register('artisticName')} />
              {errors.artisticName ? (
                <p className="text-sm text-destructive">{errors.artisticName.message}</p>
              ) : null}
            </div>
            <div className="space-y-2">
              <Label htmlFor="discipline">Categoría / disciplina (opcional)</Label>
              <Input id="discipline" {...register('discipline')} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="city">Ciudad</Label>
              <Input id="city" {...register('city')} />
              {errors.city ? (
                <p className="text-sm text-destructive">{errors.city.message}</p>
              ) : null}
            </div>
          </div>
        </div>
      ) : null}

      <Button type="submit" className="w-full" disabled={mutation.isPending} aria-label="Crear cuenta">
        {mutation.isPending ? 'Creando cuenta…' : 'Crear cuenta'}
      </Button>
    </form>
  )
}
