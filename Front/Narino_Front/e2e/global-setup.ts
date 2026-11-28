import { API_URL, WEB_URL } from './support/config'

// Red de seguridad: estas pruebas crean usuarios, órdenes y pagos simulados. Jamás deben tocar producción.
export default async function globalSetup() {
  for (const [nombre, url] of [
    ['E2E_API_URL', API_URL],
    ['E2E_BASE_URL', WEB_URL],
  ] as const) {
    if (/railway|rlwy\.net|narinocultura\.uk/i.test(url)) {
      throw new Error(`${nombre}=${url} apunta a producción. Las pruebas e2e solo corren contra un entorno local.`)
    }
  }

  const respuesta = await fetch(`${API_URL}/health/`).catch(() => null)
  if (!respuesta?.ok) {
    throw new Error(
      `El backend e2e no responde en ${API_URL}/health/. Levántalo con config.settings.e2e (ver e2e/README.md).`,
    )
  }
}
