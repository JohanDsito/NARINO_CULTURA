import {
  describe,
  it,
  expect,
  beforeEach,
} from 'vitest'

import {
  clearPendingArtistProfile,
  getPendingArtistProfile,
  setPendingArtistProfile,
} from '@/utils/pendingArtistProfile'

const storageKey =
  'narino_cultura_pending_artist_profile'

describe('pendingArtistProfile', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('stores and reads a pending artist profile', () => {
    const payload = {
      artistic_name: 'La Montaña',
      discipline: 'Pintura',
      city: 'Pasto',
    }

    setPendingArtistProfile(payload)

    expect(
      getPendingArtistProfile(),
    ).toEqual(payload)
  })

  it('returns null when the storage value is missing or invalid', () => {
    expect(
      getPendingArtistProfile(),
    ).toBeNull()

    localStorage.setItem(
      storageKey,
      '{invalid',
    )

    expect(
      getPendingArtistProfile(),
    ).toBeNull()
  })

  it('clears the pending profile', () => {
    setPendingArtistProfile({
      artistic_name: 'La Montaña',
    })

    clearPendingArtistProfile()

    expect(
      localStorage.getItem(storageKey),
    ).toBeNull()
  })
})