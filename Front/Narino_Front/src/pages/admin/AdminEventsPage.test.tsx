import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor, within } from '@testing-library/react'
import { toast } from 'sonner'

import { approveEvent, getApprovedEvents, getPendingEvents, rejectEvent } from '@/api/admin.api'
import type { Event } from '@/api/events.api'
import AdminEventsPage from '@/pages/admin/AdminEventsPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/admin.api', () => ({
  getPendingEvents: vi.fn(),
  getApprovedEvents: vi.fn(),
  approveEvent: vi.fn(),
  rejectEvent: vi.fn(),
}))
vi.mock('@/components/events', () => ({
  EventCalendar: ({ showCreateButton }: { showCreateButton: boolean }) => <div>calendario:{String(showCreateButton)}</div>,
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedPending = vi.mocked(getPendingEvents)
const mockedApproved = vi.mocked(getApprovedEvents)
const mockedApprove = vi.mocked(approveEvent)
const mockedReject = vi.mocked(rejectEvent)

function ev(id: string, overrides: Partial<Event> = {}): Event {
  return {
    id,
    title: `Evento ${id}`,
    description: 'Una descripción',
    event_type: 'CONCIERTO',
    start_date: '2026-05-10T10:00:00Z',
    end_date: '2026-05-10T12:00:00Z',
    location: 'Pasto',
    image_url: 'https://img.test/flyer.jpg',
    is_published: false,
    organizer: { id: 1, email: 'o@test.com', first_name: 'Olga', last_name: 'Paz' },
    created_at: '',
    updated_at: '',
    ...overrides,
  }
}

describe('AdminEventsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: 'u', email: 'a@test.com', first_name: 'A', last_name: 'B', role: 'admin' } })
    mockedPending.mockResolvedValue([ev('p1')])
    mockedApproved.mockResolvedValue([ev('a1', { is_published: true })])
  })
  afterEach(() => vi.restoreAllMocks())

  it('muestra pendientes con flyer, tipo, lugar, organizador y descripción, y publicados en tabla', async () => {
    renderWithProviders(<AdminEventsPage />)
    expect(await screen.findByText('Evento p1')).toBeInTheDocument()
    expect(screen.getByText('Por: Olga Paz')).toBeInTheDocument()
    expect(screen.getByText('Una descripción')).toBeInTheDocument()
    expect(screen.getAllByAltText(/Evento/)).toHaveLength(2)
    const row = (await screen.findByText('Evento a1')).closest('tr')!
    expect(within(row).getByText('Concierto')).toBeInTheDocument()
    expect(within(row).getByText('Olga Paz')).toBeInTheDocument()
    expect(screen.getByText('calendario:true')).toBeInTheDocument()
  })

  it('el calendario no ofrece crear si el usuario no es administrador', async () => {
    useAuthStore.setState({ user: null })
    renderWithProviders(<AdminEventsPage />)
    expect(await screen.findByText('calendario:false')).toBeInTheDocument()
  })

  it('tolera eventos sin imagen, sin fecha, sin descripción y de tipo desconocido', async () => {
    mockedPending.mockResolvedValue([ev('p2', { image_url: undefined, start_date: '', description: '', event_type: 'RARO' as Event['event_type'] })])
    mockedApproved.mockResolvedValue([ev('a2', { image_url: undefined, start_date: '', event_type: 'RARO' as Event['event_type'] })])
    renderWithProviders(<AdminEventsPage />)
    expect(await screen.findByText('Evento p2')).toBeInTheDocument()
    expect(screen.queryByAltText('Evento p2')).not.toBeInTheDocument()
    expect(screen.getAllByText('RARO')).toHaveLength(2)
    expect(screen.getAllByText('—')).toHaveLength(2)
  })

  it('aprueba un evento pendiente', async () => {
    mockedApprove.mockResolvedValue({ detail: 'ok' })
    renderWithProviders(<AdminEventsPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Aprobar/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Evento aprobado y publicado en el calendario.'))
    expect(mockedApprove.mock.calls[0][0]).toBe('p1')
  })

  it('si aprobar falla avisa', async () => {
    mockedApprove.mockRejectedValue(new Error('x'))
    renderWithProviders(<AdminEventsPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Aprobar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo aprobar el evento.'))
  })

  it('rechazar pide confirmación; cancelado no hace nada, aceptado rechaza y avisa', async () => {
    mockedReject.mockResolvedValue({ detail: 'ok' })
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderWithProviders(<AdminEventsPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Rechazar/ }))
    expect(confirm).toHaveBeenCalledWith('¿Rechazar y eliminar el evento "Evento p1"? Esta acción no se puede deshacer.')
    expect(mockedReject).not.toHaveBeenCalled()
    confirm.mockReturnValue(true)
    fireEvent.click(screen.getByRole('button', { name: /Rechazar/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Evento rechazado y eliminado.'))
    expect(mockedReject.mock.calls[0][0]).toBe('p1')
  })

  it('si rechazar falla avisa', async () => {
    mockedReject.mockRejectedValue(new Error('x'))
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderWithProviders(<AdminEventsPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Rechazar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo rechazar el evento.'))
  })

  it('elimina un evento publicado con confirmación y avisa; si falla también avisa', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderWithProviders(<AdminEventsPage />)
    const deleteButton = await screen.findByRole('button', { name: /Eliminar/ })
    fireEvent.click(deleteButton)
    expect(confirm).toHaveBeenCalledWith('¿Eliminar el evento publicado "Evento a1"? Esta acción no se puede deshacer.')
    expect(mockedReject).not.toHaveBeenCalled()

    confirm.mockReturnValue(true)
    mockedReject.mockResolvedValueOnce({ detail: 'ok' })
    fireEvent.click(deleteButton)
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Evento eliminado.'))

    mockedReject.mockRejectedValueOnce(new Error('x'))
    fireEvent.click(screen.getByRole('button', { name: /Eliminar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo eliminar el evento.'))
  })

  it('sin eventos muestra los vacíos y esqueletos mientras carga', async () => {
    mockedPending.mockResolvedValue([])
    mockedApproved.mockResolvedValue([])
    const { container } = renderWithProviders(<AdminEventsPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(6)
    expect(await screen.findByText('Todo al día')).toBeInTheDocument()
    expect(screen.getByText('No hay eventos publicados.')).toBeInTheDocument()
  })
})
