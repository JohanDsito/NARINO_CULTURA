import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import {
  createMusicalWork,
  deleteMusicalWork,
  getMusicalWork,
  listMyMusicalWorks,
  updateMusicalWork,
} from '@/api/musicians.api'
import MusicianWorkCreatePage from '@/pages/musicians/MusicianWorkCreatePage'
import MusicianWorkEditPage from '@/pages/musicians/MusicianWorkEditPage'
import MusicianWorksPage from '@/pages/musicians/MusicianWorksPage'
import { renderWithProviders } from '@/test/render'
import type { MusicalWork } from '@/types'

vi.mock('@/api/musicians.api', () => ({
  listMyMusicalWorks: vi.fn(),
  deleteMusicalWork: vi.fn(),
  createMusicalWork: vi.fn(),
  getMusicalWork: vi.fn(),
  updateMusicalWork: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedList = vi.mocked(listMyMusicalWorks)
const mockedDelete = vi.mocked(deleteMusicalWork)
const mockedCreate = vi.mocked(createMusicalWork)
const mockedGet = vi.mocked(getMusicalWork)
const mockedUpdate = vi.mocked(updateMusicalWork)

function work(overrides: Partial<MusicalWork> = {}): MusicalWork {
  return {
    id: 'w1',
    musician: 'm1',
    title: 'Canción del volcán',
    work_type: 'STUDIO',
    youtube_url: 'https://youtube.com/x',
    soundcloud_embed: 'https://soundcloud.com/x',
    spotify_track_url: 'https://open.spotify.com/x',
    audio_file: '',
    thumbnail: '',
    description: 'Una descripción',
    release_date: '2025-06-01',
    views_count: 7,
    is_featured: false,
    created_at: '',
    updated_at: '',
    ...overrides,
  }
}

describe('MusicianWorksPage', () => {
  beforeEach(() => vi.clearAllMocks())
  afterEach(() => vi.restoreAllMocks())

  it('muestra cargando y luego la lista con tipo, año, destacada, visitas y enlace de edición', async () => {
    mockedList.mockResolvedValue([
      work(),
      work({ id: 'w2', title: 'Destacada', work_type: 'RARO' as MusicalWork['work_type'], release_date: undefined, is_featured: true }),
    ])
    renderWithProviders(<MusicianWorksPage />)
    expect(screen.getByText('Cargando obras...')).toBeInTheDocument()
    expect(await screen.findByText('Canción del volcán')).toBeInTheDocument()
    expect(screen.getByText('Estudio')).toBeInTheDocument()
    expect(screen.getByText('2025')).toBeInTheDocument()
    expect(screen.getByText('RARO')).toBeInTheDocument()
    expect(screen.getByText('Destacada', { selector: '[class*="text-xs"]' })).toBeInTheDocument()
    expect(screen.getAllByText('7 visitas')).toHaveLength(2)
    const edit = document.querySelector('a[href="/dashboard/musician/works/w1/edit"]')
    expect(edit).not.toBeNull()
  })

  it('sin obras invita a añadir la primera', async () => {
    mockedList.mockResolvedValue([])
    renderWithProviders(<MusicianWorksPage />)
    expect(await screen.findByText('Aún no tienes obras')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Añadir primera obra' })).toHaveAttribute('href', '/dashboard/musician/works/new')
  })

  it('eliminar pide confirmación y avisa del resultado', async () => {
    mockedList.mockResolvedValue([work()])
    mockedDelete.mockResolvedValueOnce(undefined)
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderWithProviders(<MusicianWorksPage />)
    await screen.findByText('Canción del volcán')
    const deleteButton = screen.getAllByRole('button').find((b) => b.className.includes('text-error'))!
    fireEvent.click(deleteButton)
    expect(confirm).toHaveBeenCalledWith('¿Eliminar "Canción del volcán"? Esta acción no se puede deshacer.')
    expect(mockedDelete).not.toHaveBeenCalled()

    confirm.mockReturnValue(true)
    fireEvent.click(deleteButton)
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra eliminada.'))
    expect(mockedDelete.mock.calls[0][0]).toBe('w1')

    mockedDelete.mockRejectedValueOnce(new Error('x'))
    fireEvent.click(deleteButton)
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo eliminar la obra.'))
  })
})

describe('MusicianWorkCreatePage', () => {
  beforeEach(() => vi.clearAllMocks())

  function renderCreate() {
    return renderWithProviders(<MusicianWorkCreatePage />, { route: '/dashboard/musician/works/new', path: '/dashboard/musician/works/new' })
  }

  it('crea la obra con campos recortados y vacíos como indefinidos, y vuelve a la lista', async () => {
    mockedCreate.mockResolvedValue(work())
    renderCreate()
    fireEvent.change(screen.getByLabelText('Título *'), { target: { value: '  Mi canción ' } })
    fireEvent.change(screen.getByLabelText('Tipo de obra'), { target: { value: 'LIVE' } })
    fireEvent.change(screen.getByLabelText('Fecha de lanzamiento'), { target: { value: '2026-02-03' } })
    fireEvent.change(screen.getByLabelText('URL de YouTube'), { target: { value: ' https://youtube.com/a ' } })
    fireEvent.change(screen.getByLabelText('URL de Spotify'), { target: { value: 'https://open.spotify.com/a' } })
    fireEvent.change(screen.getByLabelText('Embed de SoundCloud'), { target: { value: 'https://soundcloud.com/a' } })
    fireEvent.change(screen.getByLabelText('Descripción'), { target: { value: ' Hola ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra musical creada.'))
    expect(mockedCreate.mock.calls[0][0]).toEqual({
      title: 'Mi canción',
      work_type: 'LIVE',
      youtube_url: 'https://youtube.com/a',
      soundcloud_embed: 'https://soundcloud.com/a',
      spotify_track_url: 'https://open.spotify.com/a',
      description: 'Hola',
      release_date: '2026-02-03',
    })
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/musician/works')
  })

  it('con solo el título los demás campos van como indefinidos', async () => {
    mockedCreate.mockResolvedValue(work())
    renderCreate()
    fireEvent.change(screen.getByLabelText('Título *'), { target: { value: 'Solo título' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    await waitFor(() => expect(mockedCreate).toHaveBeenCalled())
    expect(mockedCreate.mock.calls[0][0]).toEqual({
      title: 'Solo título', work_type: 'STUDIO', youtube_url: undefined, soundcloud_embed: undefined,
      spotify_track_url: undefined, description: undefined, release_date: undefined,
    })
  })

  it('sin título avisa y no llama al servicio', async () => {
    renderCreate()
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El título es obligatorio.'))
    expect(mockedCreate).not.toHaveBeenCalled()
  })

  it('si el servicio falla con un error que no es Error usa el mensaje genérico', async () => {
    mockedCreate.mockRejectedValue('boom')
    renderCreate()
    fireEvent.change(screen.getByLabelText('Título *'), { target: { value: 'X' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No fue posible crear la obra.'))
  })
})

describe('MusicianWorkEditPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedGet.mockResolvedValue(work())
  })

  function renderEdit() {
    return renderWithProviders(<MusicianWorkEditPage />, { route: '/dashboard/musician/works/w1/edit', path: '/dashboard/musician/works/:id/edit' })
  }

  it('carga la obra en el formulario', async () => {
    renderEdit()
    expect(screen.getByText('Cargando obra...')).toBeInTheDocument()
    expect(await screen.findByLabelText('Título *')).toHaveValue('Canción del volcán')
    expect(mockedGet).toHaveBeenCalledWith('w1')
    expect(screen.getByLabelText('Tipo de obra')).toHaveValue('STUDIO')
    expect(screen.getByLabelText('Fecha de lanzamiento')).toHaveValue('2025-06-01')
    expect(screen.getByLabelText('URL de YouTube')).toHaveValue('https://youtube.com/x')
    expect(screen.getByLabelText('Descripción')).toHaveValue('Una descripción')
  })

  it('obra con campos nulos rellena el formulario con valores por defecto', async () => {
    mockedGet.mockResolvedValue({
      ...work(), title: null, work_type: null, youtube_url: null, soundcloud_embed: null,
      spotify_track_url: null, description: null, release_date: null,
    } as unknown as MusicalWork)
    renderEdit()
    expect(await screen.findByLabelText('Título *')).toHaveValue('')
    expect(screen.getByLabelText('Tipo de obra')).toHaveValue('STUDIO')
    expect(screen.getByLabelText('Fecha de lanzamiento')).toHaveValue('')
  })

  it('guarda cambios, normaliza y vuelve a la lista', async () => {
    mockedUpdate.mockResolvedValue(work())
    renderEdit()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: ' Nuevo ' } })
    fireEvent.change(screen.getByLabelText('Tipo de obra'), { target: { value: 'VIDEO' } })
    fireEvent.change(screen.getByLabelText('URL de YouTube'), { target: { value: ' https://y.test ' } })
    fireEvent.change(screen.getByLabelText('URL de Spotify'), { target: { value: '' } })
    fireEvent.change(screen.getByLabelText('Embed de SoundCloud'), { target: { value: 's' } })
    fireEvent.change(screen.getByLabelText('Descripción'), { target: { value: ' d ' } })
    fireEvent.change(screen.getByLabelText('Fecha de lanzamiento'), { target: { value: '' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra actualizada.'))
    expect(mockedUpdate.mock.calls[0]).toEqual([
      'w1',
      { title: 'Nuevo', work_type: 'VIDEO', youtube_url: 'https://y.test', soundcloud_embed: 's', spotify_track_url: '', description: 'd', release_date: undefined },
    ])
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/musician/works')
  })

  it('sin título avisa; si el servicio falla avisa con el mensaje o el genérico', async () => {
    renderEdit()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: ' ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El título es obligatorio.'))
    expect(mockedUpdate).not.toHaveBeenCalled()

    fireEvent.change(screen.getByLabelText('Título *'), { target: { value: 'ok' } })
    mockedUpdate.mockRejectedValueOnce(new Error('Servidor'))
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Servidor'))
    mockedUpdate.mockRejectedValueOnce('boom')
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No fue posible actualizar la obra.'))
  })

  it('obra inexistente: muestra el error y vuelve a la lista', async () => {
    mockedGet.mockRejectedValue(new Error('404'))
    renderEdit()
    expect(await screen.findByText('No se encontró la obra.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Volver a mis obras' })).toHaveAttribute('href', '/dashboard/musician/works')
  })
})
