import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'

import { ArtistCardSkeleton, ArtworkCardSkeleton, MusicianCardSkeleton, Skeleton } from '@/components/ui/skeleton'

describe('Skeleton', () => {
  it('Skeleton aplica la animación y la clase recibida', () => {
    const { container } = render(<Skeleton className="h-9" />)
    expect(container.firstChild).toHaveClass('animate-pulse', 'h-9')
  })

  it('Skeleton sin clase propia usa solo las base', () => {
    const { container } = render(<Skeleton />)
    expect(container.firstChild).toHaveClass('animate-pulse')
  })

  it.each([
    ['obra', ArtworkCardSkeleton, 6],
    ['artista', ArtistCardSkeleton, 6],
    ['músico', MusicianCardSkeleton, 7],
  ])('el esqueleto de tarjeta de %s dibuja sus bloques animados', (_name, Component, blocks) => {
    const { container } = render(<Component />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(blocks)
  })
})
