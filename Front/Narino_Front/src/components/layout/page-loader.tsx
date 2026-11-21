export function PageLoader({ label = 'Cargando…' }: { label?: string }) {
  return (
    <div className="mx-auto flex min-h-[60vh] w-full max-w-5xl items-center justify-center px-4">
      <div className="flex items-center gap-3 text-sm text-text-secondary" role="status" aria-live="polite">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-text-muted border-t-transparent" />
        <span>{label}</span>
      </div>
    </div>
  )
}

