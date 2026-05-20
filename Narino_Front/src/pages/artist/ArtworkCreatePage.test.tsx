import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { createArtwork } from '@/api/artworks.api'
import ArtworkCreatePage from '@/pages/artist/ArtworkCreatePage'

vi.mock('@/api/artworks.api', () => ({
  createArtwork: vi.fn(),
}))

vi.mock('sonner', () => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
  },
}))

const mockedCreateArtwork = vi.mocked(createArtwork)

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
  })

  it('validates required fields before creating an artwork', async () => {
    const user = userEvent.setup()

    renderArtworkCreatePage()

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    expect(await screen.findByText(/el titulo es obligatorio/i)).toBeInTheDocument()
    expect(mockedCreateArtwork).not.toHaveBeenCalled()
  })

  it('submits artwork payload and returns to artist dashboard', async () => {
    const user = userEvent.setup()

    mockedCreateArtwork.mockResolvedValueOnce(
      {} as Awaited<ReturnType<typeof createArtwork>>,
    )

    renderArtworkCreatePage()

    await user.type(screen.getByLabelText(/titulo/i), 'Montaña viva')
    await user.type(
      screen.getByLabelText(/descripcion/i),
      'Paisaje inspirado en Nariño',
    )
    await user.selectOptions(screen.getByLabelText(/categoria/i), 'PINTURA')
    await user.type(screen.getByLabelText(/tecnica/i), 'Óleo')
    await user.clear(screen.getByLabelText(/precio/i))
    await user.type(screen.getByLabelText(/precio/i), '120000')
    await user.type(screen.getByLabelText(/año/i), '2024')
    await user.type(screen.getByLabelText(/dimensiones/i), '40 x 60 cm')

    await user.click(screen.getByRole('button', { name: /guardar obra/i }))

    await waitFor(() => {
      expect(mockedCreateArtwork).toHaveBeenCalledWith({
        title: 'Montaña viva',
        description: 'Paisaje inspirado en Nariño',
        category: 'PINTURA',
        technique: 'Óleo',
        price: 120000,
        dimensions: '40 x 60 cm',
        year: 2024,
        image_url: undefined,
      })
    })

    expect(await screen.findByText('Panel de artista')).toBeInTheDocument()
  })
})
