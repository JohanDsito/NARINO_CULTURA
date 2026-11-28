import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'

import { sendChatMessage } from '@/api/chat.api'
import { ChatbotWidget } from '@/components/ai/chatbot-widget'

vi.mock('@/api/chat.api', () => ({ sendChatMessage: vi.fn() }))
const mockedSend = vi.mocked(sendChatMessage)

function openChat() {
  render(<ChatbotWidget />)
  fireEvent.click(screen.getByRole('button', { name: 'Abrir chat' }))
}

describe('ChatbotWidget', () => {
  beforeEach(() => vi.clearAllMocks())

  it('arranca cerrado y se abre y cierra con su botón', () => {
    openChat()
    expect(screen.getByRole('dialog', { name: 'Chat de ayuda' })).toBeInTheDocument()
    expect(screen.getByText(/Hola, soy el asistente/)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Cerrar chat' }))
    expect(screen.getByRole('button', { name: 'Abrir chat' })).toBeInTheDocument()
  })

  it('el botón de enviar está deshabilitado con el texto vacío', () => {
    openChat()
    expect(screen.getByRole('button', { name: 'Enviar mensaje' })).toBeDisabled()
    fireEvent.change(screen.getByLabelText('Mensaje'), { target: { value: '   ' } })
    expect(screen.getByRole('button', { name: 'Enviar mensaje' })).toBeDisabled()
  })

  it('envía el mensaje, muestra "Pensando…" y luego la respuesta con el historial previo', async () => {
    let resolve!: (v: { reply: string }) => void
    mockedSend.mockReturnValueOnce(new Promise((r) => { resolve = r }))
    openChat()
    fireEvent.change(screen.getByLabelText('Mensaje'), { target: { value: ' Hola ' } })
    fireEvent.submit(screen.getByLabelText('Mensaje').closest('form')!)
    expect(await screen.findByText('Pensando…')).toBeInTheDocument()
    expect(screen.getByLabelText('Mensaje')).toBeDisabled()
    // mientras envía, otro envío se ignora
    fireEvent.submit(screen.getByLabelText('Mensaje').closest('form')!)
    resolve({ reply: 'Bienvenida' })
    expect(await screen.findByText('Bienvenida')).toBeInTheDocument()
    expect(mockedSend).toHaveBeenCalledTimes(1)
    expect(mockedSend).toHaveBeenCalledWith('Hola', [])

    mockedSend.mockResolvedValueOnce({ reply: 'Segunda' })
    fireEvent.change(screen.getByLabelText('Mensaje'), { target: { value: 'otra' } })
    fireEvent.click(screen.getByRole('button', { name: 'Enviar mensaje' }))
    await screen.findByText('Segunda')
    expect(mockedSend).toHaveBeenLastCalledWith('otra', [
      { role: 'user', text: 'Hola' },
      { role: 'model', text: 'Bienvenida' },
    ])
  })

  it('las sugerencias rápidas envían su texto y desaparecen tras la primera respuesta', async () => {
    mockedSend.mockResolvedValue({ reply: 'Claro' })
    openChat()
    fireEvent.click(screen.getByRole('button', { name: 'Explorar subastas activas' }))
    await screen.findByText('Claro')
    expect(mockedSend).toHaveBeenCalledWith('Explorar subastas activas', [])
    expect(screen.queryByRole('button', { name: 'Explorar subastas activas' })).not.toBeInTheDocument()
  })

  it('si el servicio falla responde con un mensaje de disculpa', async () => {
    mockedSend.mockRejectedValue(new Error('x'))
    openChat()
    fireEvent.change(screen.getByLabelText('Mensaje'), { target: { value: 'hola' } })
    fireEvent.click(screen.getByRole('button', { name: 'Enviar mensaje' }))
    await waitFor(() => expect(screen.getByText(/no pude responder en este momento/)).toBeInTheDocument())
    expect(screen.getByLabelText('Mensaje')).toBeEnabled()
  })

  it('un envío con texto vacío no llama al servicio', () => {
    openChat()
    fireEvent.submit(screen.getByLabelText('Mensaje').closest('form')!)
    expect(mockedSend).not.toHaveBeenCalled()
  })
})
