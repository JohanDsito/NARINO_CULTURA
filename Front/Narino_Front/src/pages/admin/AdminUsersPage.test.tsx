import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { AxiosError, type AxiosResponse } from 'axios'
import { MemoryRouter } from 'react-router-dom'

import { listAdminUsers, updateAdminUser, type AdminUserListItem } from '@/api/admin.api'
import AdminUsersPage from '@/pages/admin/AdminUsersPage'
import { useAuthStore } from '@/store/authStore'

const toast = vi.hoisted(() => ({ success: vi.fn(), error: vi.fn() }))
vi.mock('sonner', () => ({ toast }))
vi.mock('@/api/admin.api', () => ({
  listAdminUsers: vi.fn(),
  updateAdminUser: vi.fn(),
  deleteAdminUser: vi.fn(),
}))

const mockedList = vi.mocked(listAdminUsers)
const mockedUpdate = vi.mocked(updateAdminUser)

function user(overrides: Partial<AdminUserListItem>): AdminUserListItem {
  return {
    id: 'u2',
    email: 'ana@test.com',
    first_name: 'Ana',
    last_name: 'Mora',
    role: 'buyer',
    is_active: true,
    is_verified: true,
    ...overrides,
  } as AdminUserListItem
}

const ME = user({ id: 'admin1', email: 'yo@test.com', first_name: 'Yo', last_name: 'Admin', role: 'admin' })
const ANA = user({})
const SUSPENDIDA = user({ id: 'u3', email: 'sus@test.com', first_name: 'Sus', last_name: 'Pendida', is_active: false })

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <AdminUsersPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('AdminUsersPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.getState().setAuth(ME as never, 'access', 'refresh')
    mockedList.mockResolvedValue([ME, ANA, SUSPENDIDA])
  })

  it('muestra la insignia "Suspendida" en las cuentas inactivas', async () => {
    renderPage()
    expect(await screen.findByText('Suspendida')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Restaurar/ })).toBeInTheDocument()
  })

  it('cambia el rol tras confirmar', async () => {
    mockedUpdate.mockResolvedValueOnce(ANA)
    renderPage()
    fireEvent.change(await screen.findByLabelText('Rol de ana@test.com'), { target: { value: 'artist' } })

    const dialog = screen.getByRole('alertdialog')
    expect(dialog).toHaveTextContent('Artista')
    fireEvent.click(within(dialog).getByRole('button', { name: 'Cambiar rol' }))

    await waitFor(() => expect(mockedUpdate).toHaveBeenCalledWith('u2', { role: 'artist' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Rol actualizado.'))
  })

  it('no cambia nada si se cancela la confirmación', async () => {
    renderPage()
    fireEvent.change(await screen.findByLabelText('Rol de ana@test.com'), { target: { value: 'artist' } })
    fireEvent.click(within(screen.getByRole('alertdialog')).getByRole('button', { name: 'Cancelar' }))

    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(mockedUpdate).not.toHaveBeenCalled()
  })

  it('el administrador no puede quitarse su propio rol ni suspenderse', async () => {
    renderPage()
    const own = await screen.findByLabelText('Rol de yo@test.com')
    expect(own).toBeDisabled()
    fireEvent.change(own, { target: { value: 'buyer' } })
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(mockedUpdate).not.toHaveBeenCalled()
    // Solo las filas ajenas ofrecen Suspender / Restaurar
    expect(screen.getAllByRole('button', { name: /Suspender|Restaurar/ })).toHaveLength(2)
  })

  it('suspende una cuenta tras confirmar', async () => {
    mockedUpdate.mockResolvedValueOnce(ANA)
    renderPage()
    await screen.findByText('Ana Mora')
    fireEvent.click(screen.getByRole('button', { name: /Suspender/ }))
    fireEvent.click(within(screen.getByRole('alertdialog')).getByRole('button', { name: 'Suspender' }))

    await waitFor(() => expect(mockedUpdate).toHaveBeenCalledWith('u2', { is_active: false }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Cuenta suspendida.'))
  })

  it('restaura una cuenta suspendida tras confirmar', async () => {
    mockedUpdate.mockResolvedValueOnce(SUSPENDIDA)
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Restaurar/ }))
    fireEvent.click(within(screen.getByRole('alertdialog')).getByRole('button', { name: 'Restaurar' }))

    await waitFor(() => expect(mockedUpdate).toHaveBeenCalledWith('u3', { is_active: true }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Cuenta restaurada.'))
  })

  it('muestra el error del backend si falla el cambio', async () => {
    mockedUpdate.mockRejectedValueOnce(
      new AxiosError('x', 'ERR', undefined, undefined, {
        status: 400,
        data: { role: ['Opción inválida.'] },
      } as AxiosResponse),
    )
    renderPage()
    fireEvent.change(await screen.findByLabelText('Rol de ana@test.com'), { target: { value: 'artist' } })
    fireEvent.click(within(screen.getByRole('alertdialog')).getByRole('button', { name: 'Cambiar rol' }))

    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Opción inválida.'))
  })

  it('pide el listado filtrado por rol y por estado', async () => {
    renderPage()
    await screen.findByText('Ana Mora')
    fireEvent.change(screen.getByLabelText('Filtrar por rol'), { target: { value: 'artist' } })
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ role: 'artist', is_active: undefined }))

    fireEvent.change(screen.getByLabelText('Filtrar por estado'), { target: { value: 'suspended' } })
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ role: 'artist', is_active: false }))

    fireEvent.change(screen.getByLabelText('Filtrar por estado'), { target: { value: 'active' } })
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ role: 'artist', is_active: true }))
  })
})
