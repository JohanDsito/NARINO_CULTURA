import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'

import { eventsApi, type Event } from '@/api/events.api'
import { EventCalendar } from '@/components/events/event-calendar'
import { Calendar } from '@/components/ui/calendar'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

vi.mock('@/api/events.api', async () => {
  const actual = await vi.importActual<typeof import('@/api/events.api')>('@/api/events.api')
  return { ...actual, eventsApi: { getEventsByDateRange: vi.fn() } }
})
vi.mock('@/components/events/event-form-modal', () => ({
  EventFormModal: ({ open, onSuccess, onOpenChange }: { open: boolean; onSuccess: () => void; onOpenChange: (o: boolean) => void }) =>
    open ? (
      <div>
        modal-evento
        <button onClick={onSuccess}>guardar-evento</button>
        <button onClick={() => onOpenChange(false)}>cerrar-modal</button>
      </div>
    ) : null,
}))

const mockedRange = vi.mocked(eventsApi.getEventsByDateRange)

function ev(id: string, start: string, overrides: Partial<Event> = {}): Event {
  return {
    id,
    title: `Evento ${id}`,
    description: 'Descripción del evento',
    event_type: 'CONCIERTO',
    start_date: start,
    end_date: start,
    location: 'Teatro Imperial',
    is_published: true,
    organizer: { id: 1, email: 'o@test.com', first_name: 'Olga', last_name: 'Paz' },
    created_at: '',
    updated_at: '',
    ...overrides,
  }
}

describe('Calendar', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-05-15T12:00:00'))
  })
  afterEach(() => vi.useRealTimers())

  it('sin control externo navega por su cuenta y avisa del cambio de mes', () => {
    const onMonthChange = vi.fn()
    render(<Calendar events={[]} onMonthChange={onMonthChange} />)
    expect(screen.getByRole('heading', { name: 'mayo 2026' })).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Mes siguiente' }))
    expect(screen.getByRole('heading', { name: 'junio 2026' })).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Mes anterior' }))
    fireEvent.click(screen.getByRole('button', { name: 'Mes anterior' }))
    expect(screen.getByRole('heading', { name: 'abril 2026' })).toBeInTheDocument()
    expect(onMonthChange).toHaveBeenCalledTimes(3)
  })

  it('sin control externo ni callback tampoco falla', () => {
    render(<Calendar events={[]} />)
    fireEvent.click(screen.getByRole('button', { name: 'Mes siguiente' }))
    fireEvent.click(screen.getByText('10', { selector: 'div.text-sm' }))
    expect(screen.getByRole('heading', { name: 'junio 2026' })).toBeInTheDocument()
  })

  it('con mes controlado no cambia solo: delega en onMonthChange', () => {
    const onMonthChange = vi.fn()
    render(<Calendar events={[]} currentMonth={new Date('2026-08-10T00:00:00')} onMonthChange={onMonthChange} />)
    fireEvent.click(screen.getByRole('button', { name: 'Mes siguiente' }))
    expect(screen.getByRole('heading', { name: 'agosto 2026' })).toBeInTheDocument()
    expect(onMonthChange).toHaveBeenCalledWith(expect.any(Date))
  })

  it('muestra los eventos de cada día (máximo 2 y "+N más"), el aviso de carga y la selección', () => {
    const onSelectDate = vi.fn()
    const day = '2026-05-20T10:00:00'
    render(
      <Calendar
        events={[ev('1', day), ev('2', day), ev('3', day), ev('4', '2026-05-21T10:00:00')]}
        isLoading
        selectedDate={new Date('2026-05-20T00:00:00')}
        onSelectDate={onSelectDate}
      />,
    )
    expect(screen.getByText('Actualizando eventos...')).toBeInTheDocument()
    expect(screen.getByText('Evento 1')).toBeInTheDocument()
    expect(screen.getByText('Evento 2')).toBeInTheDocument()
    expect(screen.queryByText('Evento 3')).not.toBeInTheDocument()
    expect(screen.getByText('+1 más')).toBeInTheDocument()
    expect(screen.getByText('Evento 4')).toBeInTheDocument()
    fireEvent.click(screen.getByText('Evento 4'))
    expect(onSelectDate).toHaveBeenCalledWith(expect.any(Date))
    expect(screen.getByText('Evento 4').parentElement!.parentElement).not.toHaveClass('border-azul')
    expect(screen.getByText('Evento 1').parentElement!.parentElement).toHaveClass('border-azul')
  })

  it('oculta el aviso de carga cuando no carga', () => {
    render(<Calendar events={[]} />)
    expect(screen.queryByText('Actualizando eventos...')).not.toBeInTheDocument()
    expect(screen.getAllByText('Dom')).toHaveLength(1)
  })
})

describe('EventCalendar', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers({ toFake: ['Date'] })
    vi.setSystemTime(new Date('2026-05-15T12:00:00'))
    useAuthStore.setState({ user: null })
  })
  afterEach(() => vi.useRealTimers())

  function respond(events: Event[]) {
    mockedRange.mockResolvedValue({ data: events } as never)
  }

  it('carga los eventos del mes visible y muestra los del día seleccionado con todos sus datos', async () => {
    respond([
      ev('1', '2026-05-15T18:00:00', { end_date: '2026-05-15T20:30:00', image_url: 'https://img.test/e.jpg' }),
      ev('0', '2026-05-15T09:00:00', { description: '', location: '', organizer: undefined as never, event_type: 'RARO' as Event['event_type'] }),
      ev('2', '2026-05-16T09:00:00'),
    ])
    renderWithProviders(<EventCalendar />)
    expect(screen.getByText('Cargando eventos...')).toBeInTheDocument()
    expect(await screen.findByText('Eventos: 15 de mayo')).toBeInTheDocument()
    expect(mockedRange).toHaveBeenCalledWith('2026-05-01', '2026-05-31')
    const list = screen.getAllByRole('heading', { level: 3 }).map((h) => h.textContent)
    expect(list).toContain('Eventos: 15 de mayo')
    expect(screen.getByAltText('Evento 1')).toHaveAttribute('src', 'https://img.test/e.jpg')
    expect(screen.getByText('Concierto')).toBeInTheDocument()
    expect(screen.getByText('Otro')).toBeInTheDocument()
    expect(screen.getByText('Teatro Imperial', { selector: 'p.text-text-secondary' })).toBeInTheDocument()
    expect(screen.getByText('Olga Paz')).toBeInTheDocument()
    expect(screen.getByText(/18:00 - 20:30/)).toBeInTheDocument()
    expect(screen.getByText('Descripción del evento', { selector: 'p.text-sm' })).toBeInTheDocument()
  })

  it('ordena los eventos del día por hora', async () => {
    respond([ev('tarde', '2026-05-15T18:00:00'), ev('temprano', '2026-05-15T08:00:00')])
    renderWithProviders(<EventCalendar />)
    await screen.findByText('Eventos: 15 de mayo')
    const titles = screen.getAllByText(/^Evento (tarde|temprano)$/, { selector: '[class*="line-clamp-2"]' }).map((e) => e.textContent)
    expect(titles).toEqual(['Evento temprano', 'Evento tarde'])
  })

  it('sin eventos ese día lo indica; al cambiar de mes o de día se actualiza', async () => {
    respond([ev('2', '2026-05-16T09:00:00')])
    renderWithProviders(<EventCalendar />)
    expect(await screen.findByText('No hay eventos para este día')).toBeInTheDocument()
    fireEvent.click(screen.getAllByText('Evento 2')[0])
    expect(screen.getByText('Eventos: 16 de mayo')).toBeInTheDocument()
    expect(screen.queryByText('No hay eventos para este día')).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Mes siguiente' }))
    await waitFor(() => expect(mockedRange).toHaveBeenLastCalledWith('2026-06-01', '2026-06-30'))
    expect(screen.getByText('Eventos: 16 de junio')).toBeInTheDocument()
  })

  it('si falla la carga avisa', async () => {
    mockedRange.mockRejectedValue(new Error('x'))
    renderWithProviders(<EventCalendar />)
    expect(await screen.findByText('No se pudieron cargar los eventos. Intenta de nuevo más tarde.')).toBeInTheDocument()
  })

  it('solo administración con el botón activado ve "Agregar evento"; al guardar recarga', async () => {
    respond([])
    useAuthStore.setState({ user: { id: 'u', role: 'admin' } as User })
    const { unmount } = renderWithProviders(<EventCalendar showCreateButton />)
    fireEvent.click(await screen.findByRole('button', { name: '+ Agregar evento' }))
    expect(await screen.findByText(/modal-evento/)).toBeInTheDocument()
    const calls = mockedRange.mock.calls.length
    fireEvent.click(screen.getByRole('button', { name: 'guardar-evento' }))
    expect(screen.queryByText(/modal-evento/)).not.toBeInTheDocument()
    await waitFor(() => expect(mockedRange.mock.calls.length).toBeGreaterThan(calls))
    unmount()

    renderWithProviders(<EventCalendar />)
    await screen.findByText('Agenda Cultural')
    expect(screen.queryByRole('button', { name: '+ Agregar evento' })).not.toBeInTheDocument()
  })

  it('la gestora cultural también puede agregar; un comprador no, aunque el botón esté activado', async () => {
    respond([])
    useAuthStore.setState({ user: { id: 'u', role: 'cultural_manager' } as User })
    const { unmount } = renderWithProviders(<EventCalendar showCreateButton />)
    fireEvent.click(await screen.findByRole('button', { name: '+ Agregar evento' }))
    fireEvent.click(screen.getByRole('button', { name: 'cerrar-modal' }))
    expect(screen.queryByText(/modal-evento/)).not.toBeInTheDocument()
    unmount()

    useAuthStore.setState({ user: { id: 'u', role: 'buyer' } as User })
    renderWithProviders(<EventCalendar showCreateButton />)
    await screen.findByText('Agenda Cultural')
    expect(screen.queryByRole('button', { name: '+ Agregar evento' })).not.toBeInTheDocument()
  })
})
