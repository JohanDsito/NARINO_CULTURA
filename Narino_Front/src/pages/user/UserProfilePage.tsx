import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation } from '@tanstack/react-query'
import { toast } from 'sonner'
import axiosInstance from '@/api/axiosInstance'
import { me } from '@/api/auth.api'
import { useAuthStore } from '@/store/authStore'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { PageShell } from '@/components/layout/page-shell'
import type { User } from '@/types/auth'

const schema = z.object({
  first_name: z.string().min(1, 'Requerido'),
  last_name: z.string().min(1, 'Requerido'),
  phone: z.string().optional(),
  avatar_url: z.string().url('URL inválida').optional().or(z.literal('')),
})

type FormData = z.infer<typeof schema>

const ROLE_LABELS: Record<string, string> = {
  artist: 'Artista',
  buyer: 'Visitante',
  cultural_manager: 'Gestor Cultural',
  admin: 'Administrador',
}

export default function UserProfilePage() {
  const { user, updateUser } = useAuthStore()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isDirty },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      first_name: user?.first_name ?? '',
      last_name: user?.last_name ?? '',
      phone: user?.phone ?? '',
      avatar_url: user?.avatar_url ?? '',
    },
  })

  useEffect(() => {
    if (user) {
      reset({
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone ?? '',
        avatar_url: user.avatar_url ?? '',
      })
    }
  }, [user, reset])

  const updateMutation = useMutation({
    mutationFn: async (data: FormData): Promise<User> => {
      const res = await axiosInstance.patch<User>('/api/v1/users/me/', data)
      return res.data
    },
    onSuccess: async () => {
      // Refresh user data from server
      const freshUser = await me()
      updateUser(freshUser)
      toast.success('Perfil actualizado correctamente')
    },
    onError: () => {
      toast.error('No se pudo actualizar el perfil.')
    },
  })

  if (!user) return null

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Mi perfil" subtitle="Administra tu información personal" />

      <main className="mx-auto max-w-xl px-6 py-8">
        {/* Info de solo lectura */}
        <div className="rounded-card border border-border bg-surface p-5 mb-8 space-y-3">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-oro/20 flex items-center justify-center">
              {user.avatar_url ? (
                <img src={user.avatar_url} alt="Avatar" className="w-16 h-16 rounded-full object-cover" />
              ) : (
                <span className="font-display font-bold text-oro text-2xl">
                  {user.first_name.charAt(0)}
                </span>
              )}
            </div>
            <div>
              <p className="font-display font-bold text-text-primary text-[18px]">
                {user.first_name} {user.last_name}
              </p>
              <p className="font-body text-text-muted text-sm">{user.email}</p>
            </div>
          </div>
          <div className="flex gap-2 pt-2">
            <span className="rounded-tag bg-oro/10 text-oro font-body text-[12px] px-3 py-1">
              {ROLE_LABELS[user.role] ?? user.role}
            </span>
            {user.is_verified && (
              <span className="rounded-tag bg-selva/10 text-selva font-body text-[12px] px-3 py-1">
                Verificado
              </span>
            )}
          </div>
        </div>

        {/* Formulario de edición */}
        <form onSubmit={handleSubmit((data) => updateMutation.mutate(data))} className="space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label htmlFor="first_name">Nombre</Label>
              <Input id="first_name" {...register('first_name')} />
              {errors.first_name && (
                <p className="font-body text-[12px] text-error">{errors.first_name.message}</p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="last_name">Apellido</Label>
              <Input id="last_name" {...register('last_name')} />
              {errors.last_name && (
                <p className="font-body text-[12px] text-error">{errors.last_name.message}</p>
              )}
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="phone">Teléfono</Label>
            <Input id="phone" type="tel" placeholder="+57 300 000 0000" {...register('phone')} />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="avatar_url">URL de foto de perfil</Label>
            <Input id="avatar_url" type="url" placeholder="https://…" {...register('avatar_url')} />
            {errors.avatar_url && (
              <p className="font-body text-[12px] text-error">{errors.avatar_url.message}</p>
            )}
          </div>

          <Button
            type="submit"
            variant="primary"
            className="w-full"
            disabled={!isDirty || updateMutation.isPending}
          >
            {updateMutation.isPending ? 'Guardando…' : 'Guardar cambios'}
          </Button>
        </form>
      </main>
    </div>
  )
}
