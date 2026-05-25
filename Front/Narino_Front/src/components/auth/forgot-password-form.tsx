import { useMutation } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'

import { requestPasswordReset } from '@/api/auth.api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getApiErrorMessage } from '@/utils/apiError'

const schema = z.object({
  email: z.string().email('Ingresa un email válido.'),
})

type FormValues = z.infer<typeof schema>

export function ForgotPasswordForm() {
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: '' },
    mode: 'onTouched',
  })

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => await requestPasswordReset(values.email),
    onSuccess: (data) => {
      toast.success('Solicitud enviada.', { description: data.message })
      form.reset()
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
      aria-label="Formulario de recuperación de contraseña"
    >
      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" autoComplete="email" {...register('email')} />
        {errors.email ? <p className="text-sm text-destructive">{errors.email.message}</p> : null}
      </div>

      <Button type="submit" className="w-full" disabled={mutation.isPending} aria-label="Enviar solicitud">
        {mutation.isPending ? 'Enviando…' : 'Enviar'}
      </Button>
    </form>
  )
}

