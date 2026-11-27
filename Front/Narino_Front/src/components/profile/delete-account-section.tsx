import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'

import { deleteAccount } from '@/api/auth.api'
import { Button } from '@/components/ui/button'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAuthStore } from '@/store/authStore'
import { getApiErrorMessage } from '@/utils/apiError'

/** "Zona de peligro" del perfil: eliminar la cuenta con confirmación y contraseña. */
export function DeleteAccountSection() {
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [open, setOpen] = useState(false)
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)

  const close = () => {
    setOpen(false)
    setPassword('')
    setError(null)
  }

  const mutation = useMutation({
    mutationFn: () => deleteAccount(password),
    onSuccess: () => {
      // La cuenta ya no existe: no hay sesión que cerrar en el servidor, solo limpiar el estado local
      logout()
      queryClient.clear()
      toast.success('Tu cuenta fue eliminada. Gracias por haber sido parte de Nariño Cultura.')
      navigate('/')
    },
    // 400 (contraseña incorrecta) y 409 (obras vendidas) traen su mensaje en `detail`: se muestran en el diálogo
    onError: (err) => setError(getApiErrorMessage(err)),
  })

  return (
    <section aria-labelledby="danger-zone-title" className="rounded-card border border-tomate/40 p-5">
      <p className="nc-eyebrow text-tomate">Zona de peligro</p>
      <h2 id="danger-zone-title" className="mt-1 font-display text-[16px] font-bold text-text-primary">
        Eliminar mi cuenta
      </h2>
      <p className="mt-1 font-body text-sm text-text-secondary">
        Se borrará tu perfil y tus datos personales de forma permanente. Esta acción no se puede deshacer.
      </p>
      <Button
        type="button"
        variant="ghost"
        className="mt-4 border-[1.5px] border-tomate/60 text-tomate hover:bg-tomate-tint"
        onClick={() => setOpen(true)}
      >
        Eliminar mi cuenta
      </Button>

      <ConfirmDialog
        open={open}
        title="¿Eliminar tu cuenta?"
        description={
          <>
            <p>
              <strong>Se elimina:</strong> tu perfil, tu foto, tus favoritos y los datos personales de tu cuenta.
            </p>
            <p>
              <strong>Se conserva:</strong> tus compras, con tu nombre y correo, porque son el soporte de los pagos
              en el historial de ventas de los artistas.
            </p>
            <p>
              Si tienes obras vendidas no podrás eliminarla: escríbele al administrador para desactivarla.
            </p>
          </>
        }
        confirmLabel={mutation.isPending ? 'Eliminando…' : 'Eliminar definitivamente'}
        tone="danger"
        isPending={mutation.isPending}
        confirmDisabled={!password.trim()}
        onConfirm={() => {
          setError(null)
          mutation.mutate()
        }}
        onCancel={close}
      >
        <div className="space-y-1.5">
          <Label htmlFor="delete-account-password">Confirma con tu contraseña</Label>
          <Input
            id="delete-account-password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            aria-invalid={error ? true : undefined}
            aria-describedby={error ? 'delete-account-error' : undefined}
          />
          {error && (
            <p id="delete-account-error" role="alert" className="font-body text-[12px] text-error">
              {error}
            </p>
          )}
        </div>
      </ConfirmDialog>
    </section>
  )
}
