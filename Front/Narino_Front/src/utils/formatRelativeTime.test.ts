import { describe, it, expect } from 'vitest'

import { formatRelativeTime } from '@/utils'

const NOW = new Date('2026-11-21T12:00:00-05:00')
const ago = (seconds: number) => new Date(NOW.getTime() - seconds * 1000)

describe('formatRelativeTime', () => {
  it('describe el tiempo transcurrido en español', () => {
    expect(formatRelativeTime(ago(20), NOW)).toBe('hace un momento')
    expect(formatRelativeTime(ago(5 * 60), NOW)).toBe('hace 5 minutos')
    expect(formatRelativeTime(ago(3 * 3600), NOW)).toBe('hace 3 horas')
    expect(formatRelativeTime(ago(26 * 3600), NOW)).toBe('ayer')
  })

  it('pasada una semana muestra la fecha', () => {
    expect(formatRelativeTime('2026-11-01T12:00:00-05:00', NOW)).toMatch(/^1 de nov.*2026$/)
  })

  it('devuelve el respaldo con fechas vacías o inválidas', () => {
    expect(formatRelativeTime(null, NOW)).toBe('')
    expect(formatRelativeTime('no-es-fecha', NOW, '—')).toBe('—')
  })
})
