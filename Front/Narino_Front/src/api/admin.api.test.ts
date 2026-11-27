import { describe, it, expect, beforeEach, vi } from 'vitest'

import axiosInstance from './axiosInstance'
import { listAdminUsers, updateAdminUser } from './admin.api'

vi.mock('@/api/axiosInstance', () => ({
  default: { get: vi.fn(), patch: vi.fn() },
}))

const mockedAxios = vi.mocked(axiosInstance)

describe('admin.api usuarios', () => {
  beforeEach(() => vi.clearAllMocks())

  it('lista sin filtros enviando parámetros vacíos', async () => {
    mockedAxios.get.mockResolvedValueOnce({ data: [] })
    await listAdminUsers()
    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/admin/users/', { params: {} })
  })

  it('traduce los filtros de rol y estado a los parámetros del backend', async () => {
    mockedAxios.get.mockResolvedValueOnce({
      data: [{ id: 'u1', email: 'a@test.com', first_name: 'A', last_name: 'B', role: 'ARTISTA', is_active: false }],
    })
    const users = await listAdminUsers({ role: 'artist', is_active: false })
    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/admin/users/', {
      params: { role: 'ARTISTA', is_active: 'false' },
    })
    expect(users[0].role).toBe('artist')
  })

  it('cambia el rol con PATCH usando el valor del backend', async () => {
    mockedAxios.patch.mockResolvedValueOnce({ data: { id: 'u1', role: 'GESTOR_CULTURAL', is_active: true } })
    const user = await updateAdminUser('u1', { role: 'cultural_manager' })
    expect(mockedAxios.patch).toHaveBeenCalledWith('/api/v1/admin/users/u1/', { role: 'GESTOR_CULTURAL' })
    expect(user.role).toBe('cultural_manager')
  })

  it('suspende y restaura con is_active', async () => {
    mockedAxios.patch.mockResolvedValue({ data: { id: 'u1', role: 'COMPRADOR', is_active: false } })
    await updateAdminUser('u1', { is_active: false })
    expect(mockedAxios.patch).toHaveBeenLastCalledWith('/api/v1/admin/users/u1/', { is_active: false })
    await updateAdminUser('u1', { is_active: true })
    expect(mockedAxios.patch).toHaveBeenLastCalledWith('/api/v1/admin/users/u1/', { is_active: true })
  })
})
