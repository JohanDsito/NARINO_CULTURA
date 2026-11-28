import { describe, it, expect } from 'vitest'

import { artworkStatus } from '@/constants/labels'
import { ANY_AUTH, ROLE } from '@/constants/roles'
import { ROUTES } from '@/constants/routes'

describe('constantes', () => {
  it('artworkStatus devuelve etiqueta y variante conocidas o el texto tal cual', () => {
    expect(artworkStatus('DISPONIBLE')).toEqual({ label: 'Disponible', variant: 'verde' })
    expect(artworkStatus('INVENTADO')).toEqual({ label: 'INVENTADO', variant: 'secondary' })
  })

  it('ANY_AUTH incluye los cuatro roles', () => {
    expect([...ANY_AUTH].sort()).toEqual(Object.values(ROLE).sort())
  })

  it('ROUTES arma las rutas con parámetros', () => {
    expect(ROUTES.ARTIST_DETAIL('ana')).toBe('/artists/ana')
    expect(ROUTES.ARTWORK_DETAIL(5)).toBe('/artworks/5')
    expect(ROUTES.AUCTION_DETAIL('a1')).toBe('/auctions/a1')
    expect(ROUTES.EVENT_DETAIL('e1')).toBe('/events/e1')
    expect(ROUTES.MUSICIAN_DETAIL('duo')).toBe('/musicians/duo')
    expect(ROUTES.DASHBOARD.ARTWORK_EDIT(9)).toBe('/dashboard/artworks/9/edit')
    expect(ROUTES.DASHBOARD.MUSICIAN.WORK_EDIT('w1')).toBe('/dashboard/musician/works/w1/edit')
  })
})
