import { useMemo, useState } from 'react'
import { MessageCircle, X, Send, Loader2 } from 'lucide-react'

import { cn } from '@/utils'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { sendChatMessage, type ChatHistoryItem } from '@/api/chat.api'

type ChatMessage = { id: string; role: 'user' | 'bot'; text: string }

const QUICK_SUGGESTIONS = [
  'Recomiéndame artistas de Pasto',
  '¿Qué eventos hay este fin de semana?',
  'Quiero artesanías tradicionales',
  'Explorar subastas activas',
] as const

const INITIAL_MESSAGE: ChatMessage = {
  id: 'init',
  role: 'bot',
  text: 'Hola, soy el asistente de Nariño Cultura. ¿Qué te gustaría descubrir hoy?',
}

export function ChatbotWidget() {
  const [open, setOpen] = useState(false)
  const [text, setText] = useState('')
  const [isSending, setIsSending] = useState(false)
  const [messages, setMessages] = useState<ChatMessage[]>([INITIAL_MESSAGE])

  const canSend = text.trim().length > 0 && !isSending
  const suggestions = useMemo(() => QUICK_SUGGESTIONS.slice(0, 4), [])

  const send = async (content: string) => {
    const value = content.trim()
    if (!value || isSending) return

    const userMsg: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      text: value,
    }
    setMessages((prev) => [...prev, userMsg])
    setText('')
    setIsSending(true)

    const history: ChatHistoryItem[] = messages
      .filter((m) => m.id !== 'init')
      .map((m) => ({ role: m.role === 'bot' ? 'model' : 'user', text: m.text }))

    try {
      const res = await sendChatMessage(value, history)
      setMessages((prev) => [
        ...prev,
        { id: crypto.randomUUID(), role: 'bot', text: res.reply },
      ])
    } catch {
      setMessages((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          role: 'bot',
          text: 'Lo siento, no pude responder en este momento. Intenta de nuevo.',
        },
      ])
    } finally {
      setIsSending(false)
    }
  }

  return (
    <div className="fixed bottom-16 right-5 z-50 md:bottom-20 md:right-8">
      {open ? (
        <div
          className="flex w-[92vw] max-w-sm flex-col overflow-hidden rounded-xl border border-border bg-card text-card-foreground shadow-xl"
          role="dialog"
          aria-label="Chat de ayuda"
        >
          <div className="flex items-center justify-between border-b border-border bg-muted px-4 py-3">
            <div className="space-y-0.5">
              <p className="font-medium text-foreground">Asistente</p>
              <p className="text-xs text-muted-foreground">Nariño Cultura</p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setOpen(false)}
              aria-label="Cerrar chat"
            >
              <X className="h-5 w-5" />
            </Button>
          </div>

          <div className="max-h-[360px] space-y-3 overflow-auto p-4">
            {messages.map((m) => (
              <div
                key={m.id}
                className={cn(
                  'max-w-[90%] rounded-lg px-3 py-2 text-sm',
                  m.role === 'user'
                    ? 'ml-auto bg-primary text-primary-foreground'
                    : 'bg-muted text-foreground',
                )}
              >
                {m.text}
              </div>
            ))}

            {isSending && (
              <div className="flex items-center gap-2 rounded-lg bg-muted px-3 py-2 text-sm text-muted-foreground">
                <Loader2 className="h-4 w-4 animate-spin" />
                Pensando…
              </div>
            )}

            {messages.length <= 1 && !isSending && (
              <div className="flex flex-wrap gap-2 pt-2">
                {suggestions.map((s) => (
                  <button
                    key={s}
                    type="button"
                    className="rounded-full border border-border bg-background px-3 py-1 text-xs text-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
                    onClick={() => send(s)}
                  >
                    {s}
                  </button>
                ))}
              </div>
            )}
          </div>

          <form
            className="flex items-center gap-2 border-t border-border bg-background p-3"
            onSubmit={(e) => {
              e.preventDefault()
              send(text)
            }}
          >
            <Input
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder="Escribe tu pregunta…"
              aria-label="Mensaje"
              disabled={isSending}
            />
            <Button type="submit" disabled={!canSend} aria-label="Enviar mensaje">
              {isSending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
            </Button>
          </form>
        </div>
      ) : (
        <Button
          onClick={() => setOpen(true)}
          className="h-14 w-14 rounded-full shadow-lg"
          size="icon"
          aria-label="Abrir chat"
        >
          <MessageCircle className="h-6 w-6" />
        </Button>
      )}
    </div>
  )
}
