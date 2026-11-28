import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { checkout, getServerCart, removeCartItem } from '@/api/marketplace.api'
import CheckoutPage from '@/pages/checkout/CheckoutPage'
import { renderWithProviders } from '@/test/render'

const startPayment = vi.hoisted(() => ({ mutate: vi.fn(), isPending: false }))

vi.mock('@/api/marketplace.api', () => ({ getServerCart: vi.fn(), removeCartItem: vi.fn(), checkout: vi.fn() }))
vi.mock('@/hooks/useStartPayment', () => ({ useStartPayment: () => startPayment }))
vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

const mockedCart = vi.mocked(getServerCart)
const mockedCheckout = vi.mocked(checkout)
const mockedRemove = vi.mocked(removeCartItem)

const cart = (items: unknown[]) => ({ id: 'c', user: 'u', items, created_at: '', updated_at: '' }) as never

describe('CheckoutPage: flujo de pago y estados', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    startPayment.isPending = false
  })

  it('muestra esqueletos al cargar y luego el carrito con imagen, artista, precio y total', async () => {
    mockedCart.mockResolvedValue(
      cart([
        { id: 'c1', artwork: 'w1', artwork_title: 'Volcán', artwork_price: '100000', artwork_image_url: 'https://img.test/a.jpg', artist_name: 'Ana', created_at: '' },
        { id: 'c2', artwork: 'w2', created_at: '' },
      ]),
    )
    const { container } = renderWithProviders(<CheckoutPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(2)
    expect(await screen.findByText('Obras en tu carrito (2)')).toBeInTheDocument()
    expect(container.querySelector('img')).toHaveAttribute('src', 'https://img.test/a.jpg')
    expect(screen.getByText('Ana')).toBeInTheDocument()
    expect(screen.getByText('Obra')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Quitar «obra» del carrito' })).toBeInTheDocument()
    expect(screen.getAllByText(/100\.000/).length).toBeGreaterThan(0)
  })

  it('carrito vacío: invita a explorar y lleva al catálogo', async () => {
    mockedCart.mockResolvedValue(cart([]))
    renderWithProviders(<CheckoutPage />)
    expect(await screen.findByText('Tu carrito está vacío.')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Explorar obras' }))
    expect(screen.getByTestId('location')).toHaveTextContent('/artworks')
  })

  it('si falla la carga del carrito avisa del error (no dice vacío) y Reintentar vuelve a pedirlo', async () => {
    mockedCart.mockRejectedValueOnce(new Error('sin red'))
    renderWithProviders(<CheckoutPage />)
    expect(await screen.findByText('No pudimos cargar tu carrito.')).toBeInTheDocument()
    expect(screen.queryByText('Tu carrito está vacío.')).not.toBeInTheDocument()
    expect(mockedCart).toHaveBeenCalledTimes(1)
    mockedCart.mockResolvedValueOnce(cart([{ id: 'c1', artwork: 'w1', artwork_title: 'Volcán', artwork_price: '1000', created_at: '' }]))
    fireEvent.click(screen.getByRole('button', { name: 'Reintentar' }))
    expect(await screen.findByText('Obras en tu carrito (1)')).toBeInTheDocument()
    expect(mockedCart).toHaveBeenCalledTimes(2)
  })

  it('pagar crea la orden, avisa y arranca el pago de Wompi con el id de la orden', async () => {
    mockedCart.mockResolvedValue(cart([{ id: 'c1', artwork: 'w1', artwork_title: 'Volcán', artwork_price: '100000', created_at: '' }]))
    mockedCheckout.mockResolvedValue({ order_id: 'abcdef12-3456', total_amount: '100000' })
    renderWithProviders(<CheckoutPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Pagar con Wompi/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Orden #ABCDEF12 creada'))
    expect(mockedCheckout).toHaveBeenCalledWith('COMPRA_DIRECTA')
    expect(startPayment.mutate).toHaveBeenCalledWith('abcdef12-3456')
  })

  it('si crear la orden falla muestra el error', async () => {
    mockedCart.mockResolvedValue(cart([{ id: 'c1', artwork: 'w1', artwork_price: '1', created_at: '' }]))
    mockedCheckout.mockRejectedValue(new Error('Obra ya vendida'))
    renderWithProviders(<CheckoutPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Pagar con Wompi/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Obra ya vendida'))
    expect(startPayment.mutate).not.toHaveBeenCalled()
  })

  it('mientras se inicia el pago bloquea los botones y muestra "Procesando…"', async () => {
    startPayment.isPending = true
    mockedCart.mockResolvedValue(cart([{ id: 'c1', artwork: 'w1', artwork_title: 'Volcán', artwork_price: '1', created_at: '' }]))
    renderWithProviders(<CheckoutPage />)
    expect(await screen.findByRole('button', { name: /Procesando…/ })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Quitar «Volcán» del carrito' })).toBeDisabled()
    expect(mockedRemove).not.toHaveBeenCalled()
  })
})
