import { describe, it, expect } from 'vitest'
import { screen } from '@testing-library/react'

import PaymentDeclinedPage from '@/pages/payment/PaymentDeclinedPage'
import PaymentPendingPage from '@/pages/payment/PaymentPendingPage'
import PaymentSuccessPage from '@/pages/payment/PaymentSuccessPage'
import { ROUTES } from '@/constants/routes'
import { renderWithProviders } from '@/test/render'

describe('Páginas de resultado de pago', () => {
  it('rechazado: ofrece reintentar en el checkout y volver al catálogo', () => {
    renderWithProviders(<PaymentDeclinedPage />)
    expect(screen.getByRole('heading', { name: 'Pago rechazado' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Intentar de nuevo' })).toHaveAttribute('href', ROUTES.CHECKOUT)
    expect(screen.getByRole('link', { name: 'Volver al catálogo' })).toHaveAttribute('href', ROUTES.ARTWORKS)
  })

  it('pendiente: enlaza a pedidos e inicio', () => {
    renderWithProviders(<PaymentPendingPage />)
    expect(screen.getByRole('heading', { name: 'Pago en proceso' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Revisar mis pedidos' })).toHaveAttribute('href', ROUTES.ORDERS)
    expect(screen.getByRole('link', { name: 'Volver al inicio' })).toHaveAttribute('href', ROUTES.HOME)
  })

  it('exitoso con orden: muestra el número abreviado en mayúsculas', () => {
    renderWithProviders(<PaymentSuccessPage />, { state: { orderId: 'abcdef12-3456' } })
    expect(screen.getByRole('heading', { name: '¡Pago exitoso!' })).toBeInTheDocument()
    expect(screen.getByText('Orden: #ABCDEF12')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Ver mis pedidos' })).toHaveAttribute('href', ROUTES.ORDERS)
    expect(screen.getByRole('link', { name: 'Seguir explorando' })).toHaveAttribute('href', ROUTES.ARTWORKS)
  })

  it('exitoso sin estado: no muestra número de orden', () => {
    renderWithProviders(<PaymentSuccessPage />)
    expect(screen.queryByText(/Orden:/)).not.toBeInTheDocument()
  })
})
