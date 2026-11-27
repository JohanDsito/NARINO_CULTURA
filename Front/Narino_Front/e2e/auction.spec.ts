import { ADMIN, BUYER } from './support/config'
import { precioActual, subastaActiva } from './support/api'
import { expect, iniciarSesion, nuevaSesion, test } from './fixtures'

test.describe('Subasta en tiempo real', () => {
  test('una puja de una persona se ve en vivo en otra sesión por WebSocket', async ({ browser }) => {
    const subasta = await subastaActiva()
    const sala = `/auctions/${subasta.id}`

    const observadora = await nuevaSesion(browser)
    const postora = await nuevaSesion(browser)
    try {
      // Sesión B (admin) solo mira la sala
      await iniciarSesion(observadora.page, ADMIN)
      await observadora.page.goto(sala)
      await expect(observadora.page.getByText('En tiempo real')).toBeVisible()

      // Sesión A (comprador) puja
      await iniciarSesion(postora.page, BUYER)
      await postora.page.goto(sala)
      await expect(postora.page.getByText('En tiempo real')).toBeVisible()

      const monto = Math.ceil((await precioActual(subasta.id)) / 1000) * 1000 + 10000
      await postora.page.locator('input[type="number"]').fill(String(monto))
      await postora.page.getByRole('button', { name: 'Pujar' }).click()
      await expect(postora.page.getByText('Puja registrada exitosamente')).toBeVisible()

      // B ve la puja sin recargar: llega por el WebSocket
      await expect(observadora.page.getByText('Pujas recientes')).toBeVisible({ timeout: 15_000 })
      await expect(observadora.page.getByText(/Nueva puja/).first()).toBeVisible()
      expect(await precioActual(subasta.id)).toBe(monto)
    } finally {
      await observadora.context.close()
      await postora.context.close()
    }
  })
})
