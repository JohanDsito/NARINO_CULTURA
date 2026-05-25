import '@testing-library/jest-dom/vitest'
import { TextDecoder, TextEncoder } from 'util'
import { vi } from 'vitest'

Object.assign(globalThis, { TextDecoder, TextEncoder })

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})
