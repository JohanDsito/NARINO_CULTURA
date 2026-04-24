import { useLocation, useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'

import { login, me } from '@/api/auth.api'
import { createArtistProfile } from '@/api/artists.api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/store/authStore'
import { getApiErrorMessage } from '@/utils/apiError'
import {
  clearPendingArtistProfile,
  getPendingArtistProfile,
} from '@/utils/pendingArtistProfile'

const schema = z.object({
  email: z.string().email('Ingresa un email válido.'),
  password: z.string().min(1, 'La contraseña es obligatoria.'),
})

type FormValues = z.infer<typeof schema>

function getRedirectPathByRole(role: string) {
  switch (role) {
    case 'admin':
      return '/admin/dashboard'
    case 'artist':
      return '/dashboard/profile'
    case 'cultural_manager':
      return '/events'
    case 'buyer':
    default:
      return '/'
  }
}

export function LoginForm() {
  const queryClient = useQueryClient()
  const navigate = useNavigate()
  const location = useLocation()

  const setTokens = useAuthStore((s) => s.setTokens)
  const setUser = useAuthStore((s) => s.setUser)

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '' },
    mode: 'onTouched',
  })

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => {
      const tokens = await login(values)
      setTokens(tokens)
      const user = await queryClient.fetchQuery({
        queryKey: ['auth', 'me'],
        queryFn: me,
      })
      setUser(user)
      const pendingArtist = getPendingArtistProfile()
      if (user.role === 'artist' && pendingArtist) {
        try {
          await createArtistProfile(pendingArtist)
          toast.success('Perfil de artista creado.')
        } catch {
          toast.message('Perfil de artista', {
            description: 'No fue posible crear el perfil automáticamente. Puedes completarlo luego.',
          })
        } finally {
          clearPendingArtistProfile()
        }
      }
      return user
    },
    onSuccess: (user) => {
      toast.success('Bienvenido/a.')
      const from = (location.state as { from?: string } | null)?.from
      navigate(from ?? getRedirectPathByRole(user.role), { replace: true })
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
      aria-label="Formulario de inicio de sesión"
    >
      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" autoComplete="email" {...register('email')} />
        {errors.email ? <p className="text-sm text-destructive">{errors.email.message}</p> : null}
      </div>

      <div className="space-y-2">
        <Label htmlFor="password">Contraseña</Label>
        <Input
          id="password"
          type="password"
          autoComplete="current-password"
          {...register('password')}
        />
        {errors.password ? (
          <p className="text-sm text-destructive">{errors.password.message}</p>
        ) : null}
      </div>

      <Button type="submit" className="w-full" disabled={mutation.isPending} aria-label="Ingresar">
        {mutation.isPending ? 'Ingresando…' : 'Ingresar'}
      </Button>
    </form>
  )
}

