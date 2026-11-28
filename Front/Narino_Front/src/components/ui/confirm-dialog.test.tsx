import { describe, it, expect, vi, afterEach } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'

import { ConfirmDialog, type ConfirmDialogProps } from '@/components/ui/confirm-dialog'

function setup(props: Partial<ConfirmDialogProps> = {}) {
  const onConfirm = vi.fn()
  const onCancel = vi.fn()
  const view = render(
    <ConfirmDialog open title="¿Seguro?" confirmLabel="Sí, borrar" onConfirm={onConfirm} onCancel={onCancel} {...props} />,
  )
  return { onConfirm, onCancel, ...view }
}

describe('ConfirmDialog', () => {
  afterEach(() => vi.restoreAllMocks())

  it('cerrado no pinta nada', () => {
    const { container } = setup({ open: false })
    expect(container).toBeEmptyDOMElement()
  })

  it('abierto muestra título, descripción asociada y botones; el foco inicial va a "Cancelar"', () => {
    setup({ description: <p>Esto no se deshace</p> })
    const dialog = screen.getByRole('alertdialog')
    expect(dialog).toHaveAccessibleName('¿Seguro?')
    expect(dialog).toHaveAccessibleDescription('Esto no se deshace')
    expect(screen.getByRole('button', { name: 'Cancelar' })).toHaveFocus()
  })

  it('sin descripción no la enlaza; con etiqueta de cancelar propia', () => {
    setup({ cancelLabel: 'Mejor no' })
    expect(screen.getByRole('alertdialog')).not.toHaveAttribute('aria-describedby')
    expect(screen.getByRole('button', { name: 'Mejor no' })).toBeInTheDocument()
  })

  it('si hay un campo, el foco inicial va al campo', () => {
    setup({ children: <input aria-label="Contraseña" /> })
    expect(screen.getByLabelText('Contraseña')).toHaveFocus()
  })

  it('confirmar y cancelar llaman a sus manejadores; el tono de peligro pinta la acción', () => {
    const { onConfirm, onCancel } = setup({ tone: 'danger' })
    expect(screen.getByRole('button', { name: 'Sí, borrar' })).toHaveClass('bg-tomate-fill')
    fireEvent.click(screen.getByRole('button', { name: 'Sí, borrar' }))
    expect(onConfirm).toHaveBeenCalledTimes(1)
    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }))
    expect(onCancel).toHaveBeenCalledTimes(1)
  })

  it('no confirma mientras está pendiente o deshabilitado, ni siquiera con Enter', () => {
    const pending = setup({ isPending: true })
    expect(screen.getByRole('button', { name: 'Sí, borrar' })).toBeDisabled()
    fireEvent.submit(screen.getByRole('alertdialog'))
    expect(pending.onConfirm).not.toHaveBeenCalled()
    pending.unmount()

    const disabled = setup({ confirmDisabled: true })
    fireEvent.submit(screen.getByRole('alertdialog'))
    expect(disabled.onConfirm).not.toHaveBeenCalled()
  })

  it('Escape cancela, salvo que esté pendiente', () => {
    const open = setup()
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(open.onCancel).toHaveBeenCalledTimes(1)
    open.unmount()

    const pending = setup({ isPending: true })
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(pending.onCancel).not.toHaveBeenCalled()
  })

  it('Tab recorre y se queda dentro del diálogo, con y sin Mayús', () => {
    setup()
    const cancel = screen.getByRole('button', { name: 'Cancelar' })
    const confirm = screen.getByRole('button', { name: 'Sí, borrar' })

    confirm.focus()
    fireEvent.keyDown(document, { key: 'Tab' })
    expect(cancel).toHaveFocus()

    cancel.focus()
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })
    expect(confirm).toHaveFocus()

    // con el foco fuera del diálogo, Tab lo trae adentro
    const outside = document.createElement('button')
    document.body.appendChild(outside)
    outside.focus()
    fireEvent.keyDown(document, { key: 'Tab' })
    expect(cancel).toHaveFocus()
    outside.focus()
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })
    expect(confirm).toHaveFocus()
    outside.remove()
  })

  it('Tab en medio de los botones no intercepta; otras teclas se ignoran', () => {
    setup({ children: <input aria-label="Campo" /> })
    const field = screen.getByLabelText('Campo')
    const preventDefault = vi.fn()
    field.focus()
    const event = new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true })
    event.preventDefault = preventDefault
    document.dispatchEvent(event)
    expect(preventDefault).not.toHaveBeenCalled()
    fireEvent.keyDown(document, { key: 'a' })
    expect(field).toHaveFocus()
  })

  it('con todo deshabilitado Tab no hace nada', () => {
    setup({ isPending: true })
    const preventDefault = vi.fn()
    const event = new KeyboardEvent('keydown', { key: 'Tab', bubbles: true, cancelable: true })
    event.preventDefault = preventDefault
    document.dispatchEvent(event)
    expect(preventDefault).not.toHaveBeenCalled()
  })

  it('al cerrarse devuelve el foco a quien lo abrió', () => {
    const opener = document.createElement('button')
    document.body.appendChild(opener)
    opener.focus()
    const { rerender } = render(<ConfirmDialog open title="T" confirmLabel="OK" onConfirm={vi.fn()} onCancel={vi.fn()} />)
    expect(opener).not.toHaveFocus()
    rerender(<ConfirmDialog open={false} title="T" confirmLabel="OK" onConfirm={vi.fn()} onCancel={vi.fn()} />)
    expect(opener).toHaveFocus()
    opener.remove()
  })

  it('si no había un elemento enfocable al abrir, al cerrar no falla', () => {
    ;(document.activeElement as HTMLElement | null)?.blur()
    vi.spyOn(document, 'activeElement', 'get').mockReturnValue(null)
    const { rerender } = render(<ConfirmDialog open title="T" confirmLabel="OK" onConfirm={vi.fn()} onCancel={vi.fn()} />)
    expect(() => rerender(<ConfirmDialog open={false} title="T" confirmLabel="OK" onConfirm={vi.fn()} onCancel={vi.fn()} />)).not.toThrow()
  })
})
