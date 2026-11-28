import { BUYER, DEMO_PASSWORD, unico } from './support/config'
import { expect, iniciarSesion, test } from './fixtures'

test.describe('Registro e inicio de sesión', () => {
  test('una persona se registra y no entra hasta verificar su correo', async ({ page }) => {
    const email = `${unico('nueva').replace(/\s+/g, '')}@demo.test`

    await page.goto('/register')
    await page.getByLabel('Nombre', { exact: true }).fill('Camila')
    await page.getByLabel('Apellido').fill('Prueba')
    await page.getByLabel('Email').fill(email)
    await page.getByLabel('Contraseña', { exact: true }).fill(DEMO_PASSWORD)
    await page.getByLabel('Confirmar contraseña').fill(DEMO_PASSWORD)
    await page.getByRole('checkbox').check()
    await page.getByRole('button', { name: 'Crear cuenta' }).click()

    // El registro lleva al login
    await expect(page).toHaveURL(/\/login/)

    // Sin verificar el correo el acceso se rechaza (el enlace llega por correo, que aquí no sale a la red)
    await page.getByLabel('Email').fill(email)
    await page.getByLabel('Contraseña').fill(DEMO_PASSWORD)
    await page.getByRole('button', { name: 'Ingresar' }).click()
    await expect(page.locator('[data-sonner-toast][data-type="error"]')).toBeVisible()
    await expect(page).toHaveURL(/\/login/)
  })

  test('un usuario verificado inicia sesión y llega al marketplace', async ({ page }) => {
    await iniciarSesion(page, BUYER)
    await expect(page).toHaveURL(/\/marketplace/)
    expect(await page.evaluate(() => localStorage.getItem('auth-storage'))).toContain(BUYER.email)
  })

  test('una contraseña incorrecta no inicia sesión', async ({ page }) => {
    await page.goto('/login')
    await page.getByLabel('Email').fill(BUYER.email)
    await page.getByLabel('Contraseña').fill('Equivocada1!')
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page.locator('[data-sonner-toast][data-type="error"]')).toBeVisible()
    await expect(page).toHaveURL(/\/login/)
  })

  test('las rutas privadas piden iniciar sesión', async ({ page }) => {
    await page.goto('/orders')
    await expect(page).toHaveURL(/\/login/)
  })
})
