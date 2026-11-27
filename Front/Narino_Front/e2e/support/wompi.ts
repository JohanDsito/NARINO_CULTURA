import { createHash } from 'node:crypto'

import { API_URL, WOMPI_EVENTS_SECRET } from './config'

interface TransaccionWompi {
  id: string
  reference: string
  status: 'APPROVED' | 'DECLINED' | 'VOIDED' | 'ERROR' | 'PENDING'
  amount_in_cents: number
}

/**
 * Arma un evento `transaction.updated` firmado como lo hace Wompi:
 * SHA-256 de transaction.id + status + amount_in_cents + timestamp + secreto de eventos.
 */
export function eventoFirmado(
  transaccion: TransaccionWompi,
  secreto = WOMPI_EVENTS_SECRET,
  timestamp = Math.floor(Date.now() / 1000),
) {
  const propiedades = ['transaction.id', 'transaction.status', 'transaction.amount_in_cents']
  const crudo = `${transaccion.id}${transaccion.status}${transaccion.amount_in_cents}${timestamp}${secreto}`
  return {
    event: 'transaction.updated',
    data: {
      transaction: {
        currency: 'COP',
        payment_method_type: 'CARD',
        receipt_url: 'https://example.com/comprobante-e2e',
        ...transaccion,
      },
    },
    environment: 'test',
    signature: { properties: propiedades, checksum: createHash('sha256').update(crudo).digest('hex').toUpperCase() },
    timestamp,
    sent_at: new Date().toISOString(),
  }
}

/** Entrega el webhook al backend, igual que lo haría Wompi tras el pago. */
export async function enviarWebhook(evento: ReturnType<typeof eventoFirmado>): Promise<Response> {
  return fetch(`${API_URL}/api/v1/payments/wompi-webhook/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(evento),
  })
}
