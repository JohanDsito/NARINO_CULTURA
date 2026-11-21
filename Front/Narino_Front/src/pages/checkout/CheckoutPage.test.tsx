import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { toast } from 'sonner'

import { getServerCart, removeCartItem } from '@/api/marketplace.api'
import CheckoutPage from '@/pages/checkout/CheckoutPage'

vi.mock('@/api/marketplace.api', () => ({
  getServerCart: vi.fn(),
  removeCartItem: vi.fn(),
  checkout: vi.fn(),
}))
vi.mock('@/hooks/useStartPayment', () => ({
  useStartPayment: () => ({ mutate: vi.fn(), isPending: false }),
}))
vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

const mockedCart = vi.mocked(getServerCart)
const mockedRemove = vi.mocked(removeCartItem)

const ITEMS = [
  { id: 'c1', artwork: 'w1', artwork_title: 'Volcán Galeras', artwork_price: '100000.00', created_at: '' },
  { id: 'c2', artwork: 'w2', artwork_title: 'Carnaval', artwork_price: '50000.00', created_at: '' },
]

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <CheckoutPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('CheckoutPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedCart.mockResolvedValue({ id: 'cart', user: 'u1', items: ITEMS, created_at: '', updated_at: '' })
    mockedRemove.mockResolvedValue({ detail: 'ok' })
  })

  it('avisa que las obras quedan reservadas mientras se paga', async () => {
    renderPage()
    expect(await screen.findByText(/quedan\s+reservadas para ti durante el plazo de pago/i)).toBeInTheDocument()
  })

  it('quita una obra del carrito y vuelve a pedir el carrito', async () => {
    renderPage()
    mockedCart.mockResolvedValue({ id: 'cart', user: 'u1', items: [ITEMS[1]], created_at: '', updated_at: '' })
    fireEvent.click(await screen.findByRole('button', { name: 'Quitar «Volcán Galeras» del carrito' }))
    await waitFor(() => expect(mockedRemove).toHaveBeenCalledWith('w1'))
    await waitFor(() => expect(screen.queryByText('Volcán Galeras')).not.toBeInTheDocument())
    expect(toast.success).toHaveBeenCalledWith('Obra quitada del carrito')
  })

  it('si falla al quitar, lo avisa y la obra sigue en el carrito', async () => {
    mockedRemove.mockRejectedValue(new Error('sin red'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: 'Quitar «Carnaval» del carrito' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalled())
    expect(screen.getByText('Carnaval')).toBeInTheDocument()
  })
})
