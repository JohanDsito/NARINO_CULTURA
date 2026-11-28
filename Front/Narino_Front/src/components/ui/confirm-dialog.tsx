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
  const dialogRef = useRef<HTMLFormElement>(null)

  // Foco inicial solo al abrir (no en cada render: si no, escribir en un campo devolvería el foco a
  // "Cancelar"). Va al primer campo si lo hay; si no, a la acción menos destructiva. Al cerrar, vuelve
  // al elemento que abrió el diálogo.
  useEffect(() => {
    if (!open) return
    const opener = document.activeElement instanceof HTMLElement ? document.activeElement : null
    const field = dialogRef.current?.querySelector<HTMLElement>('input, select, textarea')
    ;(field ?? cancelRef.current)?.focus()
    return () => opener?.focus()
  }, [open])

  // Escape cancela y Tab no sale del diálogo (aria-modal)
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isPending) {
        onCancel()
        return
      }
      if (e.key !== 'Tab' || !dialogRef.current) return
      const focusables = Array.from(
        dialogRef.current.querySelectorAll<HTMLElement>(
          'button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [href], [tabindex]:not([tabindex="-1"])',
        ),
      )
      if (focusables.length === 0) return
      const first = focusables[0]
      const last = focusables[focusables.length - 1]
      const active = document.activeElement
      if (e.shiftKey && (active === first || !dialogRef.current.contains(active))) {
        e.preventDefault()
        last.focus()
      } else if (!e.shiftKey && (active === last || !dialogRef.current.contains(active))) {
        e.preventDefault()
        first.focus()
      }
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
        ref={dialogRef}
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
