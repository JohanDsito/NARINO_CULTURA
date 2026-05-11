import { describe, it, expect, beforeEach, vi } from 'vitest'
import axiosInstance from './axiosInstance'
import {
  createArtistProfile,
  listArtistProfiles,
  updateArtistProfile,
} from './artists.api'

vi.mock('./axiosInstance', () => ({
  default: {
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockedAxios = vi.mocked(axiosInstance)

describe('artists.api', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('creates artist profiles', async () => {
    const profile = { id: '1', slug: 'ana', artistic_name: 'Ana' }
    mockedAxios.post.mockResolvedValueOnce({ data: profile })

    await expect(createArtistProfile({ artistic_name: 'Ana' })).resolves.toBe(profile)

    expect(mockedAxios.post).toHaveBeenCalledWith('/api/v1/artists/', {
      artistic_name: 'Ana',
    })
  })

  it('normalizes list responses from array and paginated payloads', async () => {
    const profiles = [{ id: '1', slug: 'ana', artistic_name: 'Ana' }]

    mockedAxios.get.mockResolvedValueOnce({ data: profiles })
    mockedAxios.get.mockResolvedValueOnce({ data: { results: profiles } })

    await expect(listArtistProfiles()).resolves.toEqual(profiles)
    await expect(listArtistProfiles()).resolves.toEqual(profiles)
  })

  it('updates artist profiles by slug', async () => {
    const profile = { id: '1', slug: 'ana', artistic_name: 'Ana Sur' }

    mockedAxios.patch.mockResolvedValueOnce({ data: profile })

    await expect(
      updateArtistProfile('ana', { artistic_name: 'Ana Sur' })
    ).resolves.toBe(profile)

    expect(mockedAxios.patch).toHaveBeenCalledWith(
      '/api/v1/artists/ana/',
      {
        artistic_name: 'Ana Sur',
      }
    )
  })
})