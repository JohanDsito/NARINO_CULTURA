import { ADMIN, API_URL, ARTIST, unico } from './config'

interface Credenciales {
  email: string
  password: string
}

async function pedir<T>(ruta: string, opciones: { metodo?: string; token?: string; cuerpo?: unknown } = {}): Promise<T> {
  const respuesta = await fetch(`${API_URL}${ruta}`, {
    method: opciones.metodo ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(opciones.token ? { Authorization: `Bearer ${opciones.token}` } : {}),
    },
    body: opciones.cuerpo === undefined ? undefined : JSON.stringify(opciones.cuerpo),
  })
  const texto = await respuesta.text()
  if (!respuesta.ok) throw new Error(`${opciones.metodo ?? 'GET'} ${ruta} -> ${respuesta.status}: ${texto}`)
  return (texto ? JSON.parse(texto) : {}) as T
}

/** Inicia sesión por la API y devuelve el token de acceso. */
export async function tokenDe({ email, password }: Credenciales): Promise<string> {
  const datos = await pedir<{ tokens?: { access: string }; access?: string }>('/api/v1/auth/login/', {
    metodo: 'POST',
    cuerpo: { email, password },
  })
  return (datos.tokens?.access ?? datos.access) as string
}

/** Crea una obra DISPONIBLE propia de la prueba (la crea el artista y la aprueba el admin). */
export async function crearObraDisponible(precio = 250000): Promise<{ id: string; title: string }> {
  const tokenArtista = await tokenDe(ARTIST)
  const title = unico('Obra E2E')
  const obra = await pedir<{ id: string }>('/api/v1/artworks/', {
    metodo: 'POST',
    token: tokenArtista,
    cuerpo: { title, description: 'Obra creada por una prueba e2e.', price: String(precio) },
  })
  const tokenAdmin = await tokenDe(ADMIN)
  await pedir(`/api/v1/admin/artworks/${obra.id}/moderate/`, {
    metodo: 'PATCH',
    token: tokenAdmin,
    cuerpo: { status: 'DISPONIBLE' },
  })
  return { id: obra.id, title }
}

export interface SubastaApi {
  id: string
  current_price: string
  status: string
}

/** La subasta ACTIVA que siembra seed_demo. */
export async function subastaActiva(): Promise<SubastaApi> {
  const datos = await pedir<{ results?: SubastaApi[] } | SubastaApi[]>('/api/v1/auctions/?status=ACTIVA')
  const lista = Array.isArray(datos) ? datos : (datos.results ?? [])
  const activa = lista.find((a) => a.status === 'ACTIVA')
  if (!activa) throw new Error('No hay subasta ACTIVA: corre `manage.py seed_demo --confirmar`.')
  return activa
}

export async function precioActual(subastaId: string): Promise<number> {
  const subasta = await pedir<SubastaApi>(`/api/v1/auctions/${subastaId}/`)
  return parseFloat(subasta.current_price)
}

/** Deja vacío el carrito del usuario (por si una corrida anterior falló a medias). */
export async function vaciarCarrito(credenciales: Credenciales): Promise<void> {
  const token = await tokenDe(credenciales)
  const carrito = await pedir<{ items?: { artwork: string }[] }>('/api/v1/marketplace/cart/', { token })
  for (const item of carrito.items ?? []) {
    await pedir('/api/v1/marketplace/cart/items/', { metodo: 'DELETE', token, cuerpo: { artwork_id: item.artwork } })
  }
}

/** Eventos PÚBLICOS (publicados) cuyo título coincide; el calendario de la web solo muestra un mes a la vez. */
export async function eventosPublicos(busqueda: string): Promise<{ id: string; title: string }[]> {
  const datos = await pedir<{ results?: { id: string; title: string }[] } | { id: string; title: string }[]>(
    `/api/v1/events/?search=${encodeURIComponent(busqueda)}`,
  )
  return Array.isArray(datos) ? datos : (datos.results ?? [])
}
