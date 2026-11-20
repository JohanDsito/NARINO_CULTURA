import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { createArtwork, getArtworkCategories } from '@/api/artworks.api'
import ArtworkCreatePage from '@/pages/artist/ArtworkCreatePage'

vi.mock('@/api/artworks.api', () => ({
  createArtwork: vi.fn(),
  getArtworkCategories: vi.fn(),
}))

vi.mock('sonner', () => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
  },
}))

const mockedCreateArtwork = vi.mocked(createArtwork)
const mockedGetArtworkCategories = vi.mocked(getArtworkCategories)

function renderArtworkCreatePage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/dashboard/artworks/new']}>
        <Routes>
          <Route path="/dashboard/artworks/new" element={<ArtworkCreatePage />} />
          <Route path="/dashboard/artworks" element={<div>Mis obras</div>} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('ArtworkCreatePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedGetArtworkCategories.mockResolvedValue([
      { id: 1, name: 'Pintura', slug: 'pintura' },
      { id: 2, name: 'Escultura', slug: 'escultura' },
    ])
  })

  it('validates required fields before creating an artwork', async () => {
    const user = userEvent.setup()

    renderArtworkCreatePage()

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    expect(await screen.findByText(/el título es obligatorio/i)).toBeInTheDocument()
    expect(mockedCreateArtwork).not.toHaveBeenCalled()
  })

  it('submits the artwork with numeric category and price, then returns to my artworks', async () => {
    const user = userEvent.setup()

    mockedCreateArtwork.mockResolvedValueOnce({} as Awaited<ReturnType<typeof createArtwork>>)

    renderArtworkCreatePage()

    await user.type(screen.getByLabelText(/título/i), '  Montaña viva  ')
    await user.type(screen.getByLabelText(/descripción/i), 'Paisaje inspirado en Nariño')
    // Esperar a que carguen las categorías antes de elegir una
    await screen.findByRole('option', { name: 'Pintura' })
    await user.selectOptions(screen.getByLabelText(/categoría/i), '1')
    await user.type(screen.getByLabelText(/técnica/i), 'Óleo')
    await user.type(screen.getByLabelText(/precio/i), '120000')
    await user.type(screen.getByLabelText(/dimensiones/i), '40 x 60 cm')

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    await waitFor(() => {
      expect(mockedCreateArtwork).toHaveBeenCalledWith({
        title: 'Montaña viva',
        description: 'Paisaje inspirado en Nariño',
        category: 1,
        technique: 'Óleo',
        price: 120000,
        dimensions: '40 x 60 cm',
        material: undefined,
        main_image: undefined,
      })
    })

    expect(await screen.findByText('Mis obras')).toBeInTheDocument()
  })
})
