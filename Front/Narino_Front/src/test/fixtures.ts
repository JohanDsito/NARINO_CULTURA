import type { Artwork } from '@/types'

/** Obra de ejemplo con todos los campos; cada prueba sobreescribe lo que necesita. */
export function makeArtwork(overrides: Partial<Artwork> = {}): Artwork {
  return {
    id: 'art-1',
    title: 'Volcán Galeras',
    description: 'Óleo sobre lienzo',
    price: '350000.00',
    category: 1,
    category_detail: { id: 1, name: 'Pintura', slug: 'pintura' },
    technique: 'Óleo',
    dimensions: '50x70',
    material: 'Lienzo',
    status: 'DISPONIBLE',
    main_image_url: 'https://img.test/volcan.jpg',
    ai_tags: {},
    ai_description: '',
    views_count: 0,
    images: [],
    artist: 'artist-1',
    artist_slug: 'ana-barniz',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

export function paginated<T>(results: T[], extra: { next?: string | null; previous?: string | null; count?: number } = {}) {
  return {
    count: extra.count ?? results.length,
    next: extra.next ?? null,
    previous: extra.previous ?? null,
    results,
  }
}
