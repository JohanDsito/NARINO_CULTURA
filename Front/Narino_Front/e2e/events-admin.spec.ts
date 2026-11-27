import { ADMIN, ARTIST, BUYER, unico } from './support/config'
import { eventosPublicos } from './support/api'
import { expect, iniciarSesion, nuevaSesion, test } from './fixtures'

test.describe('Eventos y administración', () => {
  test('el artista crea un evento, el admin lo aprueba y aparece en eventos', async ({ browser, page }) => {
    const titulo = unico('Evento E2E')

    // Artista propone el evento
    await iniciarSesion(page, ARTIST)
    await page.goto('/dashboard/events/new')
    await page.getByLabel('Nombre del evento').fill(titulo)
    await page.getByLabel('Tipo de evento').selectOption('CONCIERTO')
    await page.getByLabel('Lugar').fill('Teatro Imperial, Pasto')
    await page.getByLabel('Fecha y hora de inicio').fill('2030-05-10T18:00')
    await page.getByLabel('Descripción').fill('Evento creado por una prueba e2e.')
    await page.getByRole('button', { name: 'Enviar evento' }).click()
    await expect(page.getByText('Evento enviado para aprobación')).toBeVisible()

    // Mientras no se aprueba, el público no lo ve
    const publico = await nuevaSesion(browser)
    const admin = await nuevaSesion(browser)
    try {
      expect(await eventosPublicos(titulo)).toHaveLength(0)

      // Admin aprueba
      await iniciarSesion(admin.page, ADMIN)
      await admin.page.goto('/admin/events')
      const tarjeta = admin.page.locator('[class*="sm:flex-row"]').filter({ hasText: titulo })
      await tarjeta.getByRole('button', { name: 'Aprobar' }).click()
      await expect(tarjeta).toHaveCount(0)

      // Ahora es público: está en el listado de eventos y su página lo muestra
      const publicados = await eventosPublicos(titulo)
      expect(publicados).toHaveLength(1)
      await publico.page.goto(`/events/${publicados[0].id}`)
      await expect(publico.page.getByRole('heading', { name: titulo })).toBeVisible()
    } finally {
      await publico.context.close()
      await admin.context.close()
    }
  })

  test('el administrador ve la lista de usuarios', async ({ page }) => {
    await iniciarSesion(page, ADMIN)
    await page.goto('/admin/users')
    await expect(page.getByText(BUYER.email)).toBeVisible()
    await expect(page.getByText(ARTIST.email)).toBeVisible()
  })
})
