import { describe, it, expect, beforeEach, vi } from 'vitest'

import axiosInstance from './axiosInstance'
import { createArtwork, getArtworkById, getArtworks } from './artworks.api'

vi.mock('./axiosInstance', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

const mockedAxios = vi.mocked(axiosInstance)

describe('artworks.api', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads artworks with params', async () => {
    const artworks = [{ id: 1, title: 'Montaña' }]
    mockedAxios.get.mockResolvedValueOnce({ data: artworks })

    await expect(getArtworks({ category: 'PINTURA' })).resolves.toBe(artworks)

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/artworks/', {
      params: { category: 'PINTURA' },
    })
  })

  it('loads an artwork by id', async () => {
    const artwork = { id: 1, title: 'Montaña' }
    mockedAxios.get.mockResolvedValueOnce({ data: artwork })

    await expect(getArtworkById(1)).resolves.toBe(artwork)

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/artworks/1/')
  })

  it('creates artworks', async () => {
    const artwork = { id: 1, title: 'Montaña' }
    const payload = {
      title: 'Montaña',
      description: 'Paisaje de Nariño',
      price: 120000,
      category: 1,
      technique: 'Óleo',
    }

    mockedAxios.post.mockResolvedValueOnce({ data: artwork })

    await expect(createArtwork(payload)).resolves.toBe(artwork)

    expect(mockedAxios.post).toHaveBeenCalledWith('/api/v1/artworks/', payload)
  })
})
