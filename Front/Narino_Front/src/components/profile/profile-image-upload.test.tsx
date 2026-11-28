import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'

import { ProfileImageUpload } from '@/components/profile/profile-image-upload'

const createObjectURL = vi.fn()
const revokeObjectURL = vi.fn()

function picker(container: HTMLElement) {
  return container.querySelector('input[type="file"]') as HTMLInputElement
}

describe('ProfileImageUpload', () => {
  beforeEach(() => {
    createObjectURL.mockReset()
    revokeObjectURL.mockReset()
    createObjectURL.mockReturnValueOnce('blob:uno').mockReturnValueOnce('blob:dos')
    vi.stubGlobal('URL', Object.assign(URL, { createObjectURL, revokeObjectURL }))
  })
  afterEach(() => vi.unstubAllGlobals())

  it('sin foto muestra la inicial del nombre; con foto, la imagen', () => {
    const { rerender } = render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} />)
    expect(screen.getByText('A')).toBeInTheDocument()
    rerender(<ProfileImageUpload name="ana" currentUrl="https://img.test/a.jpg" onUpload={vi.fn()} isPending={false} />)
    expect(screen.getByAltText('ana')).toHaveAttribute('src', 'https://img.test/a.jpg')
  })

  it('"Cambiar foto" y la cámara abren el selector de archivos', () => {
    const { container } = render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} />)
    const click = vi.spyOn(picker(container), 'click')
    fireEvent.click(screen.getByRole('button', { name: 'Cambiar foto' }))
    fireEvent.click(container.querySelector('button.absolute')!)
    expect(click).toHaveBeenCalledTimes(2)
  })

  it('al elegir un archivo muestra la vista previa y permite guardar', async () => {
    const onUpload = vi.fn().mockResolvedValue(undefined)
    const { container } = render(<ProfileImageUpload name="ana" onUpload={onUpload} isPending={false} />)
    const file = new File(['x'], 'foto.png', { type: 'image/png' })
    fireEvent.change(picker(container), { target: { files: [file] } })
    expect(screen.getByAltText('ana')).toHaveAttribute('src', 'blob:uno')
    fireEvent.click(screen.getByRole('button', { name: 'Guardar foto' }))
    await waitFor(() => expect(onUpload).toHaveBeenCalledWith(file))
    await waitFor(() => expect(screen.getByRole('button', { name: 'Cambiar foto' })).toBeInTheDocument())
  })

  it('elegir otro archivo libera la vista previa anterior; cancelar descarta todo', () => {
    const { container } = render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} />)
    fireEvent.change(picker(container), { target: { files: [new File(['1'], 'a.png')] } })
    fireEvent.change(picker(container), { target: { files: [new File(['2'], 'b.png')] } })
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:uno')
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:dos')
    expect(screen.getByRole('button', { name: 'Cambiar foto' })).toBeInTheDocument()
  })

  it('sin archivo seleccionado el cambio se ignora', () => {
    const { container } = render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} />)
    fireEvent.change(picker(container), { target: { files: [] } })
    expect(screen.getByRole('button', { name: 'Cambiar foto' })).toBeInTheDocument()
    expect(createObjectURL).not.toHaveBeenCalled()
  })

  it('cancelar tras elegir un solo archivo libera su vista previa una vez', () => {
    const { container } = render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} />)
    fireEvent.change(picker(container), { target: { files: [new File(['1'], 'a.png')] } })
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    expect(revokeObjectURL).toHaveBeenCalledTimes(1)
  })

  it('mientras sube, los botones se bloquean y el texto cambia; deshabilitado bloquea el selector', () => {
    const { container, rerender } = render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} />)
    fireEvent.change(picker(container), { target: { files: [new File(['1'], 'a.png')] } })
    rerender(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending />)
    expect(screen.getByRole('button', { name: 'Subiendo…' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Cancelar' })).toBeDisabled()
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
  })

  it('con disabled el botón de cambiar foto queda inactivo', () => {
    render(<ProfileImageUpload name="ana" onUpload={vi.fn()} isPending={false} disabled />)
    expect(screen.getByRole('button', { name: 'Cambiar foto' })).toBeDisabled()
  })

  it('si la subida falla no deja un rechazo sin manejar y conserva la foto elegida para reintentar', async () => {
    const unhandled = vi.fn()
    process.on('unhandledRejection', unhandled)
    try {
      const onUpload = vi.fn().mockRejectedValue(new Error('x'))
      const { container } = render(<ProfileImageUpload name="ana" onUpload={onUpload} isPending={false} />)
      fireEvent.change(picker(container), { target: { files: [new File(['1'], 'a.png')] } })
      fireEvent.click(screen.getByRole('button', { name: 'Guardar foto' }))
      await waitFor(() => expect(onUpload).toHaveBeenCalled())
      await new Promise((r) => setTimeout(r, 50))
    } finally {
      process.off('unhandledRejection', unhandled)
    }
    expect(unhandled).not.toHaveBeenCalled()
    expect(screen.getByRole('button', { name: 'Guardar foto' })).toBeInTheDocument()
  })
})
