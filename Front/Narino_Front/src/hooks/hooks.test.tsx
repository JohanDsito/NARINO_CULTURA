import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { act, renderHook, waitFor } from '@testing-library/react'
import { MemoryRouter, useLocation } from 'react-router-dom'
import { toast } from 'sonner'

import { authApi } from '@/api/auth.api'
import { addCartItem, getServerCart } from '@/api/marketplace.api'
import { getUnreadNotificationsCount } from '@/api/notifications.api'
import { buildWompiCheckoutUrl, initiatePayment } from '@/api/payments.api'
import { useLogin, useLogout, useRegister } from '@/hooks/useAuth'
import { useCartCount } from '@/hooks/useCartCount'
import { syncCartToServer } from '@/hooks/useCartSync'
import { useStartPayment } from '@/hooks/useStartPayment'
import { useUnreadNotifications } from '@/hooks/useUnreadNotifications'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'
import type { User } from '@/types'

vi.mock('@/api/auth.api', () => ({ authApi: { login: vi.fn(), register: vi.fn(), logout: vi.fn() } }))
vi.mock('@/api/marketplace.api', () => ({ addCartItem: vi.fn(), getServerCart: vi.fn() }))
vi.mock('@/api/notifications.api', () => ({ getUnreadNotificationsCount: vi.fn() }))
vi.mock('@/api/payments.api', () => ({ initiatePayment: vi.fn(), buildWompiCheckoutUrl: vi.fn() }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

function setup() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })
  const wrapper = ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  )
  return { queryClient, wrapper }
}

/** Hook + ubicación actual, para comprobar a dónde navega. */
function withLocation<T>(hook: () => T) {
  return () => ({ value: hook(), location: useLocation() })
}

const ITEM = { id: 'a1', artwork_id: 'a1', title: 'V', artist_name: 'A', price: 1, image: '' }
const tokens = { access: 'acc', refresh: 'ref' }

describe('useLogin', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    useAuthStore.setState({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false })
    useCartStore.setState({ items: [] })
  })

  it.each([
    ['admin', '/admin/dashboard'],
    ['cultural_manager', '/events'],
    ['buyer', '/marketplace'],
    ['artist', '/dashboard'],
    ['desconocido', '/'],
  ])('rol %s: guarda la sesión, saluda y navega a %s', async (role, path) => {
    vi.mocked(authApi.login).mockResolvedValue({ tokens, user: { id: 'u1', first_name: 'Ana', role } as User } as never)
    const { wrapper, queryClient } = setup()
    queryClient.setQueryData(['auth', 'me'], { viejo: true })
    const { result } = renderHook(withLocation(useLogin), { wrapper })
    await act(async () => {
      await result.current.value.mutateAsync({ email: 'a@b.c', password: 'x' } as never)
    })
    expect(toast.success).toHaveBeenCalledWith('Bienvenido, Ana')
    expect(result.current.location.pathname).toBe(path)
    expect(useAuthStore.getState().accessToken).toBe('acc')
    expect(queryClient.getQueryData(['auth', 'me'])).toBeUndefined()
  })

  it('una artista con disciplina de música va a su panel musical', async () => {
    localStorage.setItem('artist_discipline_u1', 'musico')
    vi.mocked(authApi.login).mockResolvedValue({ tokens, user: { id: 'u1', first_name: 'Ana', role: 'artist' } as User } as never)
    const { result } = renderHook(withLocation(useLogin), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.value.mutateAsync({ email: 'a@b.c', password: 'x' } as never)
    })
    expect(result.current.location.pathname).toBe('/dashboard/musician/profile')
  })

  it('sincroniza el carrito de invitado con el del servidor al iniciar sesión', async () => {
    useCartStore.setState({ items: [{ ...ITEM, quantity: 1 }] })
    vi.mocked(addCartItem).mockResolvedValue({ detail: 'ok' })
    vi.mocked(authApi.login).mockResolvedValue({ tokens, user: { id: 'u1', first_name: 'Ana', role: 'buyer' } as User } as never)
    const { result } = renderHook(withLocation(useLogin), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.value.mutateAsync({ email: 'a@b.c', password: 'x' } as never)
    })
    await waitFor(() => expect(useCartStore.getState().items).toHaveLength(0))
    expect(addCartItem).toHaveBeenCalledWith('a1')
  })

  it('credenciales incorrectas avisan y no inician sesión', async () => {
    vi.mocked(authApi.login).mockRejectedValue(new Error('401'))
    const { result } = renderHook(withLocation(useLogin), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.value.mutateAsync({ email: 'a@b.c', password: 'x' } as never).catch(() => {})
    })
    expect(toast.error).toHaveBeenCalledWith('Credenciales incorrectas. Verifica tu email y contraseña.')
    expect(useAuthStore.getState().isAuthenticated).toBe(false)
  })
})

describe('useRegister', () => {
  beforeEach(() => vi.clearAllMocks())

  it('al registrarse avisa y lleva al login', async () => {
    vi.mocked(authApi.register).mockResolvedValue({} as never)
    const { result } = renderHook(withLocation(useRegister), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.value.mutateAsync({} as never)
    })
    expect(toast.success).toHaveBeenCalledWith('Cuenta creada. Revisa tu correo para verificar tu cuenta.')
    expect(result.current.location.pathname).toBe('/login')
  })

  it('si falla avisa que el correo puede estar en uso', async () => {
    vi.mocked(authApi.register).mockRejectedValue(new Error('400'))
    const { result } = renderHook(withLocation(useRegister), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.value.mutateAsync({} as never).catch(() => {})
    })
    expect(toast.error).toHaveBeenCalledWith('Error al crear la cuenta. El email puede estar en uso.')
  })
})

describe('useLogout', () => {
  it('cierra la sesión en el servidor y en el cliente, limpia la caché y va al login', async () => {
    vi.clearAllMocks()
    vi.mocked(authApi.logout).mockResolvedValue(undefined)
    useAuthStore.setState({ user: { id: 'u' } as User, accessToken: 'a', refreshToken: 'r', isAuthenticated: true })
    const { wrapper, queryClient } = setup()
    queryClient.setQueryData(['algo'], 1)
    const { result } = renderHook(withLocation(useLogout), { wrapper })
    await act(async () => {
      await result.current.value()
    })
    expect(authApi.logout).toHaveBeenCalled()
    expect(useAuthStore.getState().isAuthenticated).toBe(false)
    expect(queryClient.getQueryData(['algo'])).toBeUndefined()
    expect(toast.success).toHaveBeenCalledWith('Sesión cerrada exitosamente')
    expect(result.current.location.pathname).toBe('/login')
  })
})

describe('syncCartToServer', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useCartStore.setState({ items: [] })
  })

  it('sin obras locales no llama al servidor', async () => {
    await syncCartToServer()
    expect(addCartItem).not.toHaveBeenCalled()
  })

  it('vacía el carrito local si al menos una obra se pasó al servidor', async () => {
    useCartStore.setState({ items: [{ ...ITEM, quantity: 1 }, { ...ITEM, id: 'a2', artwork_id: 'a2', quantity: 1 }] })
    vi.mocked(addCartItem).mockResolvedValueOnce({ detail: 'ok' }).mockRejectedValueOnce(new Error('x'))
    await syncCartToServer()
    expect(useCartStore.getState().items).toEqual([])
  })

  it('si todas fallan conserva el carrito local', async () => {
    useCartStore.setState({ items: [{ ...ITEM, quantity: 1 }] })
    vi.mocked(addCartItem).mockRejectedValue(new Error('x'))
    await syncCartToServer()
    expect(useCartStore.getState().items).toHaveLength(1)
  })
})

describe('useCartCount', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useCartStore.setState({ items: [{ ...ITEM, quantity: 1 }, { ...ITEM, id: 'a2', artwork_id: 'a2', quantity: 1 }] })
  })

  it('invitado: cuenta las obras del carrito local', () => {
    useAuthStore.setState({ isAuthenticated: false })
    const { result } = renderHook(() => useCartCount(), { wrapper: setup().wrapper })
    expect(result.current).toBe(2)
    expect(getServerCart).not.toHaveBeenCalled()
  })

  it('con sesión: cuenta las del servidor (0 mientras carga)', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    vi.mocked(getServerCart).mockResolvedValue({ items: [{}, {}, {}] } as never)
    const { result } = renderHook(() => useCartCount(), { wrapper: setup().wrapper })
    expect(result.current).toBe(0)
    await waitFor(() => expect(result.current).toBe(3))
  })
})

describe('useUnreadNotifications', () => {
  beforeEach(() => vi.clearAllMocks())

  it('sin sesión devuelve 0 sin consultar', () => {
    useAuthStore.setState({ isAuthenticated: false })
    const { result } = renderHook(() => useUnreadNotifications(), { wrapper: setup().wrapper })
    expect(result.current).toBe(0)
    expect(getUnreadNotificationsCount).not.toHaveBeenCalled()
  })

  it('con sesión devuelve el contador del servidor (0 mientras carga)', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    vi.mocked(getUnreadNotificationsCount).mockResolvedValue(5)
    const { result } = renderHook(() => useUnreadNotifications(), { wrapper: setup().wrapper })
    expect(result.current).toBe(0)
    await waitFor(() => expect(result.current).toBe(5))
  })
})

describe('useStartPayment', () => {
  const payment = { transaction_id: 't' } as never
  const assign = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubGlobal('location', { ...window.location, origin: 'https://app.test', assign })
  })
  afterEach(() => vi.unstubAllGlobals())

  it('redirige al checkout de Wompi con la URL de retorno a /payment/pending', async () => {
    vi.mocked(initiatePayment).mockResolvedValue(payment)
    vi.mocked(buildWompiCheckoutUrl).mockReturnValue('https://checkout.wompi.co/p/?x')
    const { result } = renderHook(() => useStartPayment(), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.mutateAsync('o1')
    })
    expect(initiatePayment).toHaveBeenCalledWith('o1')
    expect(buildWompiCheckoutUrl).toHaveBeenCalledWith(payment, 'https://app.test/payment/pending')
    expect(assign).toHaveBeenCalledWith('https://checkout.wompi.co/p/?x')
  })

  it('sin pasarela configurada avisa y lleva a los pedidos con la orden', async () => {
    vi.mocked(initiatePayment).mockResolvedValue(payment)
    vi.mocked(buildWompiCheckoutUrl).mockReturnValue(null)
    const { result } = renderHook(withLocation(useStartPayment), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.value.mutateAsync('o1')
    })
    expect(toast.error).toHaveBeenCalledWith('La pasarela de pago no está configurada. Intenta más tarde.')
    expect(result.current.location.pathname).toBe('/orders')
    expect(result.current.location.state).toEqual({ orderId: 'o1' })
    expect(assign).not.toHaveBeenCalled()
  })

  it('si iniciar el pago falla muestra el error', async () => {
    vi.mocked(initiatePayment).mockRejectedValue(new Error('Orden no pendiente'))
    const { result } = renderHook(() => useStartPayment(), { wrapper: setup().wrapper })
    await act(async () => {
      await result.current.mutateAsync('o1').catch(() => {})
    })
    expect(toast.error).toHaveBeenCalledWith('Orden no pendiente')
  })
})
