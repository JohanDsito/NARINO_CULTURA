import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen } from '@testing-library/react'

import { listAdminUsers, type AdminUserListItem } from '@/api/admin.api'
import AdminUsersPage from '@/pages/admin/AdminUsersPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'

const toast = vi.hoisted(() => ({ success: vi.fn(), error: vi.fn() }))
vi.mock('sonner', () => ({ toast }))
vi.mock('@/api/admin.api', () => ({ listAdminUsers: vi.fn(), updateAdminUser: vi.fn(), deleteAdminUser: vi.fn() }))
// La fila real no ofrece "Suspender" para la propia cuenta; se simula para comprobar que la página igual se protege.
vi.mock('@/components/admin/admin-user-row', () => ({
  AdminUserRow: ({ user, onToggleActive }: { user: AdminUserListItem; onToggleActive: (u: AdminUserListItem) => void }) => (
    <tr>
      <td>
        <button onClick={() => onToggleActive(user)}>suspender-{user.id}</button>
      </td>
    </tr>
  ),
}))

describe('AdminUsersPage: protección de la propia cuenta', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: 'admin1' } as never, isAuthenticated: true })
    vi.mocked(listAdminUsers).mockResolvedValue([
      { id: 'admin1', email: 'yo@test.com', first_name: 'Yo', last_name: 'A', role: 'admin', is_active: true } as AdminUserListItem,
      { id: 'u2', email: 'ana@test.com', first_name: 'Ana', last_name: 'M', role: 'buyer', is_active: true } as AdminUserListItem,
    ])
  })

  it('no deja suspender la propia cuenta aunque se invoque', async () => {
    renderWithProviders(<AdminUsersPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'suspender-admin1' }))
    expect(toast.error).toHaveBeenCalledWith('No puedes suspender tu propia cuenta.')
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
  })

  it('a otra cuenta sí le abre la confirmación de suspensión', async () => {
    renderWithProviders(<AdminUsersPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'suspender-u2' }))
    expect(screen.getByRole('alertdialog')).toHaveTextContent('Suspender cuenta')
  })
})
