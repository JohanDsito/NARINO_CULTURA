import { describe, it, expect, vi, beforeEach } from 'vitest'
import { AxiosError, type AxiosResponse } from 'axios'

import axiosInstance from '@/api/axiosInstance'
import * as admin from '@/api/admin.api'
import * as artists from '@/api/artists.api'
import * as artworks from '@/api/artworks.api'
import * as auctions from '@/api/auctions.api'
import * as auth from '@/api/auth.api'
import { sendChatMessage } from '@/api/chat.api'
import { eventsApi, normalizeEventsResponse, type Event } from '@/api/events.api'
import * as market from '@/api/marketplace.api'
import * as musicians from '@/api/musicians.api'
import * as notifications from '@/api/notifications.api'
import * as payments from '@/api/payments.api'

vi.mock('@/api/axiosInstance', () => ({
  default: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), put: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(axiosInstance)

/** Respuesta de axios con el cuerpo indicado. */
const ok = (data: unknown) => Promise.resolve({ data })

beforeEach(() => {
  vi.clearAllMocks()
  http.get.mockReset()
  http.post.mockReset()
  http.patch.mockReset()
  http.delete.mockReset()
})

describe('admin.api', () => {
  it('métricas, usuario y borrado de usuario', async () => {
    http.get.mockReturnValueOnce(ok({ total_users: 3 }))
    expect(await admin.getAdminMetrics()).toEqual({ total_users: 3 })
    expect(http.get).toHaveBeenCalledWith('/api/v1/admin/metrics/')

    http.get.mockReturnValueOnce(ok({ id: 'u1' }))
    expect(await admin.getAdminUser('u1')).toEqual({ id: 'u1' })
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/admin/users/u1/')

    http.delete.mockReturnValueOnce(ok(null))
    await admin.deleteAdminUser('u1')
    expect(http.delete).toHaveBeenCalledWith('/api/v1/admin/users/u1/')
  })

  it('updateAdminUser sin rol ni estado envía un cuerpo vacío', async () => {
    http.patch.mockReturnValueOnce(ok({ id: 'u1', role: 'COMPRADOR' }))
    await admin.updateAdminUser('u1', {})
    expect(http.patch).toHaveBeenCalledWith('/api/v1/admin/users/u1/', {})
  })

  it('obras: pendientes, moderación, borrado y listado con las dos formas de respuesta', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 'p1' }]))
    expect(await admin.getPendingArtworks()).toEqual([{ id: 'p1' }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/admin/artworks/pending/')

    http.post.mockReturnValueOnce(ok({ id: 'a1' }))
    await admin.moderateArtwork('a1', { status: 'INACTIVA', reason: 'x' })
    expect(http.post).toHaveBeenCalledWith('/api/v1/admin/artworks/a1/moderate/', { status: 'INACTIVA', reason: 'x' })

    http.delete.mockReturnValueOnce(ok(null))
    await admin.deleteAdminArtwork('a1')
    expect(http.delete).toHaveBeenCalledWith('/api/v1/artworks/a1/delete/')

    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await admin.getAllArtworks({ page: 2 })).toEqual([{ id: 1 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/artworks/', { params: { page: 2 } })
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await admin.getAllArtworks()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await admin.getAllArtworks()).toEqual([])
  })

  it('eventos: pendientes y publicados (arreglo o paginado), aprobar y rechazar', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 'e1' }]))
    expect(await admin.getPendingEvents()).toEqual([{ id: 'e1' }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/', { params: { is_published: false } })
    http.get.mockReturnValueOnce(ok({ results: [{ id: 'e2' }] }))
    expect(await admin.getPendingEvents()).toEqual([{ id: 'e2' }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await admin.getPendingEvents()).toEqual([])

    http.get.mockReturnValueOnce(ok([{ id: 'e3' }]))
    expect(await admin.getApprovedEvents()).toEqual([{ id: 'e3' }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/', { params: { is_published: true } })
    http.get.mockReturnValueOnce(ok({ results: [{ id: 'e4' }] }))
    expect(await admin.getApprovedEvents()).toEqual([{ id: 'e4' }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await admin.getApprovedEvents()).toEqual([])

    http.post.mockReturnValueOnce(ok({ detail: 'ok' }))
    expect(await admin.approveEvent('e1')).toEqual({ detail: 'ok' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/events/e1/approve/')
    http.post.mockReturnValueOnce(ok({ detail: 'no' }))
    expect(await admin.rejectEvent('e1')).toEqual({ detail: 'no' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/events/e1/reject/')
  })

  it('transacciones y bitácora de notificaciones', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 't' }]))
    expect(await admin.getAdminTransactions()).toEqual([{ id: 't' }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/admin/transactions/')
    http.get.mockReturnValueOnce(ok([{ a: 1 }]))
    expect(await admin.getAdminNotificationsLog()).toEqual([{ a: 1 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/admin/notifications/log/')
  })
})

describe('artists.api', () => {
  const notFound = new AxiosError('x', 'ERR', undefined, undefined, { status: 404 } as AxiosResponse)

  it('listado: arreglo, paginado y sin resultados', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await artists.listArtistProfiles({ search: 'a' })).toEqual([{ id: 1 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/artists/', { params: { search: 'a' } })
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await artists.listArtistProfiles()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await artists.listArtistProfiles()).toEqual([])
  })

  it('mi perfil: existe, no existe (404) o falla de otra forma', async () => {
    http.get.mockReturnValueOnce(ok({ slug: 'yo' }))
    expect(await artists.getMyArtistProfile()).toEqual({ slug: 'yo' })
    http.get.mockRejectedValueOnce(notFound)
    expect(await artists.getMyArtistProfile()).toBeNull()
    const serverError = new AxiosError('x', 'ERR', undefined, undefined, { status: 500 } as AxiosResponse)
    http.get.mockRejectedValueOnce(serverError)
    await expect(artists.getMyArtistProfile()).rejects.toBe(serverError)
    http.get.mockRejectedValueOnce(new Error('red'))
    await expect(artists.getMyArtistProfile()).rejects.toThrow('red')
  })

  it('perfil por slug, crear, actualizar, subir foto, seguir y listas de seguidores', async () => {
    http.get.mockReturnValueOnce(ok({ slug: 'ana' }))
    expect(await artists.getArtistBySlug('ana')).toEqual({ slug: 'ana' })
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/artists/ana/')

    http.post.mockReturnValueOnce(ok({ slug: 'nuevo' }))
    await artists.createArtistProfile({ artistic_name: 'N' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/artists/', { artistic_name: 'N' })

    http.patch.mockReturnValueOnce(ok({ slug: 'ana' }))
    await artists.updateArtistProfile('ana', { city: 'Pasto' })
    expect(http.patch).toHaveBeenLastCalledWith('/api/v1/artists/ana/', { city: 'Pasto' })

    http.patch.mockReturnValueOnce(ok({ slug: 'ana' }))
    const file = new File(['x'], 'f.png')
    await artists.uploadArtistProfileImage('ana', file)
    const form = http.patch.mock.calls[1][1] as FormData
    expect(http.patch.mock.calls[1][0]).toBe('/api/v1/artists/ana/')
    expect(form.get('profile_image')).toBeInstanceOf(File)

    http.post.mockReturnValueOnce(ok({ detail: 'ok' }))
    expect(await artists.followArtist('ana')).toEqual({ detail: 'ok' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/artists/ana/follow/')

    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await artists.getArtistFollowers('ana')).toEqual([{ id: 1 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await artists.getArtistFollowers('ana')).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await artists.getArtistFollowers('ana')).toEqual([])

    http.get.mockReturnValueOnce(ok([{ id: 3 }]))
    expect(await artists.getMyFollowing()).toEqual([{ id: 3 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/artists/following/')
    http.get.mockReturnValueOnce(ok({ results: [{ id: 4 }] }))
    expect(await artists.getMyFollowing()).toEqual([{ id: 4 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await artists.getMyFollowing()).toEqual([])
  })
})

describe('artworks.api', () => {
  it('getArtworks: una respuesta en arreglo se envuelve como paginada', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 'a' }, { id: 'b' }]))
    expect(await artworks.getArtworks({ page: 1 })).toEqual({ count: 2, next: null, previous: null, results: [{ id: 'a' }, { id: 'b' }] })
    const page = { count: 1, next: null, previous: null, results: [{ id: 'a' }] }
    http.get.mockReturnValueOnce(ok(page))
    expect(await artworks.getArtworks()).toBe(page)
  })

  it('crear: envía solo los campos presentes como multipart', async () => {
    http.post.mockReturnValue(ok({ id: 'a' }))
    const file = new File(['x'], 'o.png')
    await artworks.createArtwork({
      title: 'T', description: 'D', category: 3, price: 5000, technique: 'Óleo', dimensions: '1x1', material: 'Lienzo', main_image: file,
    })
    const full = http.post.mock.calls[0][1] as FormData
    expect(Object.fromEntries([...full.entries()].filter(([k]) => k !== 'main_image'))).toEqual({
      title: 'T', description: 'D', category: '3', price: '5000', technique: 'Óleo', dimensions: '1x1', material: 'Lienzo',
    })
    expect(full.get('main_image')).toBeInstanceOf(File)
    expect(http.post.mock.calls[0][2]).toEqual({ headers: { 'Content-Type': 'multipart/form-data' } })

    await artworks.createArtwork({ title: 'T', description: 'D' })
    const minimal = http.post.mock.calls[1][1] as FormData
    expect([...minimal.keys()]).toEqual(['title', 'description'])
  })

  it('actualizar: igual, solo con lo presente', async () => {
    http.patch.mockReturnValue(ok({ id: 'a' }))
    const file = new File(['x'], 'o.png')
    await artworks.updateArtwork('a1', {
      title: 'T', description: 'D', category: 3, price: 0, technique: 'Óleo', dimensions: '1x1', material: 'Lienzo', main_image: file,
    })
    const full = http.patch.mock.calls[0][1] as FormData
    expect([...full.keys()].sort()).toEqual(['category', 'description', 'dimensions', 'main_image', 'material', 'price', 'technique', 'title'])
    expect(http.patch.mock.calls[0][0]).toBe('/api/v1/artworks/a1/')

    await artworks.updateArtwork('a1', {})
    expect([...(http.patch.mock.calls[1][1] as FormData).keys()]).toEqual([])
  })

  it('obra por id, borrado propio, IA y categorías', async () => {
    http.get.mockReturnValueOnce(ok({ id: 'a1' }))
    expect(await artworks.getArtworkById('a1')).toEqual({ id: 'a1' })
    http.delete.mockReturnValueOnce(ok(null))
    await artworks.deleteArtwork('a1')
    expect(http.delete).toHaveBeenCalledWith('/api/v1/artworks/a1/')

    http.post.mockReturnValue(ok({ ai_tags: {}, ai_description: 'x' }))
    await artworks.aiEnhanceArtwork('a1')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/artworks/a1/ai-enhance/', { regenerate_description: false })
    await artworks.aiEnhanceArtwork('a1', true)
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/artworks/a1/ai-enhance/', { regenerate_description: true })

    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await artworks.getArtworkCategories()).toEqual([{ id: 1 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await artworks.getArtworkCategories()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await artworks.getArtworkCategories()).toEqual([])
  })
})

describe('auctions.api', () => {
  it('lista, detalle, pujar y cerrar', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await auctions.getAuctions({ status: 'ACTIVA' })).toEqual([{ id: 1 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/auctions/', { params: { status: 'ACTIVA' } })
    http.get.mockReturnValueOnce(ok({ id: 7 }))
    expect(await auctions.getAuctionById(7)).toEqual({ id: 7 })
    http.post.mockReturnValueOnce(ok({ detail: 'ok', bid_id: 'b' }))
    await auctions.placeBid(7, 5000)
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/auctions/7/bid/', { amount: 5000 })
    http.post.mockReturnValueOnce(ok({ detail: 'ok' }))
    await auctions.closeAuction(7)
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/auctions/7/close/')
  })
})

describe('auth.api', () => {
  it('login: con { tokens, user } o con tokens sueltos y perfil aparte; sin tokens falla', async () => {
    http.post.mockReturnValueOnce(ok({ tokens: { access: 'a', refresh: 'r' }, user: { id: 'u', role: 'ARTISTA' } }))
    const direct = await auth.login({ email: 'a@b.c', password: 'x' })
    expect(direct.user.role).toBe('artist')
    expect(direct.tokens).toEqual({ access: 'a', refresh: 'r' })

    http.post.mockReturnValueOnce(ok({ access: 'a2', refresh: 'r2' }))
    http.get.mockReturnValueOnce(ok({ id: 'u2', role: 'COMPRADOR' }))
    const separate = await auth.login({ email: 'a@b.c', password: 'x' })
    expect(separate.user.role).toBe('buyer')
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/users/me/', { headers: { Authorization: 'Bearer a2' } })

    http.post.mockReturnValueOnce(ok({ access: 'solo-access' }))
    await expect(auth.login({ email: 'a@b.c', password: 'x' })).rejects.toThrow('Respuesta de autenticación inválida.')
  })

  it('registro y verificación de correo usan message, detail o un texto por defecto', async () => {
    http.post.mockReturnValueOnce(ok({ message: 'm' }))
    expect(await auth.register({} as never)).toEqual({ message: 'm' })
    http.post.mockReturnValueOnce(ok({ detail: 'd' }))
    expect(await auth.register({} as never)).toEqual({ message: 'd' })
    http.post.mockReturnValueOnce(ok({}))
    expect(await auth.register({} as never)).toEqual({ message: 'Registro exitoso.' })

    http.post.mockReturnValueOnce(ok({ message: 'm' }))
    expect(await auth.verifyEmail('t')).toEqual({ message: 'm' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/auth/verify-email/', { token: 't' })
    http.post.mockReturnValueOnce(ok({ detail: 'd' }))
    expect(await auth.verifyEmail('t')).toEqual({ message: 'd' })
    http.post.mockReturnValueOnce(ok({}))
    expect(await auth.verifyEmail('t')).toEqual({ message: 'Email verificado correctamente.' })
  })

  it('perfil, recuperar, restablecer y cambiar contraseña con { message } o { detail } o texto por defecto', async () => {
    http.get.mockReturnValueOnce(ok({ id: 'u', role: 'ARTISTA' }))
    expect((await auth.me()).role).toBe('artist')

    http.post.mockReturnValueOnce(ok({ message: 'm' }))
    expect(await auth.requestPasswordReset('a@b.c')).toEqual({ message: 'm' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/auth/password-reset/', { email: 'a@b.c' })
    http.post.mockReturnValueOnce(ok({ detail: 'd' }))
    expect(await auth.requestPasswordReset('a@b.c')).toEqual({ message: 'd' })
    http.post.mockReturnValueOnce(ok(undefined))
    expect(await auth.requestPasswordReset('a@b.c')).toEqual({ message: 'Si el correo existe, te enviamos instrucciones.' })

    http.post.mockReturnValueOnce(ok({}))
    expect(await auth.confirmPasswordReset('tok', 'nueva')).toEqual({ message: 'Contraseña actualizada.' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/auth/password-reset/confirm/', { token: 'tok', new_password: 'nueva' })

    http.post.mockReturnValueOnce(ok({ message: 'hecho' }))
    expect(await auth.changePassword('vieja', 'nueva')).toEqual({ message: 'hecho' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/users/me/password/', { current_password: 'vieja', new_password: 'nueva' })
  })

  it('actualizar perfil, subir avatar y eliminar cuenta', async () => {
    http.patch.mockReturnValueOnce(ok({ id: 'u', role: 'COMPRADOR' }))
    expect((await auth.updateMe({ first_name: 'A' })).role).toBe('buyer')
    expect(http.patch).toHaveBeenLastCalledWith('/api/v1/users/me/', { first_name: 'A' })

    http.patch.mockReturnValueOnce(ok({ id: 'u', role: 'COMPRADOR' }))
    await auth.uploadAvatar(new File(['x'], 'a.png'))
    expect((http.patch.mock.calls[1][1] as FormData).get('avatar')).toBeInstanceOf(File)

    http.delete.mockReturnValueOnce(ok(null))
    await auth.deleteAccount('clave')
    expect(http.delete).toHaveBeenCalledWith('/api/v1/auth/delete-account/', { data: { password: 'clave' } })
  })

  it('logout: sin refresh no llama al servidor; con refresh lo llama y tolera el fallo', async () => {
    localStorage.removeItem('refresh_token')
    await auth.logout()
    expect(http.post).not.toHaveBeenCalled()

    localStorage.setItem('refresh_token', 'r1')
    http.post.mockReturnValueOnce(Promise.reject(new Error('caído')))
    await expect(auth.logout()).resolves.toBeUndefined()
    expect(http.post).toHaveBeenCalledWith('/api/v1/auth/logout/', { refresh: 'r1' })
    localStorage.removeItem('refresh_token')
  })
})

describe('chat.api', () => {
  it('envía el mensaje con su historial (vacío por defecto)', async () => {
    http.post.mockReturnValue(ok({ reply: 'hola' }))
    expect(await sendChatMessage('hola')).toEqual({ reply: 'hola' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/chat/', { message: 'hola', history: [] })
    await sendChatMessage('x', [{ role: 'user', text: 'a' }])
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/chat/', { message: 'x', history: [{ role: 'user', text: 'a' }] })
  })
})

describe('events.api', () => {
  it('normalizeEventsResponse acepta arreglo, paginado, vacío y nulo', () => {
    const list = [{ id: 'e' }] as Event[]
    expect(normalizeEventsResponse(list)).toBe(list)
    expect(normalizeEventsResponse({ results: list })).toBe(list)
    expect(normalizeEventsResponse({})).toEqual([])
    expect(normalizeEventsResponse(null)).toEqual([])
    expect(normalizeEventsResponse(undefined)).toEqual([])
  })

  it('consultas: publicados, todos, por id y por rango', () => {
    eventsApi.getPublishedEvents({ event_type: 'TALLER' })
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/', { params: { is_published: true, event_type: 'TALLER' } })
    eventsApi.getPublishedEvents()
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/', { params: { is_published: true } })
    eventsApi.getAllEvents({ start_date: '2026-01-01' })
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/', { params: { start_date: '2026-01-01' } })
    eventsApi.getEventById('e1')
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/e1/')
    eventsApi.getEventsByDateRange('2026-01-01', '2026-01-31')
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/events/', {
      params: { is_published: true, start_date__gte: '2026-01-01', start_date__lte: '2026-01-31' },
    })
  })

  it('crear, actualizar, borrar, inscribirse y cancelar inscripción', () => {
    const payload = { title: 'T', description: 'D', event_type: 'OTRO', start_date: 'a', end_date: 'b', location: 'L' }
    eventsApi.createEvent(payload)
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/events/', payload)
    eventsApi.updateEvent('e1', { title: 'N' })
    expect(http.patch).toHaveBeenLastCalledWith('/api/v1/events/e1/', { title: 'N' })
    eventsApi.deleteEvent('e1')
    expect(http.delete).toHaveBeenLastCalledWith('/api/v1/events/e1/')
    eventsApi.registerToEvent('e1')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/events/e1/register/', {})
    eventsApi.unregisterFromEvent('e1')
    expect(http.delete).toHaveBeenLastCalledWith('/api/v1/events/e1/register/')
  })

  it('evento de artista con archivo: multipart con la entrada opcional', () => {
    const flyer = new File(['x'], 'f.png')
    const base = { title: 'T', description: 'D', event_type: 'OTRO', start_date: 'a', end_date: 'b', location: 'L', flyer }
    eventsApi.createArtistEvent({ ...base, ticket_url: 'https://t.co' })
    const withTicket = http.post.mock.calls[0][1] as FormData
    expect(withTicket.get('ticket_url')).toBe('https://t.co')
    expect(withTicket.get('is_published')).toBe('false')
    expect(withTicket.get('flyer')).toBeInstanceOf(File)
    expect(http.post.mock.calls[0][2]).toEqual({ headers: { 'Content-Type': 'multipart/form-data' } })

    eventsApi.createArtistEvent(base)
    expect((http.post.mock.calls[1][1] as FormData).has('ticket_url')).toBe(false)
  })

  it('evento de artista sin archivo: JSON con enlaces solo si existen', () => {
    const base = { title: 'T', description: 'D', event_type: 'OTRO', start_date: 'a', end_date: 'b', location: 'L' }
    eventsApi.createArtistEvent({ ...base, ticket_url: 'https://t.co', image_url: 'https://i.co/a.jpg' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/events/', { ...base, is_published: false, ticket_url: 'https://t.co', image_url: 'https://i.co/a.jpg' })
    eventsApi.createArtistEvent(base)
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/events/', { ...base, is_published: false })
  })
})

describe('marketplace.api', () => {
  it('carrito, favoritos y checkout', async () => {
    http.get.mockReturnValueOnce(ok({ id: 'c' }))
    expect(await market.getServerCart()).toEqual({ id: 'c' })
    http.post.mockReturnValueOnce(ok({ detail: 'ok' }))
    await market.addCartItem('a1')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/marketplace/cart/items/', { artwork_id: 'a1' })
    http.delete.mockReturnValueOnce(ok({ detail: 'ok' }))
    await market.removeCartItem('a1')
    expect(http.delete).toHaveBeenLastCalledWith('/api/v1/marketplace/cart/items/', { data: { artwork_id: 'a1' } })

    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await market.getFavorites()).toEqual([{ id: 1 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await market.getFavorites()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await market.getFavorites()).toEqual([])
    http.post.mockReturnValueOnce(ok({ detail: 'ok' }))
    await market.addFavorite('a1')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/marketplace/favorites/', { artwork_id: 'a1' })
    http.delete.mockReturnValueOnce(ok({ detail: 'ok' }))
    await market.removeFavorite('a1')
    expect(http.delete).toHaveBeenLastCalledWith('/api/v1/marketplace/favorites/', { data: { artwork_id: 'a1' } })

    http.post.mockReturnValue(ok({ order_id: 'o', total_amount: '1' }))
    await market.checkout()
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/marketplace/checkout/', { order_type: 'COMPRA_DIRECTA' })
    await market.checkout('SUBASTA')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/marketplace/checkout/', { order_type: 'SUBASTA' })
  })

  it('pedidos y ventas en arreglo, paginado o vacío', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await market.getOrders()).toEqual([{ id: 1 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/marketplace/orders/', { params: { page_size: 100 } })
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await market.getOrders()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await market.getOrders()).toEqual([])

    http.get.mockReturnValueOnce(ok([{ id: 3 }]))
    expect(await market.getSales()).toEqual([{ id: 3 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 4 }] }))
    expect(await market.getSales()).toEqual([{ id: 4 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await market.getSales()).toEqual([])
  })
})

describe('musicians.api', () => {
  const notFound = new AxiosError('x', 'ERR', undefined, undefined, { status: 404 } as AxiosResponse)

  it('listado: arreglo se envuelve, paginado pasa tal cual', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await musicians.listMusicians({ city: 'Pasto' })).toEqual({ count: 1, next: null, previous: null, results: [{ id: 1 }] })
    const page = { count: 0, next: null, previous: null, results: [] }
    http.get.mockReturnValueOnce(ok(page))
    expect(await musicians.listMusicians()).toBe(page)
  })

  it('perfil por slug y mi perfil (existe, 404, otro error)', async () => {
    http.get.mockReturnValueOnce(ok({ slug: 'duo' }))
    expect(await musicians.getMusicianBySlug('duo')).toEqual({ slug: 'duo' })
    http.get.mockReturnValueOnce(ok({ slug: 'yo' }))
    expect(await musicians.getMyMusicianProfile()).toEqual({ slug: 'yo' })
    http.get.mockRejectedValueOnce(notFound)
    expect(await musicians.getMyMusicianProfile()).toBeNull()
    http.get.mockRejectedValueOnce(new Error('red'))
    await expect(musicians.getMyMusicianProfile()).rejects.toThrow('red')
    const serverError = new AxiosError('x', 'ERR', undefined, undefined, { status: 500 } as AxiosResponse)
    http.get.mockRejectedValueOnce(serverError)
    await expect(musicians.getMyMusicianProfile()).rejects.toBe(serverError)
  })

  it('crear, actualizar, foto, seguir y seguidores', async () => {
    http.post.mockReturnValueOnce(ok({ slug: 'n' }))
    await musicians.createMusicianProfile({ artistic_name: 'N' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/musicians/', { artistic_name: 'N' })
    http.patch.mockReturnValueOnce(ok({}))
    await musicians.updateMusicianProfile('duo', { city: 'X' })
    expect(http.patch).toHaveBeenLastCalledWith('/api/v1/musicians/duo/', { city: 'X' })
    http.patch.mockReturnValueOnce(ok({}))
    await musicians.uploadMusicianProfileImage('duo', new File(['x'], 'f.png'))
    expect((http.patch.mock.calls[1][1] as FormData).get('profile_image')).toBeInstanceOf(File)
    http.post.mockReturnValueOnce(ok({ detail: 'ok' }))
    await musicians.followMusician('duo')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/musicians/duo/follow/')

    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await musicians.getMusicianFollowers('duo')).toEqual([{ id: 1 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await musicians.getMusicianFollowers('duo')).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await musicians.getMusicianFollowers('duo')).toEqual([])
    http.get.mockReturnValueOnce(ok([{ id: 3 }]))
    expect(await musicians.getMyMusicianFollowing()).toEqual([{ id: 3 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 4 }] }))
    expect(await musicians.getMyMusicianFollowing()).toEqual([{ id: 4 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await musicians.getMyMusicianFollowing()).toEqual([])
  })

  it('obras de un músico (con y sin tipo), reseñas y géneros', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await musicians.getMusicianWorks('duo', 'VIDEO')).toEqual([{ id: 1 }])
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/musicians/duo/works/', { params: { type: 'VIDEO' } })
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    await musicians.getMusicianWorks('duo')
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/musicians/duo/works/', { params: undefined })
    http.get.mockReturnValueOnce(ok({}))
    expect(await musicians.getMusicianWorks('duo')).toEqual([])

    http.get.mockReturnValueOnce(ok([{ id: 5 }]))
    expect(await musicians.getMusicianReviews('duo')).toEqual([{ id: 5 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 6 }] }))
    expect(await musicians.getMusicianReviews('duo')).toEqual([{ id: 6 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await musicians.getMusicianReviews('duo')).toEqual([])

    http.get.mockReturnValueOnce(ok([{ id: 7 }]))
    expect(await musicians.getMusicGenres()).toEqual([{ id: 7 }])
    http.post.mockReturnValueOnce(ok({ count: 0 }))
    await musicians.musicDiscovery('rock')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/music-discovery/recommendations/', { query: 'rock' })
  })

  it('obras propias: listar, crear, ver, actualizar, borrar, registrar vista y reseñar', async () => {
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await musicians.listMyMusicalWorks()).toEqual([{ id: 1 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await musicians.listMyMusicalWorks()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await musicians.listMyMusicalWorks()).toEqual([])

    http.post.mockReturnValueOnce(ok({ id: 'w' }))
    await musicians.createMusicalWork({ title: 'T', work_type: 'VIDEO' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/musicians/works/', { title: 'T', work_type: 'VIDEO' })
    http.get.mockReturnValueOnce(ok({ id: 'w' }))
    expect(await musicians.getMusicalWork('w')).toEqual({ id: 'w' })
    http.patch.mockReturnValueOnce(ok({ id: 'w' }))
    await musicians.updateMusicalWork('w', { title: 'N' })
    expect(http.patch).toHaveBeenLastCalledWith('/api/v1/musicians/works/w/', { title: 'N' })
    http.delete.mockReturnValueOnce(ok(null))
    await musicians.deleteMusicalWork('w')
    expect(http.delete).toHaveBeenLastCalledWith('/api/v1/musicians/works/w/')
    http.post.mockReturnValueOnce(ok(null))
    await musicians.registerWorkView('w')
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/musicians/works/w/view/')
    http.post.mockReturnValueOnce(ok({ id: 'r' }))
    await musicians.addMusicianReview('duo', { rating: 5, comment: 'bien' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/musicians/duo/reviews/', { rating: 5, comment: 'bien' })
  })
})

describe('notifications.api', () => {
  it('lista (con y sin filtro de no leídas), contador, marcar una y marcar todas', async () => {
    http.get.mockReturnValue(ok({ results: [] }))
    await notifications.listNotifications({ unread: true, page: 2 })
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/notifications/', { params: { unread: 'true', page: 2 } })
    await notifications.listNotifications()
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/notifications/', { params: { unread: undefined, page: undefined } })

    http.get.mockReturnValueOnce(ok({ unread: 4 }))
    expect(await notifications.getUnreadNotificationsCount()).toBe(4)
    http.post.mockReturnValueOnce(ok({ id: 'n' }))
    expect(await notifications.markNotificationRead('n')).toEqual({ id: 'n' })
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/notifications/n/read/')
    http.post.mockReturnValueOnce(ok({ updated: 9 }))
    expect(await notifications.markAllNotificationsRead()).toBe(9)
  })
})

describe('payments.api', () => {
  const payment = {
    transaction_id: 't', public_key: 'pub key', reference: 'ref/1', amount_in_cents: 150000, currency: 'COP', integrity_signature: 'sig=',
  }

  it('iniciar pago y consultar transacciones y recibo', async () => {
    http.post.mockReturnValueOnce(ok(payment))
    expect(await payments.initiatePayment('o1')).toEqual(payment)
    expect(http.post).toHaveBeenLastCalledWith('/api/v1/payments/initiate/', { order_id: 'o1' })
    http.get.mockReturnValueOnce(ok([{ id: 1 }]))
    expect(await payments.getTransactions()).toEqual([{ id: 1 }])
    http.get.mockReturnValueOnce(ok({ results: [{ id: 2 }] }))
    expect(await payments.getTransactions()).toEqual([{ id: 2 }])
    http.get.mockReturnValueOnce(ok({}))
    expect(await payments.getTransactions()).toEqual([])
    http.get.mockReturnValueOnce(ok({ receipt_url: 'u' }))
    expect(await payments.getTransactionReceipt('t1')).toEqual({ receipt_url: 'u' })
    expect(http.get).toHaveBeenLastCalledWith('/api/v1/payments/transactions/t1/receipt/')
  })

  it('arma la URL del checkout de Wompi con los parámetros codificados', () => {
    const url = payments.buildWompiCheckoutUrl(payment, 'https://app.test/payment/pending')
    expect(url).toBe(
      'https://checkout.wompi.co/p/?public-key=pub%20key&currency=COP&amount-in-cents=150000&reference=ref%2F1&signature:integrity=sig%3D&redirect-url=https%3A%2F%2Fapp.test%2Fpayment%2Fpending',
    )
  })

  it('sin llave pública o sin referencia no hay URL', () => {
    expect(payments.buildWompiCheckoutUrl({ ...payment, public_key: '' }, 'x')).toBeNull()
    expect(payments.buildWompiCheckoutUrl({ ...payment, reference: '' }, 'x')).toBeNull()
  })
})
