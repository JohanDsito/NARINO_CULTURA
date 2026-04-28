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
        category: values.discipline?.trim() || undefined,
      })
    },
    onSuccess: (data) => {
      toast.success('Registro exitoso.', { description: data.message })
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
      className="space-y-3"
      onSubmit={handleSubmit((values) => mutation.mutate(values))}
      aria-label="Formulario de registro"
    >
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1">
          <Label htmlFor="firstName" className="text-xs font-medium">Nombre</Label>
          <Input id="firstName" autoComplete="given-name" {...register('firstName')} />
          {errors.firstName ? (
            <p className="text-xs text-destructive">{errors.firstName.message}</p>
          ) : null}
        </div>
        <div className="space-y-1">
          <Label htmlFor="lastName" className="text-xs font-medium">Apellido</Label>
          <Input id="lastName" autoComplete="family-name" {...register('lastName')} />
          {errors.lastName ? (
            <p className="text-xs text-destructive">{errors.lastName.message}</p>
          ) : null}
        </div>
      </div>

      <div className="space-y-1">
        <Label htmlFor="email" className="text-xs font-medium">Email</Label>
        <Input id="email" type="email" autoComplete="email" {...register('email')} />
        {errors.email ? <p className="text-xs text-destructive">{errors.email.message}</p> : null}
      </div>

      <div className="space-y-1">
        <Label htmlFor="password" className="text-xs font-medium">Contraseña</Label>
        <Input id="password" type="password" autoComplete="new-password" {...register('password')} />
        {errors.password ? (
          <p className="text-xs text-destructive">{errors.password.message}</p>
        ) : null}
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1">
          <Label htmlFor="role" className="text-xs font-medium">Tipo de usuario</Label>
          <Select id="role" {...register('role')} aria-label="Seleccionar tipo de usuario">
            <option value="buyer">Comprador</option>
            <option value="artist">Artista</option>
            <option value="cultural_manager">Gestor cultural</option>
          </Select>
          {errors.role ? <p className="text-xs text-destructive">{errors.role.message}</p> : null}
        </div>
        <div className="space-y-1">
          <Label htmlFor="phone" className="text-xs font-medium">Teléfono (opt.)</Label>
          <Input id="phone" autoComplete="tel" {...register('phone')} />
        </div>
      </div>

      {role === 'artist' ? (
        <div className="rounded-lg border border-tierra/20 bg-tierra-pale/20 p-3">
          <p className="mb-2 text-xs font-semibold text-tierra">Información de artista</p>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1 sm:col-span-2">
              <Label htmlFor="artisticName" className="text-xs font-medium">Nombre artístico*</Label>
              <Input id="artisticName" {...register('artisticName')} />
              {errors.artisticName ? (
                <p className="text-xs text-destructive">{errors.artisticName.message}</p>
              ) : null}
            </div>
            <div className="space-y-1">
              <Label htmlFor="discipline" className="text-xs font-medium">Categoría (opt.)</Label>
              <Input id="discipline" {...register('discipline')} />
            </div>
            <div className="space-y-1">
              <Label htmlFor="city" className="text-xs font-medium">Ciudad*</Label>
              <Input id="city" {...register('city')} />
              {errors.city ? (
                <p className="text-xs text-destructive">{errors.city.message}</p>
              ) : null}
            </div>
          </div>
        </div>
      ) : null}

      <Button type="submit" className="w-full mt-4" disabled={mutation.isPending} aria-label="Crear cuenta">
        {mutation.isPending ? 'Creando…' : 'Crear cuenta'}
      </Button>
    </form>
  )
}
