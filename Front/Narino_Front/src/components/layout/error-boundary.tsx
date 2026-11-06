import { Component, type ErrorInfo, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[ErrorBoundary]', error, info.componentStack)
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null })
    window.location.reload()
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback

      return (
        <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-6 text-center">
          <p className="font-display text-xl font-semibold text-text-primary">
            Algo salió mal
          </p>
          <p className="max-w-sm font-body text-sm text-text-muted">
            Ocurrió un error inesperado. Intenta recargar la página.
          </p>
          {this.state.error && (
            <pre className="max-w-sm overflow-auto rounded-card border border-border bg-surface px-4 py-2 text-left font-mono text-[11px] text-text-muted">
              {this.state.error.message}
            </pre>
          )}
          <button
            onClick={this.handleReset}
            className="rounded-input bg-oro px-4 py-2 font-body text-sm font-medium text-white hover:bg-oro/90 transition-colors"
          >
            Recargar página
          </button>
        </div>
      )
    }

    return this.props.children
  }
}
