import axiosInstance from './axiosInstance'
import type { PaginatedResponse, Transaction } from '@/types'

/** Respuesta de `POST /payments/initiate/`: datos para abrir el Web Checkout de Wompi. */
export interface PaymentInitiation {
  transaction_id: string
  public_key: string
  reference: string
  amount_in_cents: number
  currency: string
  integrity_signature: string
}

export async function initiatePayment(orderId: string): Promise<PaymentInitiation> {
  const { data } = await axiosInstance.post<PaymentInitiation>('/api/v1/payments/initiate/', {
    order_id: orderId,
  })
  return data
}

/**
 * URL del Web Checkout de Wompi. `signature:integrity` lleva dos puntos en el
 * nombre del parámetro, por eso la query se arma a mano (URLSearchParams lo codificaría).
 * Devuelve `null` si el backend no tiene llave pública configurada.
 */
export function buildWompiCheckoutUrl(payment: PaymentInitiation, redirectUrl: string): string | null {
  if (!payment.public_key || !payment.reference) return null
  const params = [
    `public-key=${encodeURIComponent(payment.public_key)}`,
    `currency=${encodeURIComponent(payment.currency)}`,
    `amount-in-cents=${payment.amount_in_cents}`,
    `reference=${encodeURIComponent(payment.reference)}`,
    `signature:integrity=${encodeURIComponent(payment.integrity_signature)}`,
    `redirect-url=${encodeURIComponent(redirectUrl)}`,
  ]
  return `https://checkout.wompi.co/p/?${params.join('&')}`
}

export async function getTransactions(): Promise<Transaction[]> {
  const { data } = await axiosInstance.get<Transaction[] | PaginatedResponse<Transaction>>(
    '/api/v1/payments/transactions/',
  )
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getTransactionReceipt(id: string): Promise<{ receipt_url: string }> {
  const { data } = await axiosInstance.get<{ receipt_url: string }>(
    `/api/v1/payments/transactions/${id}/receipt/`,
  )
  return data
}
