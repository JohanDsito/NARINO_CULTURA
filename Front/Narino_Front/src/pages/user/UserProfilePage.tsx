import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation } from '@tanstack/react-query'
import { toast } from 'sonner'

import { updateMe, uploadAvatar } from '@/api/auth.api'
import { PageShell } from '@/components/layout/page-shell'
import { ProfileImageUpload } from '@/components/profile/profile-image-upload'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ROLE_LABELS } from '@/constants/labels'
import { useAuthStore } from '@/store/authStore'
import { getApiErrorMessage } from '@/utils/apiError'

const schema = z.object({
  first_name: z.string().trim().min(1, 'Requerido'),
  last_name: z.string().trim().min(1, 'Requerido'),
  phone: z.string().trim().optional(),
})

type FormData = z.infer<typeof schema>

export default function UserProfilePage() {
  const user = useAuthStore((s) => s.user)
  const updateUser = useAuthStore((s) => s.updateUser)

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
    },
  })

  const updateMutation = useMutation({
    mutationFn: (data: FormData) => updateMe(data),
    onSuccess: (freshUser) => {
      updateUser(freshUser)
      reset({
        first_name: freshUser.first_name,
        last_name: freshUser.last_name,
        phone: freshUser.phone ?? '',
      })
      toast.success('Perfil actualizado correctamente')
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const avatarMutation = useMutation({
    mutationFn: (file: File) => uploadAvatar(file),
    onSuccess: (freshUser) => {
      updateUser(freshUser)
      toast.success('Foto de perfil actualizada')
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  if (!user) return null

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell title="Mi perfil" subtitle="Administra tu información personal" />

      <main className="mx-auto grid max-w-4xl gap-6 px-6 py-8 md:grid-cols-[1fr_280px]">
        <div className="space-y-8">
          {/* Info de solo lectura */}
          <div className="rounded-card border border-border bg-bg-card p-5 space-y-3">
            <div>
              <p className="font-display font-bold text-text-primary text-[18px]">
                {user.first_name} {user.last_name}
              </p>
              <p className="font-body text-text-muted text-sm">{user.email}</p>
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
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
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

            <Button
              type="submit"
              variant="primary"
              className="w-full"
              disabled={!isDirty || updateMutation.isPending}
            >
              {updateMutation.isPending ? 'Guardando…' : 'Guardar cambios'}
            </Button>
          </form>
        </div>

        <ProfileImageUpload
          currentUrl={user.avatar_url || undefined}
          name={user.first_name || user.email}
          onUpload={(file) => avatarMutation.mutateAsync(file)}
          isPending={avatarMutation.isPending}
        />
      </main>
    </div>
  )
}
