import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { deleteAdminArtwork, getAllArtworks, getPendingArtworks, moderateArtwork } from '@/api/admin.api'
import AdminArtworksPage from '@/pages/admin/AdminArtworksPage'
import { makeArtwork } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/admin.api', () => ({
  getPendingArtworks: vi.fn(),
  getAllArtworks: vi.fn(),
  moderateArtwork: vi.fn(),
  deleteAdminArtwork: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedPending = vi.mocked(getPendingArtworks)
const mockedAll = vi.mocked(getAllArtworks)
const mockedModerate = vi.mocked(moderateArtwork)
const mockedDelete = vi.mocked(deleteAdminArtwork)

const PENDING = { id: 'p1', title: 'Pendiente uno', artist_slug: 'ana', price: '1000', created_at: '' }

describe('AdminArtworksPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedPending.mockResolvedValue([PENDING])
    mockedAll.mockResolvedValue([
      makeArtwork({ id: 'a1', title: 'Con principal' }),
      makeArtwork({ id: 'a2', title: 'Con galería', main_image_url: '', category_detail: null, images: [{ id: 'i', image_url: 'https://img.test/g.jpg', order: 0 }] }),
      makeArtwork({ id: 'a3', title: 'Sin imagen', main_image_url: '', images: [] }),
    ])
  })
  afterEach(() => vi.restoreAllMocks())

  it('pestaña de pendientes: resumen, contador, artista y acciones de moderación', async () => {
    renderWithProviders(<AdminArtworksPage />)
    expect(await screen.findByText('Pendiente uno')).toBeInTheDocument()
    expect(screen.getByText('1 obra pendiente de revisión')).toBeInTheDocument()
    expect(screen.getByText('ana')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Aprobar/ })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Rechazar/ })).toBeInTheDocument()
  })

  it('aprueba y rechaza una obra pendiente, con aviso y recarga', async () => {
    mockedModerate.mockResolvedValue(makeArtwork())
    renderWithProviders(<AdminArtworksPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Aprobar/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra aprobada'))
    expect(mockedModerate).toHaveBeenCalledWith('p1', { status: 'DISPONIBLE', reason: undefined })
    fireEvent.click(screen.getByRole('button', { name: /Rechazar/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra rechazada'))
    expect(mockedModerate).toHaveBeenLastCalledWith('p1', { status: 'INACTIVA', reason: 'No cumple los requisitos' })
  })

  it('si la moderación falla avisa', async () => {
    mockedModerate.mockRejectedValue(new Error('x'))
    renderWithProviders(<AdminArtworksPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Aprobar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo procesar la acción'))
  })

  it('pestaña de todas: plural, imágenes, categoría y estado; sin acciones de moderación', async () => {
    renderWithProviders(<AdminArtworksPage />)
    await screen.findByText('Pendiente uno')
    fireEvent.click(screen.getByRole('button', { name: /Todas las obras/ }))
    expect(await screen.findByText('Con principal')).toBeInTheDocument()
    expect(screen.getByText('3 obras en la plataforma')).toBeInTheDocument()
    expect(screen.getByAltText('Con galería')).toHaveAttribute('src', 'https://img.test/g.jpg')
    expect(screen.queryByAltText('Sin imagen')).not.toBeInTheDocument()
    expect(screen.getAllByText('Pintura')).toHaveLength(2)
    expect(screen.getAllByText('Disponible')).toHaveLength(3)
    expect(screen.queryByRole('button', { name: /Aprobar/ })).not.toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /Pendientes de moderación/ }))
    expect(await screen.findByText('Pendiente uno')).toBeInTheDocument()
  })

  it('"Ver" abre la obra en otra pestaña', async () => {
    const open = vi.spyOn(window, 'open').mockReturnValue(null)
    renderWithProviders(<AdminArtworksPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Ver/ }))
    expect(open).toHaveBeenCalledWith('/artworks/p1', '_blank', 'noopener')
  })

  it('eliminar pide confirmación; si se cancela no borra y si se acepta borra y avisa', async () => {
    mockedDelete.mockResolvedValue(undefined)
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderWithProviders(<AdminArtworksPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Eliminar/ }))
    expect(confirm).toHaveBeenCalledWith('¿Eliminar permanentemente "Pendiente uno"? Esta acción no se puede deshacer.')
    expect(mockedDelete).not.toHaveBeenCalled()

    confirm.mockReturnValue(true)
    fireEvent.click(screen.getByRole('button', { name: /Eliminar/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra eliminada.'))
    expect(mockedDelete.mock.calls[0][0]).toBe('p1')
  })

  it('si eliminar falla avisa', async () => {
    mockedDelete.mockRejectedValue(new Error('x'))
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderWithProviders(<AdminArtworksPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Eliminar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo eliminar la obra.'))
  })

  it('vacíos de cada pestaña y plural de pendientes', async () => {
    mockedPending.mockResolvedValue([PENDING, { ...PENDING, id: 'p2' }])
    const { unmount } = renderWithProviders(<AdminArtworksPage />)
    expect(await screen.findByText('2 obras pendientes de revisión')).toBeInTheDocument()
    unmount()

    mockedPending.mockResolvedValue([])
    mockedAll.mockResolvedValue([])
    renderWithProviders(<AdminArtworksPage />)
    expect(await screen.findByText('No hay obras pendientes de moderación.')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /Todas las obras/ }))
    expect(await screen.findByText('No hay obras registradas.')).toBeInTheDocument()
    expect(screen.getByText('0 obras en la plataforma')).toBeInTheDocument()
  })

  it('una sola obra en la plataforma usa el singular', async () => {
    mockedAll.mockResolvedValue([makeArtwork()])
    renderWithProviders(<AdminArtworksPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Todas las obras/ }))
    expect(await screen.findByText('1 obra en la plataforma')).toBeInTheDocument()
  })
})
