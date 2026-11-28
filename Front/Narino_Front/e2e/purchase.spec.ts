import { BUYER } from './support/config'
import { crearObraDisponible, vaciarCarrito } from './support/api'
import { eventoFirmado, enviarWebhook } from './support/wompi'
import { expect, iniciarSesion, test } from './fixtures'

interface IniciarPago {
  reference: string
  amount_in_cents: number
  public_key: string
  transaction_id: string
}

test.describe('Compra con Wompi simulado', () => {
  test('catálogo, carrito, pago y orden pagada tras el webhook firmado', async ({ page }) => {
    const obra = await crearObraDisponible(250000)
    // El correo de una cuenta nueva debe verificarse antes de entrar: se usa el comprador sembrado
    await vaciarCarrito(BUYER)

    // Wompi nunca se contacta: el Web Checkout se reemplaza por una página local
    let urlCheckout = ''
    await page.route('https://checkout.wompi.co/**', (route) => {
      urlCheckout = route.request().url()
      return route.fulfill({ contentType: 'text/html', body: '<h1>Wompi simulado</h1>' })
    })

    await iniciarSesion(page, BUYER)

    // Catálogo -> detalle
    await page.goto('/artworks')
    await page.getByPlaceholder('Buscar obras…').fill(obra.title)
    await page.getByRole('link', { name: new RegExp(obra.title) }).click()
    await expect(page.getByRole('heading', { name: obra.title })).toBeVisible()

    // Detalle -> carrito
    await page.getByRole('button', { name: 'Agregar al carrito' }).click()
    await expect(page.getByText('Obra agregada al carrito')).toBeVisible()

    // Carrito -> checkout -> pago
    await page.goto('/checkout')
    await expect(page.getByText(obra.title)).toBeVisible()
    // El front navega a Wompi apenas responde initiate: el cuerpo se copia dentro de la ruta, antes de que se pierda
    let pago: IniciarPago | undefined
    await page.route('**/api/v1/payments/initiate/', async (route) => {
      const respuesta = await route.fetch()
      expect(respuesta.status()).toBe(201)
      pago = (await respuesta.json()) as IniciarPago
      await route.fulfill({ response: respuesta })
    })
    await page.getByRole('button', { name: 'Pagar con Wompi' }).click()

    await expect(page.getByText('Wompi simulado')).toBeVisible()
    if (!pago) throw new Error('No se capturó la respuesta de payments/initiate')
    expect(urlCheckout).toContain(`reference=${pago.reference}`)
    expect(urlCheckout).toContain('public-key=pub_test_e2e')
    expect(pago.amount_in_cents).toBe(25000000)

    // Un webhook con firma falsa se rechaza y la orden sigue pendiente
    const falso = eventoFirmado(
      { id: `e2e-tx-${pago.reference}`, reference: pago.reference, status: 'APPROVED', amount_in_cents: pago.amount_in_cents },
      'secreto_equivocado',
    )
    expect((await enviarWebhook(falso)).status).toBe(401)

    // El webhook firmado con el secreto de la prueba confirma el pago
    const aprobado = eventoFirmado({
      id: `e2e-tx-${pago.reference}`,
      reference: pago.reference,
      status: 'APPROVED',
      amount_in_cents: pago.amount_in_cents,
    })
    expect((await enviarWebhook(aprobado)).status).toBe(200)

    // Wompi devuelve a la persona a la URL de retorno que armó el front (/payment/pending)
    const coincidencia = /redirect-url=([^&]+)/.exec(urlCheckout)
    expect(coincidencia).not.toBeNull()
    await page.goto(new URL(decodeURIComponent(coincidencia![1])).pathname)
    await expect(page.getByRole('heading', { name: 'Pago en proceso' })).toBeVisible()
    await page.getByRole('link', { name: 'Revisar mis pedidos' }).click()

    await expect(page.getByRole('heading', { name: 'Mis pedidos' })).toBeVisible()
    // La cuenta sembrada acumula pedidos de corridas anteriores: se mira solo la tarjeta de esta obra
    const pedido = page.locator('div.p-5').filter({ hasText: obra.title })
    await expect(pedido.getByText('Pagado', { exact: true })).toBeVisible()
  })
})
