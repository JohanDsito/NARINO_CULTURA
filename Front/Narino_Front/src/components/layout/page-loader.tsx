import { cn } from '@/utils'

/**
 * Indicador de carga. Con `fullPage` ocupa el alto de una pantalla, igual que las páginas que reemplaza:
 * así el pie de página no se ve mientras carga ni salta cuando llega el contenido (menos CLS).
 */
export function PageLoader({ label = 'Cargando…', fullPage = false }: { label?: string; fullPage?: boolean }) {
  return (
    <div
      className={cn(
        'mx-auto flex w-full max-w-5xl items-center justify-center px-4',
        fullPage ? 'min-h-screen pt-16' : 'min-h-[60vh]',
      )}
    >
      <div className="flex items-center gap-3 text-sm text-text-secondary" role="status" aria-live="polite">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-text-muted border-t-transparent" />
        <span>{label}</span>
      </div>
    </div>
  )
}
