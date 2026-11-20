import { describe, it, expect, beforeEach, vi } from 'vitest'

import axiosInstance from './axiosInstance'
import {
  createArtwork,
  deleteArtwork,
  getArtworkById,
  getArtworkCategories,
  getArtworks,
} from './artworks.api'

vi.mock('./axiosInstance', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockedAxios = vi.mocked(axiosInstance)

describe('artworks.api', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('wraps a plain list response in a paginated shape', async () => {
    const artworks = [{ id: '1', title: 'Montaña' }]
    mockedAxios.get.mockResolvedValueOnce({ data: artworks })

    await expect(getArtworks({ category: 'PINTURA' })).resolves.toEqual({
      count: 1,
      next: null,
      previous: null,
      results: artworks,
    })

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/artworks/', {
      params: { category: 'PINTURA' },
    })
  })

  it('returns paginated responses as they come', async () => {
    const page = { count: 1, next: null, previous: null, results: [{ id: '1', title: 'Montaña' }] }
    mockedAxios.get.mockResolvedValueOnce({ data: page })

    await expect(getArtworks()).resolves.toBe(page)

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/artworks/', { params: undefined })
  })

  it('loads an artwork by id', async () => {
    const artwork = { id: '1', title: 'Montaña' }
    mockedAxios.get.mockResolvedValueOnce({ data: artwork })

    await expect(getArtworkById(1)).resolves.toBe(artwork)

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/artworks/1/')
  })

  it('normalizes paginated artwork categories', async () => {
    const categories = [{ id: 1, name: 'Musica', slug: 'musica' }]
    mockedAxios.get.mockResolvedValueOnce({ data: { count: 1, results: categories } })

    await expect(getArtworkCategories()).resolves.toBe(categories)

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/artworks/categories/')
  })

  it('creates artworks as multipart form data', async () => {
    const artwork = { id: '1', title: 'Montaña' }
    mockedAxios.post.mockResolvedValueOnce({ data: artwork })

    await expect(
      createArtwork({
        title: 'Montaña',
        description: 'Paisaje de Nariño',
        price: 120000,
        category: 1,
        technique: 'Óleo',
      }),
    ).resolves.toBe(artwork)

    const [url, body, config] = mockedAxios.post.mock.calls[0] as [string, FormData, unknown]
    expect(url).toBe('/api/v1/artworks/')
    expect(body).toBeInstanceOf(FormData)
    expect(Object.fromEntries(body.entries())).toEqual({
      title: 'Montaña',
      description: 'Paisaje de Nariño',
      category: '1',
      price: '120000',
      technique: 'Óleo',
    })
    expect(config).toEqual({ headers: { 'Content-Type': 'multipart/form-data' } })
  })

  it('deletes an own artwork through the owner endpoint, not the admin one', async () => {
    mockedAxios.delete.mockResolvedValueOnce({ data: undefined })

    await deleteArtwork('abc')

    expect(mockedAxios.delete).toHaveBeenCalledWith('/api/v1/artworks/abc/')
  })
})
