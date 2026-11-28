import { describe, it, expect } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'

import { ArtworkImage } from '@/components/artworks/artwork-image'

describe('ArtworkImage', () => {
  it('con foto la muestra', () => {
    render(<ArtworkImage src="https://img.test/obra.jpg" alt="Obra" />)
    expect(screen.getByAltText('Obra')).toHaveAttribute('src', 'https://img.test/obra.jpg')
  })

  it('sin foto muestra el recuadro con la paleta', () => {
    render(<ArtworkImage src={null} alt="Sin foto" />)
    expect(screen.getByRole('img', { name: 'Sin foto' })).toBeInTheDocument()
    expect(screen.queryByAltText('Sin foto')).not.toBeInTheDocument()
  })

  it('si la foto no carga cambia al recuadro', () => {
    render(<ArtworkImage src="https://img.test/rota.jpg" alt="Rota" />)
    fireEvent.error(screen.getByAltText('Rota'))
    expect(screen.queryByAltText('Rota')).not.toBeInTheDocument()
    expect(screen.getByRole('img', { name: 'Rota' })).toBeInTheDocument()
  })
})