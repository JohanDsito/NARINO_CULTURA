const KEY_PREFIX = 'artist_discipline'

export function getArtistDiscipline(userId: string): string | null {
  return localStorage.getItem(`${KEY_PREFIX}_${userId}`)
}

export function setArtistDiscipline(userId: string, discipline: string): void {
  localStorage.setItem(`${KEY_PREFIX}_${userId}`, discipline)
}

export function clearArtistDiscipline(userId: string): void {
  localStorage.removeItem(`${KEY_PREFIX}_${userId}`)
}

export function getArtistDashboardPath(userId: string): string {
  const discipline = getArtistDiscipline(userId)
  if (discipline === 'musico') return '/dashboard/musician/profile'
  if (discipline) return '/dashboard/profile'
  return '/dashboard'
}
