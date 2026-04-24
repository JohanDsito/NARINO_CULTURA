export type Role = 'artist' | 'buyer' | 'cultural_manager' | 'admin'

export type BackendRole =
  | 'ARTISTA'
  | 'COMPRADOR'
  | 'GESTOR_CULTURAL'
  | 'ADMINISTRADOR'

export interface BackendMeUser {
  id: string
  email: string
  first_name: string
  last_name: string
  role: BackendRole
  phone: string
  avatar_url: string
  is_verified: boolean
}

export interface AuthUser {
  id: string
  email: string
  firstName: string
  lastName: string
  role: Role
  phone: string
  avatarUrl: string
  isVerified: boolean
}

export interface AuthTokens {
  access: string
  refresh: string
}

export function mapBackendRole(role: BackendRole): Role {
  switch (role) {
    case 'ARTISTA':
      return 'artist'
    case 'COMPRADOR':
      return 'buyer'
    case 'GESTOR_CULTURAL':
      return 'cultural_manager'
    case 'ADMINISTRADOR':
      return 'admin'
  }
}

export function mapBackendMeUser(user: BackendMeUser): AuthUser {
  return {
    id: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    role: mapBackendRole(user.role),
    phone: user.phone,
    avatarUrl: user.avatar_url,
    isVerified: user.is_verified,
  }
}
