import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'

import { deleteAdminUser, listAdminUsers, updateAdminUser, type AdminUserListItem } from '@/api/admin.api'
import AdminUsersPage from '@/pages/admin/AdminUsersPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'

const toast = vi.hoisted(() => ({ success: vi.fn(), error: vi.fn() }))
vi.mock('sonner', () => ({ toast }))
vi.mock('@/api/admin.api', () => ({ listAdminUsers: vi.fn(), updateAdminUser: vi.fn(), deleteAdminUser: vi.fn() }))

const mockedList = vi.mocked(listAdminUsers)
const mockedUpdate = vi.mocked(updateAdminUser)
const mockedDelete = vi.mocked(deleteAdminUser)

function user(overrides: Partial<AdminUserListItem>): AdminUserListItem {
  return {
    id: 'u2', email: 'ana@test.com', first_name: 'Ana', last_name: 'Mora', role: 'buyer', is_active: true, is_verified: true,
    ...overrides,
  } as AdminUserListItem
}

const ME = user({ id: 'admin1', email: 'yo@test.com', first_name: 'Yo', last_name: 'Admin', role: 'admin' })
const ANA = user({})

describe('AdminUsersPage: eliminación, búsqueda y estados', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: ME as never, isAuthenticated: true })
    mockedList.mockResolvedValue([ME, ANA])
  })
  afterEach(() => vi.restoreAllMocks())

  it('eliminar pide confirmación; cancelado no borra, aceptado borra y avisa', async () => {
    mockedDelete.mockResolvedValueOnce(undefined)
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false)
    renderWithProviders(<AdminUsersPage />)
    await screen.findByText('Ana Mora')
    const deleteButton = screen.getByRole('button', { name: /Eliminar/ })
    fireEvent.click(deleteButton)
    expect(confirm).toHaveBeenCalled()
    expect(mockedDelete).not.toHaveBeenCalled()

    confirm.mockReturnValue(true)
    fireEvent.click(deleteButton)
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Usuario eliminado.'))
    expect(mockedDelete.mock.calls[0][0]).toBe('u2')
  })

  it('si el servidor no deja eliminar muestra su mensaje', async () => {
    mockedDelete.mockRejectedValue(new Error('El usuario tiene ventas'))
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    renderWithProviders(<AdminUsersPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Eliminar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El usuario tiene ventas'))
  })

  it('busca por correo o por nombre y avisa cuando no hay resultados', async () => {
    renderWithProviders(<AdminUsersPage />)
    await screen.findByText('Ana Mora')
    const search = screen.getByLabelText('Buscar usuarios')
    fireEvent.change(search, { target: { value: 'ANA@' } })
    expect(screen.queryByText('Yo Admin')).not.toBeInTheDocument()
    expect(screen.getByText('1 usuario encontrado')).toBeInTheDocument()
    fireEvent.change(search, { target: { value: 'yo adm' } })
    expect(screen.getByText('(tú)')).toBeInTheDocument()
    expect(screen.getByText('yo@test.com', { selector: 'td' })).toBeInTheDocument()
    fireEvent.change(search, { target: { value: 'nadie' } })
    expect(screen.getByText('Sin resultados para tu búsqueda.')).toBeInTheDocument()
  })

  it('sin usuarios registrados muestra el mensaje de vacío y el plural', async () => {
    mockedList.mockResolvedValue([])
    renderWithProviders(<AdminUsersPage />)
    expect(await screen.findByText('No hay usuarios registrados.')).toBeInTheDocument()
    expect(screen.getByText('0 usuarios registrados')).toBeInTheDocument()
  })

  it('si no carga el listado lo avisa', async () => {
    mockedList.mockRejectedValue(new Error('x'))
    renderWithProviders(<AdminUsersPage />)
    expect(await screen.findByText(/No se pudo cargar el listado de usuarios/, undefined, { timeout: 8000 })).toBeInTheDocument()
  })

  it('cambiar al mismo rol no abre confirmación', async () => {
    renderWithProviders(<AdminUsersPage />)
    fireEvent.change(await screen.findByLabelText('Rol de ana@test.com'), { target: { value: 'buyer' } })
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
  })

  it('usuario sin nombre se muestra por su correo en el aviso, y su inicial sale del correo', async () => {
    mockedList.mockResolvedValue([ME, user({ id: 'u9', email: 'zeta@test.com', first_name: '', last_name: '', is_verified: false })])
    renderWithProviders(<AdminUsersPage />)
    await screen.findByText('zeta@test.com', { selector: 'td' })
    expect(screen.getByText('Z')).toBeInTheDocument()
    expect(screen.getByText('Sin verificar')).toBeInTheDocument()
    fireEvent.change(screen.getByLabelText('Rol de zeta@test.com'), { target: { value: 'artist' } })
    expect(screen.getByRole('alertdialog')).toHaveTextContent('zeta@test.com')
  })

  it('mientras guarda el cambio el diálogo dice "Guardando…"', async () => {
    mockedUpdate.mockReturnValue(new Promise(() => {}))
    renderWithProviders(<AdminUsersPage />)
    fireEvent.change(await screen.findByLabelText('Rol de ana@test.com'), { target: { value: 'artist' } })
    fireEvent.click(screen.getByRole('button', { name: 'Cambiar rol' }))
    expect(await screen.findByRole('button', { name: 'Guardando…' })).toBeDisabled()
  })

  it('el diálogo cierra con "Cancelar"', async () => {
    renderWithProviders(<AdminUsersPage />)
    fireEvent.change(await screen.findByLabelText('Rol de ana@test.com'), { target: { value: 'artist' } })
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
  })

  it('la lista pide al servidor el listado filtrado al cambiar el rol y el estado', async () => {
    renderWithProviders(<AdminUsersPage />)
    await screen.findByText('Ana Mora')
    fireEvent.change(screen.getByLabelText('Filtrar por rol'), { target: { value: 'artist' } })
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ role: 'artist', is_active: undefined }))
    fireEvent.change(screen.getByLabelText('Filtrar por estado'), { target: { value: 'active' } })
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ role: 'artist', is_active: true }))
    fireEvent.change(screen.getByLabelText('Filtrar por estado'), { target: { value: 'suspended' } })
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ role: 'artist', is_active: false }))
  })
})
