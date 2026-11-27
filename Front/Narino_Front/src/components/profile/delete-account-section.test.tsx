import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { AxiosError, type AxiosResponse } from 'axios'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { deleteAccount } from '@/api/auth.api'
import { DeleteAccountSection } from '@/components/profile/delete-account-section'
import { useAuthStore } from '@/store/authStore'

const toastSuccess = vi.hoisted(() => vi.fn())
vi.mock('sonner', () => ({ toast: { success: toastSuccess, error: vi.fn() } }))
vi.mock('@/api/auth.api', () => ({ deleteAccount: vi.fn() }))

const mockedDelete = vi.mocked(deleteAccount)

function apiError(status: number, data: Record<string, unknown>) {
  return new AxiosError('fail', 'ERR', undefined, undefined, {
    status,
    data,
  } as AxiosResponse)
}

function renderSection() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/profile']}>
        <Routes>
          <Route path="/profile" element={<DeleteAccountSection />} />
          <Route path="/" element={<p>Inicio</p>} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

function openDialog() {
  fireEvent.click(screen.getByRole('button', { name: 'Eliminar mi cuenta' }))
}

describe('DeleteAccountSection', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.getState().setAuth(
      { id: 'u1', email: 'a@test.com', first_name: 'Ana', last_name: 'Mora', role: 'buyer' } as never,
      'access',
      'refresh',
    )
  })

  it('muestra la zona de peligro y explica qué se borra y qué se conserva', () => {
    renderSection()
    expect(screen.getByText('Zona de peligro')).toBeInTheDocument()
    openDialog()
    const dialog = screen.getByRole('alertdialog')
    expect(dialog).toHaveTextContent('Se elimina:')
    expect(dialog).toHaveTextContent('Se conserva:')
  })

  it('no permite confirmar sin contraseña', () => {
    renderSection()
    openDialog()
    expect(screen.getByRole('button', { name: 'Eliminar definitivamente' })).toBeDisabled()
  })

  it('enfoca la contraseña al abrir y no pierde el foco al escribir', () => {
    renderSection()
    openDialog()
    const input = screen.getByLabelText('Confirma con tu contraseña')
    expect(input).toHaveFocus()
    fireEvent.change(input, { target: { value: 'Sec' } })
    fireEvent.change(input, { target: { value: 'Secreta' } })
    expect(input).toHaveFocus()
  })

  it('Escape cierra el diálogo, Tab no sale de él y el foco vuelve al botón que lo abrió', () => {
    renderSection()
    // En el navegador el clic enfoca el botón; fireEvent.click no, así que se enfoca a mano
    const opener = screen.getByRole('button', { name: 'Eliminar mi cuenta' })
    opener.focus()
    openDialog()
    const input = screen.getByLabelText('Confirma con tu contraseña')
    fireEvent.change(input, { target: { value: 'x' } })
    const confirm = screen.getByRole('button', { name: 'Eliminar definitivamente' })
    confirm.focus()
    fireEvent.keyDown(document, { key: 'Tab' })
    expect(input).toHaveFocus()
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })
    expect(confirm).toHaveFocus()

    fireEvent.keyDown(document, { key: 'Escape' })
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(opener).toHaveFocus()
  })

  it('cancelar cierra el diálogo sin llamar al backend', () => {
    renderSection()
    openDialog()
    fireEvent.change(screen.getByLabelText('Confirma con tu contraseña'), { target: { value: 'x' } })
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(mockedDelete).not.toHaveBeenCalled()
  })

  it('con éxito cierra sesión, avisa y lleva al inicio', async () => {
    mockedDelete.mockResolvedValueOnce(undefined)
    renderSection()
    openDialog()
    fireEvent.change(screen.getByLabelText('Confirma con tu contraseña'), { target: { value: 'Secreta123' } })
    fireEvent.click(screen.getByRole('button', { name: 'Eliminar definitivamente' }))

    expect(await screen.findByText('Inicio')).toBeInTheDocument()
    expect(mockedDelete).toHaveBeenCalledWith('Secreta123')
    expect(useAuthStore.getState().isAuthenticated).toBe(false)
    expect(useAuthStore.getState().user).toBeNull()
    expect(toastSuccess).toHaveBeenCalled()
  })

  it('muestra el error de contraseña incorrecta y mantiene la sesión', async () => {
    mockedDelete.mockRejectedValueOnce(apiError(400, { detail: 'La contraseña no es correcta.' }))
    renderSection()
    openDialog()
    fireEvent.change(screen.getByLabelText('Confirma con tu contraseña'), { target: { value: 'mala' } })
    fireEvent.click(screen.getByRole('button', { name: 'Eliminar definitivamente' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('La contraseña no es correcta.')
    expect(useAuthStore.getState().isAuthenticated).toBe(true)
  })

  it('muestra el 409 de obras vendidas y mantiene la sesión', async () => {
    mockedDelete.mockRejectedValueOnce(
      apiError(409, { detail: 'No puedes eliminar tu cuenta porque tienes obras vendidas.', code: 'account_has_sales' }),
    )
    renderSection()
    openDialog()
    fireEvent.change(screen.getByLabelText('Confirma con tu contraseña'), { target: { value: 'Secreta123' } })
    fireEvent.click(screen.getByRole('button', { name: 'Eliminar definitivamente' }))

    await waitFor(() =>
      expect(screen.getByRole('alert')).toHaveTextContent('tienes obras vendidas'),
    )
    expect(screen.getByRole('alertdialog')).toBeInTheDocument()
    expect(useAuthStore.getState().isAuthenticated).toBe(true)
  })
})
