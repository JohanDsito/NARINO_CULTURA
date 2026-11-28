import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { deleteArtwork, getArtworkById, getArtworkCategories, updateArtwork } from '@/api/artworks.api'
import ArtworkEditPage from '@/pages/artist/ArtworkEditPage'
import { makeArtwork } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/artworks.api', () => ({
  getArtworkById: vi.fn(),
  updateArtwork: vi.fn(),
  deleteArtwork: vi.fn(),
  getArtworkCategories: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedGet = vi.mocked(getArtworkById)
const mockedUpdate = vi.mocked(updateArtwork)
const mockedDelete = vi.mocked(deleteArtwork)
const mockedCategories = vi.mocked(getArtworkCategories)

function renderPage() {
  return renderWithProviders(<ArtworkEditPage />, { route: '/dashboard/artworks/art-1/edit', path: '/dashboard/artworks/:id/edit' })
}

describe('ArtworkEditPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedCategories.mockResolvedValue([{ id: 1, name: 'Pintura', slug: 'pintura' }])
    mockedGet.mockResolvedValue(makeArtwork())
  })
  afterEach(() => vi.restoreAllMocks())

  it('carga la obra en el formulario', async () => {
    renderPage()
    expect(screen.getByText('Cargando obra…')).toBeInTheDocument()
    expect(await screen.findByLabelText('Título *')).toHaveValue('Volcán Galeras')
    expect(screen.getByLabelText('Descripción *')).toHaveValue('Óleo sobre lienzo')
    expect(screen.getByLabelText('Precio (COP)')).toHaveValue(350000)
    await waitFor(() => expect(screen.getByLabelText('Categoría')).toHaveValue('1'))
    expect(screen.getByLabelText('Técnica')).toHaveValue('Óleo')
    expect(screen.getByLabelText('Dimensiones')).toHaveValue('50x70')
    expect(screen.getByLabelText('Material')).toHaveValue('Lienzo')
    expect(mockedGet).toHaveBeenCalledWith('art-1')
    expect(screen.getByRole('button', { name: 'Guardar cambios' })).toBeDisabled()
  })

  it('una obra sin categoría deja el selector en "Sin categoría"', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ category: null }))
    renderPage()
    await screen.findByLabelText('Título *')
    await waitFor(() => expect(screen.getByLabelText('Título *')).toHaveValue('Volcán Galeras'))
    expect(screen.getByLabelText('Categoría')).toHaveValue('')
  })

  it('guarda los cambios y vuelve a mis obras', async () => {
    mockedUpdate.mockResolvedValue(makeArtwork())
    renderPage()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: 'Nuevo título' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra actualizada correctamente'))
    expect(mockedUpdate.mock.calls[0][0]).toBe('art-1')
    expect(mockedUpdate.mock.calls[0][1]).toMatchObject({ title: 'Nuevo título', category: 1, price: 350000 })
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/artworks')
  })

  it('sin categoría ni precio envía la categoría vacía como indefinida', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ category: null }))
    mockedUpdate.mockResolvedValue(makeArtwork())
    renderPage()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: 'Otro' } })
    fireEvent.change(screen.getByLabelText('Precio (COP)'), { target: { value: '' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(mockedUpdate).toHaveBeenCalled())
    expect(mockedUpdate.mock.calls[0][1]).toMatchObject({ title: 'Otro', category: undefined, price: undefined })
  })

  it('valida título y descripción', async () => {
    renderPage()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: '' } })
    fireEvent.change(screen.getByLabelText('Descripción *'), { target: { value: 'corta' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    expect(await screen.findByText('El título es requerido')).toBeInTheDocument()
    expect(screen.getByText('La descripción debe tener al menos 10 caracteres')).toBeInTheDocument()
    expect(mockedUpdate).not.toHaveBeenCalled()
  })

  it('si guardar falla avisa', async () => {
    mockedUpdate.mockRejectedValue(new Error('x'))
    renderPage()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: 'Otro' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo actualizar la obra.'))
  })

  it('eliminar pide confirmación; al aceptar borra y vuelve a mis obras', async () => {
    mockedDelete.mockResolvedValue(undefined)
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderPage()
    const button = await screen.findByRole('button', { name: 'Eliminar obra' })
    fireEvent.click(button)
    expect(mockedDelete).not.toHaveBeenCalled()
    confirm.mockReturnValue(true)
    fireEvent.click(button)
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra eliminada'))
    expect(mockedDelete.mock.calls[0][0]).toBe('art-1')
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/artworks')
  })

  it('si eliminar falla avisa', async () => {
    mockedDelete.mockRejectedValue(new Error('x'))
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: 'Eliminar obra' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo eliminar la obra.'))
  })

  it('si la obra no carga muestra el formulario vacío con subtítulo vacío', async () => {
    mockedGet.mockRejectedValue(new Error('404'))
    renderPage()
    expect(await screen.findByLabelText('Título *')).toHaveValue('')
  })
})
