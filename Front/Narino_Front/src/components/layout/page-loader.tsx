export function PageLoader({ label = 'Cargando…' }: { label?: string }) {
  return (
    <div className="mx-auto flex min-h-[60vh] w-full max-w-5xl items-center justify-center px-4">
      <div className="flex items-center gap-3 text-sm text-muted-foreground" role="status" aria-live="polite">
        <div className="h-4 w-4 animate-spin rounded-full border-2 border-muted-foreground border-t-transparent" />
        <span>{label}</span>
      </div>
    </div>
  )
}

