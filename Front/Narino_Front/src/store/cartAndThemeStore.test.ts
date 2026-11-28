import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import { getCartCount, getCartSubtotalCop, useCartStore, type CartItem } from '@/store/cartStore'
import { getSystemTheme, useThemeStore, watchSystemTheme } from '@/store/themeStore'

const ITEM = { id: 'a1', artwork_id: 'a1', title: 'Volcán', artist_name: 'Ana', price: 100000, image: '' }

describe('cartStore', () => {
  beforeEach(() => useCartStore.setState({ items: [], isOpen: false }))

  it('agrega una obra una sola vez (cada obra es única)', () => {
    useCartStore.getState().addItem(ITEM)
    useCartStore.getState().addItem(ITEM)
    expect(useCartStore.getState().items).toEqual([{ ...ITEM, quantity: 1 }])
  })

  it('quita una obra y vacía el carrito', () => {
    const { addItem, removeItem, clearCart } = useCartStore.getState()
    addItem(ITEM)
    addItem({ ...ITEM, id: 'a2', artwork_id: 'a2', price: 50000 })
    removeItem('a1')
    expect(useCartStore.getState().items.map((i) => i.artwork_id)).toEqual(['a2'])
    clearCart()
    expect(useCartStore.getState().items).toEqual([])
  })

  it('actualiza la cantidad solo de la obra indicada y calcula total y cantidad', () => {
    const { addItem, updateQuantity } = useCartStore.getState()
    addItem(ITEM)
    addItem({ ...ITEM, id: 'a2', artwork_id: 'a2', price: 50000 })
    updateQuantity('a1', 3)
    const state = useCartStore.getState()
    expect(state.items.find((i) => i.artwork_id === 'a1')?.quantity).toBe(3)
    expect(state.items.find((i) => i.artwork_id === 'a2')?.quantity).toBe(1)
    expect(state.total()).toBe(350000)
    expect(state.itemCount()).toBe(4)
  })

  it('abre y cierra el panel', () => {
    useCartStore.getState().toggleCart()
    expect(useCartStore.getState().isOpen).toBe(true)
    useCartStore.getState().toggleCart()
    expect(useCartStore.getState().isOpen).toBe(false)
  })

  it('getCartCount y getCartSubtotalCop suman cantidades y precios', () => {
    const items = [
      { ...ITEM, quantity: 2 },
      { ...ITEM, price: 1000, quantity: 3 },
    ] as CartItem[]
    expect(getCartCount(items)).toBe(5)
    expect(getCartSubtotalCop(items)).toBe(203000)
    expect(getCartCount([])).toBe(0)
  })

  it('solo persiste los productos, no el estado del panel', () => {
    useCartStore.getState().addItem(ITEM)
    useCartStore.getState().toggleCart()
    const saved = JSON.parse(localStorage.getItem('cart-storage')!)
    expect(saved.state).toEqual({ items: [{ ...ITEM, quantity: 1 }] })
  })
})

describe('themeStore', () => {
  const listeners: ((e: { matches: boolean }) => void)[] = []

  function mockMedia(matches: boolean, legacy = false) {
    const add = vi.fn((_: string, cb: (e: { matches: boolean }) => void) => listeners.push(cb))
    const remove = vi.fn()
    const addListener = vi.fn((cb: (e: { matches: boolean }) => void) => listeners.push(cb))
    const removeListener = vi.fn()
    window.matchMedia = vi.fn().mockReturnValue({
      matches,
      addEventListener: legacy ? undefined : add,
      removeEventListener: remove,
      addListener,
      removeListener,
    })
    return { add, remove, addListener, removeListener }
  }

  beforeEach(() => {
    listeners.length = 0
    document.documentElement.classList.remove('dark')
  })
  afterEach(() => vi.unstubAllGlobals())

  it('toggle alterna el tema y aplica la clase dark al documento', () => {
    useThemeStore.setState({ theme: 'light' })
    useThemeStore.getState().toggle()
    expect(useThemeStore.getState().theme).toBe('dark')
    expect(document.documentElement).toHaveClass('dark')
    useThemeStore.getState().toggle()
    expect(useThemeStore.getState().theme).toBe('light')
    expect(document.documentElement).not.toHaveClass('dark')
  })

  it('setTheme fija el tema indicado y solo persiste el tema', () => {
    useThemeStore.getState().setTheme('dark')
    expect(document.documentElement).toHaveClass('dark')
    expect(JSON.parse(localStorage.getItem('nc-theme-store')!).state).toEqual({ theme: 'dark' })
    useThemeStore.getState().setTheme('light')
    expect(document.documentElement).not.toHaveClass('dark')
  })

  it('al rehidratar aplica el tema guardado, o el del sistema si no hay estado', async () => {
    localStorage.setItem('nc-theme-store', JSON.stringify({ state: { theme: 'dark' }, version: 0 }))
    await useThemeStore.persist.rehydrate()
    expect(document.documentElement).toHaveClass('dark')

    document.documentElement.classList.remove('dark')
    localStorage.removeItem('nc-theme-store')
    mockMedia(true)
    await useThemeStore.persist.rehydrate()
    expect(document.documentElement).toHaveClass('dark')
  })

  it('getSystemTheme lee la preferencia del sistema y sin ventana asume claro', () => {
    mockMedia(true)
    expect(getSystemTheme()).toBe('dark')
    mockMedia(false)
    expect(getSystemTheme()).toBe('light')
    vi.stubGlobal('window', undefined)
    expect(getSystemTheme()).toBe('light')
  })

  it('watchSystemTheme avisa de los cambios y se puede cancelar', () => {
    const { add, remove } = mockMedia(false)
    const callback = vi.fn()
    const stop = watchSystemTheme(callback)
    expect(add).toHaveBeenCalledWith('change', expect.any(Function))
    listeners[0]({ matches: true })
    listeners[0]({ matches: false })
    expect(callback).toHaveBeenNthCalledWith(1, 'dark')
    expect(callback).toHaveBeenNthCalledWith(2, 'light')
    stop?.()
    expect(remove).toHaveBeenCalledWith('change', expect.any(Function))
  })

  it('watchSystemTheme en navegadores antiguos usa addListener', () => {
    const { addListener, removeListener } = mockMedia(false, true)
    const callback = vi.fn()
    const stop = watchSystemTheme(callback)
    expect(addListener).toHaveBeenCalled()
    listeners[0]({ matches: true })
    expect(callback).toHaveBeenCalledWith('dark')
    stop?.()
    expect(removeListener).toHaveBeenCalled()
  })

  it('watchSystemTheme sin ventana no hace nada', () => {
    vi.stubGlobal('window', undefined)
    expect(watchSystemTheme(vi.fn())).toBeUndefined()
  })
})
