import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { eventsApi, type Event } from '@/api/events.api'
import EventDetailPage from '@/pages/events/EventDetailPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/events.api', () => ({
  eventsApi: { getEventById: vi.fn(), registerToEvent: vi.fn(), unregisterFromEvent: vi.fn() },
}))
vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

const api = vi.mocked(eventsApi)
const DAY = 24 * 3600 * 1000

function event(overrides: Partial<Event> = {}): Event {
  return {
    id: 'e1',
    title: 'Concierto andino',
    description: 'Música de los Andes',
    event_type: 'CONCIERTO',
    start_date: new Date(Date.now() + DAY).toISOString(),
    end_date: new Date(Date.now() + DAY + 2 * 3600 * 1000).toISOString(),
    location: 'Teatro Imperial',
    is_published: true,
    is_registered: false,
    organizer: { id: 1, email: 'g@test.com', first_name: 'Gestor', last_name: 'Cultural' },
    created_at: '',
    updated_at: '',
    ...overrides,
  }
}

function renderPage() {
  return renderWithProviders(<EventDetailPage />, { route: '/events/e1', path: '/events/:id' })
}

describe('EventDetailPage: casos de borde', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true })
  })

  it('evento inexistente: muestra el error y vuelve a la agenda', async () => {
    api.getEventById.mockRejectedValue(new Error('404'))
    renderPage()
    expect(await screen.findByText('No se encontró este evento.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Volver a eventos' })).toHaveAttribute('href', '/events')
  })

  it('un borrador con imagen, mapa y tipo desconocido muestra todo y no permite inscribirse', async () => {
    api.getEventById.mockResolvedValue({
      data: event({ is_published: false, image_url: 'https://img.test/e.jpg', latitude: 1.2, longitude: -77.3, event_type: 'RARO' as Event['event_type'] }),
    } as never)
    renderPage()
    expect(await screen.findByText('Borrador')).toBeInTheDocument()
    expect(screen.getByText('RARO')).toBeInTheDocument()
    expect(screen.getByAltText('Concierto andino')).toHaveAttribute('src', 'https://img.test/e.jpg')
    expect(screen.getByRole('link', { name: 'Ver en el mapa →' })).toHaveAttribute('href', 'https://www.google.com/maps?q=1.2,-77.3')
    expect(screen.queryByRole('button', { name: /Inscribirme/ })).not.toBeInTheDocument()
  })

  it('sin ubicación, descripción, organizador ni coordenadas no pinta esos bloques', async () => {
    api.getEventById.mockResolvedValue({
      data: event({ location: '', description: '', organizer: undefined as never, latitude: 1.2 }),
    } as never)
    renderPage()
    await screen.findByRole('heading', { name: 'Concierto andino' })
    expect(screen.queryByText('Organizador')).not.toBeInTheDocument()
    expect(screen.queryByText('Música de los Andes')).not.toBeInTheDocument()
    expect(screen.queryByText('Ver en el mapa →')).not.toBeInTheDocument()
  })

  it('con ubicación pero sin coordenadas no ofrece el mapa', async () => {
    api.getEventById.mockResolvedValue({ data: event({ latitude: 1.2 }) } as never)
    renderPage()
    expect(await screen.findByText('Teatro Imperial')).toBeInTheDocument()
    expect(screen.queryByText('Ver en el mapa →')).not.toBeInTheDocument()
  })

  it('mientras se inscribe dice "Inscribiendo…"', async () => {
    api.getEventById.mockResolvedValue({ data: event() } as never)
    api.registerToEvent.mockReturnValue(new Promise(() => {}) as never)
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Inscribirme en este evento/ }))
    expect(await screen.findByRole('button', { name: /Inscribiendo…/ })).toBeDisabled()
  })

  it('mientras cancela dice "Cancelando…"; si falla cancelar muestra el error', async () => {
    api.getEventById.mockResolvedValue({ data: event({ is_registered: true }) } as never)
    api.unregisterFromEvent.mockRejectedValueOnce(new Error('No se pudo cancelar'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Cancelar inscripción/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo cancelar'))

    api.unregisterFromEvent.mockReturnValue(new Promise(() => {}) as never)
    fireEvent.click(screen.getByRole('button', { name: /Cancelar inscripción/ }))
    expect(await screen.findByRole('button', { name: /Cancelando…/ })).toBeDisabled()
  })
})
