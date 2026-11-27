import { useEffect, useId, useRef } from 'react'
import type { FormEvent, ReactNode } from 'react'

import { Button } from '@/components/ui/button'
import { cn } from '@/utils'

export interface ConfirmDialogProps {
  open: boolean
  title: string
  description?: ReactNode
  /** Contenido extra entre la descripción y los botones (p. ej. un campo de contraseña). */
  children?: ReactNode
  confirmLabel: string
  cancelLabel?: string
  /** `danger` pinta la acción en tomate; la acción primaria normal es azul. */
  tone?: 'primary' | 'danger'
  isPending?: boolean
  confirmDisabled?: boolean
  onConfirm: () => void
  onCancel: () => void
}

/** Diálogo de confirmación accesible (alertdialog). Enter confirma, Escape cancela. */
export function ConfirmDialog({
  open,
  title,
  description,
  children,
  confirmLabel,
  cancelLabel = 'Cancelar',
  tone = 'primary',
  isPending = false,
  confirmDisabled = false,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const titleId = useId()
  const descId = useId()
  const cancelRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (!open) return
    cancelRef.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isPending) onCancel()
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open, isPending, onCancel])

  if (!open) return null

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (!isPending && !confirmDisabled) onConfirm()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
      <form
        role="alertdialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={description ? descId : undefined}
        onSubmit={submit}
        className="nc-card w-full max-w-md space-y-4 rounded-card border border-border bg-bg-card p-6 text-text-primary shadow-xl"
      >
        <h2 id={titleId} className="font-display text-[18px] font-bold">
          {title}
        </h2>
        {description && (
          <div id={descId} className="space-y-2 font-body text-sm text-text-secondary">
            {description}
          </div>
        )}
        {children}
        <div className="flex justify-end gap-2 pt-2">
          <Button
            ref={cancelRef}
            type="button"
            variant="ghost"
            onClick={onCancel}
            disabled={isPending}
          >
            {cancelLabel}
          </Button>
          <Button
            type="submit"
            variant="primary"
            disabled={isPending || confirmDisabled}
            className={cn(tone === 'danger' && 'bg-tomate-fill text-on-tomate hover:bg-tomate-fill/90')}
          >
            {confirmLabel}
          </Button>
        </div>
      </form>
    </div>
  )
}
