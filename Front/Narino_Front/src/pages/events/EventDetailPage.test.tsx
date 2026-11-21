import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { toast } from 'sonner'

import { eventsApi, type Event } from '@/api/events.api'
import EventDetailPage from '@/pages/events/EventDetailPage'
import { useAuthStore } from '@/store/authStore'

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
    location: 'Teatro Imperial, Pasto',
    is_published: true,
    is_registered: false,
    organizer: { id: 1, email: 'gestor@narino.test', first_name: 'Gestor', last_name: 'Cultural' },
    created_at: '',
    updated_at: '',
    ...overrides,
  }
}

function LoginProbe() {
  const location = useLocation()
  return <p>Login (volver a {(location.state as { from?: string } | null)?.from})</p>
}

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/events/e1']}>
        <Routes>
          <Route path="/events/:id" element={<EventDetailPage />} />
          <Route path="/login" element={<LoginProbe />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('EventDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true, accessToken: 't', refreshToken: 'r' })
    api.registerToEvent.mockResolvedValue({} as never)
    api.unregisterFromEvent.mockResolvedValue({} as never)
  })

  it('se inscribe y pasa a mostrar «Ya estás inscrito»', async () => {
    api.getEventById
      .mockResolvedValueOnce({ data: event() } as never)
      .mockResolvedValue({ data: event({ is_registered: true }) } as never)
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /inscribirme en este evento/i }))
    await waitFor(() => expect(api.registerToEvent).toHaveBeenCalledWith('e1'))
    expect(await screen.findByText('Ya estás inscrito')).toBeInTheDocument()
    expect(toast.success).toHaveBeenCalledWith(expect.stringMatching(/te recordaremos/i))
  })

  it('quien ya está inscrito puede cancelar', async () => {
    api.getEventById
      .mockResolvedValueOnce({ data: event({ is_registered: true }) } as never)
      .mockResolvedValue({ data: event({ is_registered: false }) } as never)
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /cancelar inscripción/i }))
    await waitFor(() => expect(api.unregisterFromEvent).toHaveBeenCalledWith('e1'))
    expect(await screen.findByRole('button', { name: /inscribirme en este evento/i })).toBeInTheDocument()
  })

  it('muestra el mensaje del servidor si no se puede inscribir', async () => {
    api.getEventById.mockResolvedValue({ data: event() } as never)
    api.registerToEvent.mockRejectedValue({
      isAxiosError: true,
      response: { status: 400, data: { detail: 'El evento ya finalizó.' } },
    })
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /inscribirme en este evento/i }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El evento ya finalizó.'))
  })

  it('sin sesión invita a iniciar sesión y luego vuelve al evento', async () => {
    useAuthStore.setState({ isAuthenticated: false, accessToken: null, refreshToken: null })
    api.getEventById.mockResolvedValue({ data: event() } as never)
    renderPage()
    fireEvent.click(await screen.findByRole('link', { name: /inicia sesión para inscribirte/i }))
    expect(await screen.findByText('Login (volver a /events/e1)')).toBeInTheDocument()
  })

  it('un evento terminado ya no permite inscribirse', async () => {
    api.getEventById.mockResolvedValue({
      data: event({
        start_date: new Date(Date.now() - 2 * DAY).toISOString(),
        end_date: new Date(Date.now() - DAY).toISOString(),
      }),
    } as never)
    renderPage()
    expect(await screen.findByText('Este evento ya terminó.')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /inscribirme/i })).not.toBeInTheDocument()
  })
})
