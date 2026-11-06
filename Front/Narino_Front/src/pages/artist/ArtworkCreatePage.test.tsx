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
  const queryClient = new QueryClient()

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/dashboard/artworks/new']}>
        <Routes>
          <Route path="/dashboard/artworks/new" element={<ArtworkCreatePage />} />
          <Route path="/dashboard/profile" element={<div>Panel de artista</div>} />
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
      { id: 2, name: 'Musica', slug: 'musica' },
    ])
  })

  it('validates required fields before creating an artwork', async () => {
    const user = userEvent.setup()

    renderArtworkCreatePage()

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    expect(await screen.findByText(/el titulo es obligatorio/i)).toBeInTheDocument()
    expect(mockedCreateArtwork).not.toHaveBeenCalled()
  })

  it('submits artwork payload with category id and returns to artist dashboard', async () => {
    const user = userEvent.setup()

    mockedCreateArtwork.mockResolvedValueOnce(
      {} as Awaited<ReturnType<typeof createArtwork>>,
    )

    renderArtworkCreatePage()

    await user.type(screen.getByLabelText(/titulo/i), 'Montana viva')
    await user.type(
      screen.getByLabelText(/descripcion/i),
      'Paisaje inspirado en Narino',
    )
    await user.selectOptions(await screen.findByLabelText(/categoria/i), '1')
    await user.type(screen.getByLabelText(/tecnica/i), 'Oleo')
    await user.clear(screen.getByLabelText(/precio/i))
    await user.type(screen.getByLabelText(/precio/i), '120000')
    await user.type(screen.getByLabelText(/ano/i), '2024')
    await user.type(screen.getByLabelText(/dimensiones/i), '40 x 60 cm')

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    await waitFor(() => {
      expect(mockedCreateArtwork).toHaveBeenCalledWith({
        title: 'Montana viva',
        description: 'Paisaje inspirado en Narino',
        category: 1,
        technique: 'Oleo',
        price: 120000,
        dimensions: '40 x 60 cm',
        year: 2024,
        image_url: undefined,
      })
    })

    expect(await screen.findByText('Panel de artista')).toBeInTheDocument()
  })

  it('submits music payload with category id and mp3 demo', async () => {
    const user = userEvent.setup()
    const demo = new File(['demo'], 'cancion.mp3', { type: 'audio/mpeg' })

    mockedCreateArtwork.mockResolvedValueOnce(
      {} as Awaited<ReturnType<typeof createArtwork>>,
    )

    renderArtworkCreatePage()

    await user.type(screen.getByLabelText(/titulo/i), 'Cancion del sur')
    await user.type(
      screen.getByLabelText(/descripcion/i),
      'Demo musical inspirado en Narino',
    )
    await user.selectOptions(await screen.findByLabelText(/categoria/i), '2')
    await user.type(screen.getByLabelText(/fecha de lanzamiento/i), '2026-05-01')
    await user.type(screen.getByLabelText(/compositor/i), 'Ana Mora')
    await user.type(screen.getByLabelText(/genero/i), 'Andina')
    await user.upload(screen.getByLabelText(/subir demo mp3/i), demo)

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    await waitFor(() => {
      expect(mockedCreateArtwork).toHaveBeenCalledWith({
        title: 'Cancion del sur',
        description: 'Demo musical inspirado en Narino',
        category: 2,
        release_date: '2026-05-01',
        composer: 'Ana Mora',
        genre: 'Andina',
        demo,
      })
    })
  })
})
