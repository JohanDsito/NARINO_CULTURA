import type { Role } from '@/types/auth'

export const ROLE = {
  artist: 'artist',
  buyer: 'buyer',
  culturalManager: 'cultural_manager',
  admin: 'admin',
} as const satisfies Record<string, Role>

export const ANY_AUTH: readonly Role[] = [
  ROLE.artist,
  ROLE.buyer,
  ROLE.culturalManager,
  ROLE.admin,
]

