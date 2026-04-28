import { useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'

import { confirmPasswordReset } from '@/api/auth.api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getApiErrorMessage } from '@/utils/apiError'

const schema = z
  .object({
    token: z.string().min(10, 'El token es obligatorio.'),
    newPassword: z.string().min(8, 'Mínimo 8 caracteres.'),
    confirmPassword: z.string().min(8, 'Confirma tu contraseña.'),
  })
  .refine((v) => v.newPassword === v.confirmPassword, {
    message: 'Las contraseñas no coinciden.',
    path: ['confirmPassword'],
  })

type FormValues = z.infer<typeof schema>

export function ResetPasswordForm({ initialToken }: { initialToken?: string }) {
  const navigate = useNavigate()

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { token: initialToken ?? '', newPassword: '', confirmPassword: '' },
    mode: 'onTouched',
  })

  const mutation = useMutation({
    mutationFn: async (values: FormValues) =>
      await confirmPasswordReset(values.token, values.newPassword),
    onSuccess: (data) => {
      toast.success('Contraseña actualizada.', { description: data.message })
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
      aria-label="Formulario para restablecer contraseña"
    >
      <div className="space-y-2">
        <Label htmlFor="token">Token</Label>
        <Input id="token" autoComplete="one-time-code" {...register('token')} />
        {errors.token ? <p className="text-sm text-destructive">{errors.token.message}</p> : null}
      </div>

      <div className="space-y-2">
        <Label htmlFor="newPassword">Nueva contraseña</Label>
        <Input id="newPassword" type="password" autoComplete="new-password" {...register('newPassword')} />
        {errors.newPassword ? (
          <p className="text-sm text-destructive">{errors.newPassword.message}</p>
        ) : null}
      </div>

      <div className="space-y-2">
        <Label htmlFor="confirmPassword">Confirmar contraseña</Label>
        <Input
          id="confirmPassword"
          type="password"
          autoComplete="new-password"
          {...register('confirmPassword')}
        />
        {errors.confirmPassword ? (
          <p className="text-sm text-destructive">{errors.confirmPassword.message}</p>
        ) : null}
      </div>

      <Button type="submit" className="w-full" disabled={mutation.isPending} aria-label="Actualizar contraseña">
        {mutation.isPending ? 'Actualizando…' : 'Actualizar contraseña'}
      </Button>
    </form>
  )
}

