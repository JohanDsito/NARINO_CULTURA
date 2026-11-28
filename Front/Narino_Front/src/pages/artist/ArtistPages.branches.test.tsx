import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { getMyArtistProfile } from '@/api/artists.api'
import { createArtwork, deleteArtwork, getArtworkById, getArtworkCategories, getArtworks, updateArtwork } from '@/api/artworks.api'
import ArtistArtworksPage from '@/pages/artist/ArtistArtworksPage'
import ArtworkCreatePage from '@/pages/artist/ArtworkCreatePage'
import ArtworkEditPage from '@/pages/artist/ArtworkEditPage'
import { useAuthStore } from '@/store/authStore'
import { makeArtwork, paginated } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'
import type { ArtistProfile, User } from '@/types'

vi.mock('@/api/artists.api', () => ({ getMyArtistProfile: vi.fn() }))
vi.mock('@/api/artworks.api', () => ({
  getArtworks: vi.fn(),
  deleteArtwork: vi.fn(),
  createArtwork: vi.fn(),
  getArtworkCategories: vi.fn(),
  getArtworkById: vi.fn(),
  updateArtwork: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedProfile = vi.mocked(getMyArtistProfile)
const mockedArtworks = vi.mocked(getArtworks)
const mockedDelete = vi.mocked(deleteArtwork)
const mockedCreate = vi.mocked(createArtwork)
const mockedCategories = vi.mocked(getArtworkCategories)
const mockedGet = vi.mocked(getArtworkById)
const mockedUpdate = vi.mocked(updateArtwork)

describe('ArtistArtworksPage: eliminar, errores y textos', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: '7', role: 'artist' } as User })
    mockedProfile.mockResolvedValue({ slug: 'ana' } as ArtistProfile)
  })
  afterEach(() => vi.restoreAllMocks())

  it('lista obras sin categoría ni técnica con sus textos por defecto y el plural', async () => {
    mockedArtworks.mockResolvedValue(
      paginated([
        makeArtwork({ id: 'a1', category_detail: null, technique: '' }),
        makeArtwork({ id: 'a2', title: 'Otra' }),
      ]),
    )
    renderWithProviders(<ArtistArtworksPage />)
    expect(await screen.findByText('Sin categoría')).toBeInTheDocument()
    expect(screen.getByText('Sin técnica')).toBeInTheDocument()
    expect(screen.getByText('2 obras registradas')).toBeInTheDocument()
  })

  it('una sola obra usa el singular', async () => {
    mockedArtworks.mockResolvedValue(paginated([makeArtwork()]))
    renderWithProviders(<ArtistArtworksPage />)
    expect(await screen.findByText('1 obra registrada')).toBeInTheDocument()
  })

  it('eliminar pide confirmación; cancelado no borra, aceptado borra y avisa; si falla avisa', async () => {
    mockedArtworks.mockResolvedValue(paginated([makeArtwork()]))
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderWithProviders(<ArtistArtworksPage />)
    const deleteButton = await screen.findByRole('button', { name: /Eliminar/ })
    fireEvent.click(deleteButton)
    expect(mockedDelete).not.toHaveBeenCalled()

    confirm.mockReturnValue(true)
    mockedDelete.mockResolvedValueOnce(undefined)
    fireEvent.click(deleteButton)
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra eliminada correctamente.'))
    expect(mockedDelete.mock.calls[0][0]).toBe('art-1')

    mockedDelete.mockRejectedValueOnce(new Error('x'))
    fireEvent.click(screen.getByRole('button', { name: /Eliminar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo eliminar la obra.'))
  })

  it('si no cargan las obras permite reintentar', async () => {
    mockedArtworks.mockRejectedValueOnce(new Error('x'))
    renderWithProviders(<ArtistArtworksPage />)
    expect(await screen.findByText('No fue posible cargar tus obras.')).toBeInTheDocument()
    mockedArtworks.mockResolvedValueOnce(paginated([makeArtwork({ title: 'Recuperada' })]))
    fireEvent.click(screen.getByRole('button', { name: 'Reintentar' }))
    expect(await screen.findByText('Recuperada')).toBeInTheDocument()
  })

  it('sin perfil de artista no pide obras y muestra el vacío', async () => {
    mockedProfile.mockResolvedValue(null)
    renderWithProviders(<ArtistArtworksPage />)
    expect(await screen.findByText('Aún no tienes obras registradas')).toBeInTheDocument()
    expect(mockedArtworks).not.toHaveBeenCalled()
  })
})

describe('ArtworkCreatePage: opcionales, error y espera', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedCategories.mockResolvedValue([{ id: 2, name: 'Escultura', slug: 'e' }])
  })

  function fillRequired() {
    fireEvent.change(screen.getByLabelText('Título *'), { target: { value: ' Obra ' } })
    fireEvent.change(screen.getByLabelText('Descripción *'), { target: { value: ' Descripción larga de la obra ' } })
  }

  it('sin opcionales los envía como indefinidos; mientras categorías cargan lo indica', async () => {
    mockedCreate.mockResolvedValue(makeArtwork())
    renderWithProviders(<ArtworkCreatePage />, { route: '/dashboard/artworks/new', path: '/dashboard/artworks/new' })
    expect(screen.getByText('Cargando categorías...')).toBeInTheDocument()
    await screen.findByRole('option', { name: 'Escultura' })
    fillRequired()
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    await waitFor(() => expect(mockedCreate).toHaveBeenCalled())
    expect(mockedCreate.mock.calls[0][0]).toMatchObject({
      title: 'Obra', description: 'Descripción larga de la obra', category: undefined, technique: undefined,
      price: undefined, dimensions: undefined, material: undefined,
    })
  })

  it('con todos los opcionales los envía recortados', async () => {
    mockedCreate.mockResolvedValue(makeArtwork())
    renderWithProviders(<ArtworkCreatePage />, { route: '/dashboard/artworks/new', path: '/dashboard/artworks/new' })
    await screen.findByRole('option', { name: 'Escultura' })
    fillRequired()
    fireEvent.change(screen.getByLabelText('Categoría'), { target: { value: '2' } })
    fireEvent.change(screen.getByLabelText('Precio (COP)'), { target: { value: '90000' } })
    fireEvent.change(screen.getByLabelText('Técnica'), { target: { value: ' Talla ' } })
    fireEvent.change(screen.getByLabelText('Dimensiones'), { target: { value: ' 1x1 ' } })
    fireEvent.change(screen.getByLabelText('Material'), { target: { value: ' Madera ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    await waitFor(() => expect(mockedCreate).toHaveBeenCalled())
    expect(mockedCreate.mock.calls[0][0]).toMatchObject({ category: 2, price: 90000, technique: 'Talla', dimensions: '1x1', material: 'Madera' })
  })

  it.each(['0', '-5'])('un precio cero o negativo (%s) se rechaza', async (precio) => {
    renderWithProviders(<ArtworkCreatePage />)
    fillRequired()
    fireEvent.change(screen.getByLabelText('Precio (COP)'), { target: { value: precio } })
    fireEvent.submit(screen.getByRole('button', { name: 'Guardar obra' }).closest('form')!)
    expect(await screen.findByText('El precio debe ser mayor a 0.')).toBeInTheDocument()
    expect(mockedCreate).not.toHaveBeenCalled()
  })

  it('si el servidor rechaza muestra el error; mientras guarda dice "Guardando..."', async () => {
    let reject!: (e: Error) => void
    mockedCreate.mockReturnValueOnce(new Promise((_, r) => { reject = r }))
    renderWithProviders(<ArtworkCreatePage />)
    fillRequired()
    fireEvent.click(screen.getByRole('button', { name: 'Guardar obra' }))
    expect(await screen.findByRole('button', { name: 'Guardando...' })).toBeDisabled()
    reject(new Error('Título repetido'))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Título repetido'))
  })
})

describe('ArtworkEditPage: textos de espera', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedCategories.mockResolvedValue([])
    mockedGet.mockResolvedValue(makeArtwork())
  })
  afterEach(() => vi.restoreAllMocks())

  function renderEdit() {
    return renderWithProviders(<ArtworkEditPage />, { route: '/dashboard/artworks/art-1/edit', path: '/dashboard/artworks/:id/edit' })
  }

  it('mientras guarda dice "Guardando…"', async () => {
    mockedUpdate.mockReturnValue(new Promise(() => {}))
    renderEdit()
    fireEvent.change(await screen.findByLabelText('Título *'), { target: { value: 'Nuevo' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    expect(await screen.findByRole('button', { name: 'Guardando…' })).toBeDisabled()
  })

  it('mientras elimina dice "Eliminando…"', async () => {
    mockedDelete.mockReturnValue(new Promise(() => {}))
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderEdit()
    fireEvent.click(await screen.findByRole('button', { name: 'Eliminar obra' }))
    expect(await screen.findByRole('button', { name: 'Eliminando…' })).toBeDisabled()
  })
})
