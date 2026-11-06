import { describe, it, expect } from 'vitest'

import {
  mapRoleToBackendRole,
  normalizeUserRole,
  normalizeUser,
} from '@/types/auth'

describe('auth type helpers', () => {
  it('maps frontend roles to backend roles', () => {
    expect(
      mapRoleToBackendRole('artist'),
    ).toBe('ARTISTA')

    expect(
      mapRoleToBackendRole('buyer'),
    ).toBe('COMPRADOR')

    expect(
      mapRoleToBackendRole(
        'cultural_manager',
      ),
    ).toBe('GESTOR_CULTURAL')

    expect(
      mapRoleToBackendRole('admin'),
    ).toBe('ADMINISTRADOR')
  })

  it('normalizes backend and frontend roles', () => {
    expect(
      normalizeUserRole('ARTISTA'),
    ).toBe('artist')

    expect(
      normalizeUserRole('COMPRADOR'),
    ).toBe('buyer')

    expect(
      normalizeUserRole(
        'GESTOR_CULTURAL',
      ),
    ).toBe('cultural_manager')

    expect(
      normalizeUserRole('ADMINISTRADOR'),
    ).toBe('admin')

    expect(
      normalizeUserRole('artist'),
    ).toBe('artist')
  })

  it('falls back to buyer for unknown roles', () => {
    expect(
      normalizeUserRole('UNKNOWN'),
    ).toBe('buyer')
  })

  it('normalizes the role inside a user payload', () => {
    expect(
      normalizeUser({
        id: 1,
        email: 'a@test.com',
        role: 'ARTISTA',
        artistic_name: 'ARTISTA',
      }),
    ).toEqual({
      id: 1,
      email: 'a@test.com',
      role: 'artist',
      artistic_name: 'ARTISTA',
    })
  })
})