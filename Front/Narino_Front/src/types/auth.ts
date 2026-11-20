export type UserRole = 'artist' | 'buyer' | 'cultural_manager' | 'admin'
export type Role = UserRole
export type BackendRole = 'ARTISTA' | 'COMPRADOR' | 'GESTOR_CULTURAL' | 'ADMINISTRADOR'

const frontendToBackendRole: Record<UserRole, BackendRole> = {
  artist: 'ARTISTA',
  buyer: 'COMPRADOR',
  cultural_manager: 'GESTOR_CULTURAL',
  admin: 'ADMINISTRADOR',
}

const backendToFrontendRole: Record<BackendRole, UserRole> = {
  ARTISTA: 'artist',
  COMPRADOR: 'buyer',
  GESTOR_CULTURAL: 'cultural_manager',
  ADMINISTRADOR: 'admin',
}

export const mapRoleToBackendRole = (role: UserRole): BackendRole =>
  frontendToBackendRole[role]

export const normalizeUserRole = (role: string): UserRole => {
  if (role in backendToFrontendRole) return backendToFrontendRole[role as BackendRole]
  if (role in frontendToBackendRole) return role as UserRole
  return 'buyer'
}

export const normalizeUser = <T extends { role: string }>(
  user: T,
): Omit<T, 'role'> & { role: UserRole } => ({
  ...user,
  role: normalizeUserRole(user.role),
})

// Matches backend apps.users.models.User exactly.
export interface User {
  id: string            // UUID — backend uses UUIDField
  email: string
  first_name: string
  last_name: string
  role: UserRole
  avatar_url?: string   // URLField in backend (not "avatar")
  phone?: string
  is_verified: boolean
}

export interface AuthTokens {
  access: string
  refresh: string
}

export interface LoginCredentials {
  email: string
  password: string
}

export interface RegisterData {
  email: string
  password: string
  first_name: string
  last_name: string
  role: string          // backend key (ARTISTA, COMPRADOR, etc.)
  phone?: string
  avatar_url?: string
}
