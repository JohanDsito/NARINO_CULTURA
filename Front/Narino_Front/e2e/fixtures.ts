import { test as base, expect, type Browser, type BrowserContext, type Page } from '@playwright/test'

// Bloquea en el contexto cualquier salida hacia producción (Railway) y hacia la pasarela real de Wompi.
async function bloquearExterior(context: BrowserContext) {
  await context.route(/\.railway\.app\//, (route) => route.abort())
  await context.route(/\.wompi\.co\//, (route) => route.abort())
}

export const test = base.extend<{ bloqueos: void }>({
  bloqueos: [
    async ({ context }, provide) => {
      await bloquearExterior(context)
      await provide()
    },
    { auto: true },
  ],
})

/** Contexto y página aparte (otro usuario conectado a la vez), con los mismos bloqueos. */
export async function nuevaSesion(browser: Browser): Promise<{ context: BrowserContext; page: Page }> {
  const context = await browser.newContext()
  await bloquearExterior(context)
  return { context, page: await context.newPage() }
}

/** Inicia sesión por el formulario y espera a salir de /login. */
export async function iniciarSesion(page: Page, { email, password }: { email: string; password: string }) {
  await page.goto('/login')
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Contraseña').fill(password)
  await page.getByRole('button', { name: 'Ingresar' }).click()
  await expect(page).not.toHaveURL(/\/login/)
}

export { expect }
