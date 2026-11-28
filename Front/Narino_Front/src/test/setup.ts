import '@testing-library/jest-dom/vitest'
import { TextDecoder, TextEncoder } from 'node:util'
import { configure } from '@testing-library/react'
import { vi } from 'vitest'

// La suite completa corre con varios archivos en paralelo: 1 s (por defecto) es poco para findBy*/waitFor
configure({ asyncUtilTimeout: 5000 })

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
