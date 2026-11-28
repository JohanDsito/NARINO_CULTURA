import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'

import { AppLayout } from '@/components/layout/app-layout'
import { ErrorBoundary } from '@/components/layout/error-boundary'
import { Footer } from '@/components/layout/footer'
import { PageLoader } from '@/components/layout/page-loader'
import { PageShell } from '@/components/layout/page-shell'
import { renderWithProviders } from '@/test/render'

vi.mock('@/components/layout/navbar', () => ({ Navbar: () => <nav>barra-navegacion</nav> }))
vi.mock('@/components/ai/chatbot-widget', () => ({ ChatbotWidget: () => <div>chat</div> }))

function Boom(): never {
  throw new Error('explotó')
}

describe('Footer', () => {
  it('muestra la marca, los enlaces del sitio y las redes sociales', () => {
    renderWithProviders(<Footer />)
    expect(screen.getByText('Un proyecto de UCC y Corpocarnaval')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Artistas' })).toHaveAttribute('href', '/artists')
    expect(screen.getByRole('link', { name: 'Marketplace' })).toHaveAttribute('href', '/marketplace')
    expect(screen.getByRole('link', { name: 'Instagram' })).toHaveAttribute('href', 'https://www.instagram.com/')
    expect(screen.getByRole('link', { name: 'TikTok' })).toHaveAttribute('target', '_blank')
  })
})

describe('PageLoader', () => {
  it('muestra el texto por defecto o el indicado', () => {
    const { rerender } = render(<PageLoader />)
    expect(screen.getByRole('status')).toHaveTextContent('Cargando…')
    rerender(<PageLoader label="Un momento" />)
    expect(screen.getByRole('status')).toHaveTextContent('Un momento')
  })
})

describe('PageShell', () => {
  it('muestra título, etiqueta, subtítulo, acciones e hijos', () => {
    render(
      <PageShell title="Título" eyebrow="Etiqueta" accent="oro" subtitle="Sub" actions={<button>Acción</button>} className="extra">
        <p>contenido</p>
      </PageShell>,
    )
    expect(screen.getByRole('heading', { name: 'Título' })).toBeInTheDocument()
    expect(screen.getByText('Etiqueta')).toHaveClass('text-oro')
    expect(screen.getByText('Sub')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Acción' })).toBeInTheDocument()
    expect(screen.getByText('contenido')).toBeInTheDocument()
  })

  it('usa la descripción si no hay subtítulo y el acento azul por defecto; sin extras no pinta nada de más', () => {
    const { container } = render(<PageShell title="T" description="Descripción" eyebrow="E" />)
    expect(screen.getByText('Descripción')).toBeInTheDocument()
    expect(screen.getByText('E')).toHaveClass('text-azul')
    expect(container.querySelectorAll('button')).toHaveLength(0)
  })

  it('sin etiqueta ni descripción solo muestra el título', () => {
    const { container } = render(<PageShell title="Solo" />)
    expect(container.querySelectorAll('p')).toHaveLength(0)
  })
})

describe('ErrorBoundary', () => {
  beforeEach(() => {
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })
  afterEach(() => vi.restoreAllMocks())

  it('sin error muestra los hijos', () => {
    render(<ErrorBoundary><p>todo bien</p></ErrorBoundary>)
    expect(screen.getByText('todo bien')).toBeInTheDocument()
  })

  it('ante un error muestra el mensaje, el detalle y registra en consola', () => {
    render(<ErrorBoundary><Boom /></ErrorBoundary>)
    expect(screen.getByText('Algo salió mal')).toBeInTheDocument()
    expect(screen.getByText('explotó')).toBeInTheDocument()
    expect(console.error).toHaveBeenCalledWith('[ErrorBoundary]', expect.any(Error), expect.any(String))
  })

  it('usa el fallback propio si se entrega', () => {
    render(<ErrorBoundary fallback={<p>plan B</p>}><Boom /></ErrorBoundary>)
    expect(screen.getByText('plan B')).toBeInTheDocument()
    expect(screen.queryByText('Algo salió mal')).not.toBeInTheDocument()
  })

  it('"Recargar página" recarga la ventana', () => {
    const reload = vi.fn()
    vi.stubGlobal('location', { ...window.location, reload })
    render(<ErrorBoundary><Boom /></ErrorBoundary>)
    fireEvent.click(screen.getByRole('button', { name: 'Recargar página' }))
    expect(reload).toHaveBeenCalled()
    vi.unstubAllGlobals()
  })
})

describe('AppLayout', () => {
  it('compone barra, contenido de la ruta, pie y chat', () => {
    renderWithProviders(<AppLayout />)
    expect(screen.getByText('barra-navegacion')).toBeInTheDocument()
    expect(screen.getByText('chat')).toBeInTheDocument()
    expect(screen.getByText('Un proyecto de UCC y Corpocarnaval')).toBeInTheDocument()
  })
})
