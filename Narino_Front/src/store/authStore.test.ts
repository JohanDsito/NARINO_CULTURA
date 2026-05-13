import { describe, it, expect, beforeEach } from 'vitest'

import {
  useAuthStore,
  type User,
} from '@/store/authStore'

const user: User = {
  id: 1,
  email: 'ana@test.com',
  first_name: 'Ana',
  last_name: 'Mora',
  artistic_name: 'ARTISTA',
  role: 'artist',
}

describe('authStore', () => {
  beforeEach(() => {
    localStorage.clear()

    useAuthStore.setState({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
    })
  })

  it('sets authenticated state and persists tokens', () => {
    useAuthStore.getState().setAuth(
      user,
      'access-token',
      'refresh-token',
    )

    expect(useAuthStore.getState()).toMatchObject({
      user: {
        role: 'artist',
      },
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      isAuthenticated: true,
    })

    expect(
      localStorage.getItem('access_token'),
    ).toBe('access-token')

    expect(
      localStorage.getItem('refresh_token'),
    ).toBe('refresh-token')
  })

  it('clears state and tokens on logout', () => {
    useAuthStore.getState().setAuth(
      user,
      'access-token',
      'refresh-token',
    )

    useAuthStore.getState().logout()

    expect(useAuthStore.getState()).toMatchObject({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
    })

    expect(
      localStorage.getItem('access_token'),
    ).toBeNull()

    expect(
      localStorage.getItem('refresh_token'),
    ).toBeNull()
  })

  it('updates and normalizes the current user', () => {
    useAuthStore.getState().setAuth(
      user,
      'access-token',
      'refresh-token',
    )

    useAuthStore.getState().updateUser({
      role: 'admin',
      first_name: 'Admin',
    })

    expect(
      useAuthStore.getState().user,
    ).toMatchObject({
      first_name: 'Admin',
      role: 'admin',
    })
  })
})