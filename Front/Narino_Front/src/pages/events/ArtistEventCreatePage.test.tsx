import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { eventsApi } from '@/api/events.api'
import ArtistEventCreatePage from '@/pages/events/ArtistEventCreatePage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

vi.mock('@/api/events.api', () => ({ eventsApi: { createArtistEvent: vi.fn() } }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedCreate = vi.mocked(eventsApi.createArtistEvent)

function renderPage() {
  return renderWithProviders(<ArtistEventCreatePage />, { route: '/dashboard/events/new', path: '/dashboard/events/new' })
}

function fillRequired() {
  fireEvent.change(screen.getByLabelText('Nombre del evento *'), { target: { value: '  Concierto andino ' } })
  fireEvent.change(screen.getByLabelText('Tipo de evento *'), { target: { value: 'CONCIERTO' } })
  fireEvent.change(screen.getByLabelText('Lugar *'), { target: { value: ' Teatro Imperial ' } })
  fireEvent.change(screen.getByLabelText('Fecha y hora de inicio *'), { target: { value: '2026-06-01T19:00' } })
}

describe('ArtistEventCreatePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    useAuthStore.setState({ user: { id: 'u1' } as User })
    mockedCreate.mockResolvedValue({} as never)
  })
  afterEach(() => vi.unstubAllGlobals())

  it('valida los campos obligatorios y la URL de entradas', async () => {
    renderPage()
    fireEvent.submit(screen.getByRole('button', { name: 'Enviar evento' }).closest('form')!)
    expect(await screen.findByText('El nombre del evento es obligatorio.')).toBeInTheDocument()
    expect(screen.getByText('Selecciona un tipo de evento.')).toBeInTheDocument()
    expect(screen.getByText('El lugar es obligatorio.')).toBeInTheDocument()
    expect(screen.getByText('La fecha es obligatoria.')).toBeInTheDocument()
    expect(mockedCreate).not.toHaveBeenCalled()
  })

  it('rechaza una URL de entradas inválida', async () => {
    renderPage()
    fillRequired()
    const input = screen.getByLabelText(/Link de compra de entradas/)
    fireEvent.change(input, { target: { value: 'esto no es url' } })
    // submit directo: el clic en el botón lo frenaría la validación nativa de type="url"
    fireEvent.submit(screen.getByRole('button', { name: 'Enviar evento' }).closest('form')!)
    expect(await screen.findByText('Ingresa una URL válida.')).toBeInTheDocument()
  })

  it('envía el evento con valores recortados, fin = inicio por defecto y vuelve al panel', async () => {
    renderPage()
    fillRequired()
    fireEvent.click(screen.getByRole('button', { name: 'Enviar evento' }))
    await waitFor(() => expect(mockedCreate).toHaveBeenCalled())
    expect(mockedCreate.mock.calls[0][0]).toEqual({
      title: 'Concierto andino',
      event_type: 'CONCIERTO',
      location: 'Teatro Imperial',
      start_date: '2026-06-01T19:00',
      end_date: '2026-06-01T19:00',
      description: '',
      ticket_url: undefined,
      flyer: undefined,
      image_url: undefined,
      is_published: false,
    })
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Evento enviado para aprobación', expect.any(Object)))
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/profile')
  })

  it('para músicos vuelve al perfil de músico', async () => {
    localStorage.setItem('artist_discipline_u1', 'musico')
    renderPage()
    expect(screen.getByRole('link', { name: 'Cancelar' })).toHaveAttribute('href', '/dashboard/musician/profile')
    fillRequired()
    fireEvent.click(screen.getByRole('button', { name: 'Enviar evento' }))
    await waitFor(() => expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/musician/profile'))
  })

  it('sin sesión usa un id vacío y el panel por defecto', () => {
    useAuthStore.setState({ user: null })
    renderPage()
    expect(screen.getByRole('link', { name: /Volver/ })).toHaveAttribute('href', '/dashboard/profile')
  })

  it('incluye fecha de fin, descripción, enlace de entradas y la URL del flyer con vista previa', async () => {
    renderPage()
    fillRequired()
    fireEvent.change(screen.getByLabelText('Fecha y hora de fin'), { target: { value: '2026-06-01T22:00' } })
    fireEvent.change(screen.getByLabelText('Descripción'), { target: { value: ' Una noche ' } })
    fireEvent.change(screen.getByLabelText(/Link de compra de entradas/), { target: { value: 'https://tuboleta.com/x' } })
    fireEvent.change(screen.getByPlaceholderText(/drive.google.com/), { target: { value: ' https://img.test/flyer.jpg ' } })
    const preview = screen.getByAltText('Vista previa')
    fireEvent.error(preview)
    expect(preview.style.display).toBe('none')
    fireEvent.click(screen.getByRole('button', { name: 'Enviar evento' }))
    await waitFor(() => expect(mockedCreate).toHaveBeenCalled())
    expect(mockedCreate.mock.calls[0][0]).toMatchObject({
      end_date: '2026-06-01T22:00',
      description: 'Una noche',
      ticket_url: 'https://tuboleta.com/x',
      image_url: 'https://img.test/flyer.jpg',
      flyer: undefined,
    })
  })

  it('sube un archivo de flyer, lo previsualiza, lo quita y lo envía', async () => {
    vi.stubGlobal('URL', Object.assign(URL, { createObjectURL: vi.fn(() => 'blob:flyer'), revokeObjectURL: vi.fn() }))
    const { container } = renderPage()
    fillRequired()
    fireEvent.click(screen.getByRole('button', { name: /Subir archivo/ }))
    expect(screen.getByText(/La subida de archivos requiere activación/)).toBeInTheDocument()
    const input = container.querySelector('input[type="file"]') as HTMLInputElement
    const clicked = vi.spyOn(input, 'click')
    fireEvent.click(screen.getByRole('button', { name: /Subir flyer desde tu computador/ }))
    expect(clicked).toHaveBeenCalled()

    fireEvent.change(input, { target: { files: [] } })
    expect(screen.queryByAltText('Vista previa del flyer')).not.toBeInTheDocument()

    const file = new File(['x'], 'flyer.png', { type: 'image/png' })
    fireEvent.change(input, { target: { files: [file] } })
    expect(screen.getByAltText('Vista previa del flyer')).toHaveAttribute('src', 'blob:flyer')
    expect(screen.getByText('flyer.png')).toBeInTheDocument()

    // quitar y volver a elegir
    fireEvent.click(screen.getByAltText('Vista previa del flyer').nextElementSibling!)
    expect(screen.queryByAltText('Vista previa del flyer')).not.toBeInTheDocument()
    fireEvent.change(input, { target: { files: [file] } })

    fireEvent.click(screen.getByRole('button', { name: 'Enviar evento' }))
    await waitFor(() => expect(mockedCreate).toHaveBeenCalled())
    expect(mockedCreate.mock.calls[0][0]).toMatchObject({ flyer: file, image_url: undefined })
  })

  it('cambiar entre pestañas de flyer conserva la URL escrita', () => {
    renderPage()
    fireEvent.change(screen.getByPlaceholderText(/drive.google.com/), { target: { value: 'https://img.test/a.jpg' } })
    fireEvent.click(screen.getByRole('button', { name: /Subir archivo/ }))
    fireEvent.click(screen.getByRole('button', { name: /URL de imagen/ }))
    expect(screen.getByPlaceholderText(/drive.google.com/)).toHaveValue('https://img.test/a.jpg')
  })

  it('si el servidor rechaza el evento muestra el error y no navega', async () => {
    mockedCreate.mockRejectedValue(new Error('Fecha inválida'))
    renderPage()
    fillRequired()
    fireEvent.click(screen.getByRole('button', { name: 'Enviar evento' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Fecha inválida'))
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/events/new')
  })
})
