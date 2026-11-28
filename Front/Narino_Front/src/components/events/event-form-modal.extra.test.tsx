import { describe, it, expect, vi, beforeEach } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { AxiosError, type AxiosResponse } from 'axios'
import { toast } from 'sonner'

import { eventsApi } from '@/api/events.api'
import { EventFormModal } from '@/components/events/event-form-modal'

vi.mock('@/api/events.api', () => ({ eventsApi: { createEvent: vi.fn() } }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedCreate = vi.mocked(eventsApi.createEvent)

function renderModal(props: { onSuccess?: () => void } = {}) {
  const onOpenChange = vi.fn()
  render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { mutations: { retry: false } } })}>
      <EventFormModal open onOpenChange={onOpenChange} {...props} />
    </QueryClientProvider>,
  )
  return { onOpenChange }
}

function fill() {
  fireEvent.change(screen.getByLabelText('Título del evento'), { target: { value: 'Concierto andino' } })
  fireEvent.change(screen.getByLabelText('Descripción'), { target: { value: 'Una muestra musical tradicional' } })
  fireEvent.change(screen.getByLabelText('Tipo de evento'), { target: { value: 'CONCIERTO' } })
  fireEvent.change(screen.getByLabelText('Ubicación'), { target: { value: 'Teatro Pasto' } })
  fireEvent.change(screen.getByLabelText('Fecha y hora de inicio'), { target: { value: '2026-01-01T10:00' } })
  fireEvent.change(screen.getByLabelText('Fecha y hora de fin'), { target: { value: '2026-01-01T12:00' } })
}

describe('EventFormModal: validaciones, cierre y errores', () => {
  beforeEach(() => vi.clearAllMocks())

  it('muestra todos los mensajes de validación', async () => {
    renderModal()
    fireEvent.submit(screen.getByRole('button', { name: 'Crear evento' }).closest('form')!)
    expect(await screen.findByText('El título debe tener al menos 3 caracteres')).toBeInTheDocument()
    expect(screen.getByText('La descripción debe tener al menos 10 caracteres')).toBeInTheDocument()
    expect(screen.getByText('La ubicación debe tener al menos 3 caracteres')).toBeInTheDocument()
    expect(screen.getByText('Selecciona la fecha y hora de inicio')).toBeInTheDocument()
    expect(screen.getByText('Selecciona la fecha y hora de fin')).toBeInTheDocument()
    expect(screen.getAllByText(/Invalid|Required|expected/i).length).toBeGreaterThan(0)
    expect(mockedCreate).not.toHaveBeenCalled()
  })

  it('rechaza una URL de imagen inválida', async () => {
    renderModal()
    fill()
    fireEvent.change(screen.getByLabelText('URL de la imagen (opcional)'), { target: { value: 'no-es-url' } })
    fireEvent.submit(screen.getByRole('button', { name: 'Crear evento' }).closest('form')!)
    expect(await screen.findByText(/url/i, { selector: 'p.text-error' })).toBeInTheDocument()
    expect(mockedCreate).not.toHaveBeenCalled()
  })

  it('la X y "Cancelar" cierran el diálogo', () => {
    const { onOpenChange } = renderModal()
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    fireEvent.click(screen.getByRole('heading', { name: 'Crear nuevo evento' }).nextElementSibling!)
    expect(onOpenChange).toHaveBeenCalledTimes(2)
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('crea el evento con fechas en formato ISO aunque no se pase onSuccess', async () => {
    mockedCreate.mockResolvedValue({ data: {} } as never)
    const { onOpenChange } = renderModal()
    fill()
    fireEvent.change(screen.getByLabelText('URL de la imagen (opcional)'), { target: { value: 'https://img.test/a.jpg' } })
    fireEvent.click(screen.getByRole('button', { name: 'Crear evento' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Evento creado exitosamente'))
    const payload = mockedCreate.mock.calls[0][0]
    expect(payload.start_date).toBe(new Date('2026-01-01T10:00').toISOString())
    expect(payload.end_date).toBe(new Date('2026-01-01T12:00').toISOString())
    expect(payload.image_url).toBe('https://img.test/a.jpg')
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('si el servidor responde con detalle, lo muestra; si no, usa el mensaje genérico, sin rechazos sin manejar', async () => {
    const unhandled = vi.fn()
    process.on('unhandledRejection', unhandled)
    try {
      const withDetail = new AxiosError('x', 'ERR', undefined, undefined, { status: 400, data: { detail: 'Fecha pasada' } } as AxiosResponse)
      mockedCreate.mockRejectedValueOnce(withDetail)
      renderModal()
      fill()
      fireEvent.click(screen.getByRole('button', { name: 'Crear evento' }))
      await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Fecha pasada'))

      const plain = new Error('falló')
      mockedCreate.mockRejectedValueOnce(plain)
      fireEvent.click(screen.getByRole('button', { name: 'Crear evento' }))
      await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Error al crear el evento'))
      await new Promise((r) => setTimeout(r, 50))
    } finally {
      process.off('unhandledRejection', unhandled)
    }
    expect(unhandled).not.toHaveBeenCalled()
  })
})

describe('EventFormModal: envío en curso', () => {
  beforeEach(() => vi.clearAllMocks())

  it('mientras el servidor responde el botón dice "Creando..." y queda deshabilitado', async () => {
    mockedCreate.mockReturnValue(new Promise(() => {}))
    renderModal()
    fill()
    fireEvent.click(screen.getByRole('button', { name: 'Crear evento' }))
    const pending = await screen.findByRole('button', { name: 'Creando...' })
    expect(pending).toBeDisabled()
    expect(mockedCreate).toHaveBeenCalledTimes(1)
  })
})