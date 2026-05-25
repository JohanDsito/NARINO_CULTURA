import type { CreateArtistProfilePayload } from '@/api/artists.api'

const KEY = 'narino_cultura_pending_artist_profile'

export function setPendingArtistProfile(payload: CreateArtistProfilePayload) {
  localStorage.setItem(KEY, JSON.stringify(payload))
}

export function getPendingArtistProfile(): CreateArtistProfilePayload | null {
  const raw = localStorage.getItem(KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as CreateArtistProfilePayload
  } catch {
    return null
  }
}

export function clearPendingArtistProfile() {
  localStorage.removeItem(KEY)
}

