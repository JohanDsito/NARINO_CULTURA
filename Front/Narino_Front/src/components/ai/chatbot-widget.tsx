import { useMemo, useState } from 'react'
import { MessageCircle, X, Send } from 'lucide-react'

import { cn } from '@/utils'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

type ChatMessage = { id: string; role: 'user' | 'bot'; text: string }

const QUICK_SUGGESTIONS = [
  'Recomiéndame artistas de Pasto',
  '¿Qué eventos hay este fin de semana?',
  'Quiero artesanías tradicionales',
  'Explorar subastas activas',
] as const

export function ChatbotWidget() {
  const [open, setOpen] = useState(false)
  const [text, setText] = useState('')
  const [messages, setMessages] = useState<ChatMessage[]>(() => [
    {
      id: crypto.randomUUID(),
      role: 'bot',
      text: 'Hola, soy el asistente de Nariño Cultura. ¿Qué te gustaría descubrir hoy?',
    },
  ])

  const canSend = text.trim().length > 0

  const suggestions = useMemo(() => QUICK_SUGGESTIONS.slice(0, 4), [])

  const send = (content: string) => {
    const value = content.trim()
    if (!value) return
    setMessages((prev) => [
      ...prev,
      { id: crypto.randomUUID(), role: 'user', text: value },
      {
        id: crypto.randomUUID(),
        role: 'bot',
        text: 'Aún estoy aprendiendo. En pasos posteriores me conectaré al servicio IA para recomendaciones y respuestas.',
      },
    ])
    setText('')
  }

  return (
    <div className="fixed bottom-16 right-5 z-50 md:bottom-20 md:right-8">
      {open ? (
        <div
          className="w-[92vw] max-w-sm overflow-hidden rounded-xl border border-border bg-slate-950 text-white shadow-lg"
          role="dialog"
          aria-label="Chat de ayuda"
        >
          <div className="flex items-center justify-between border-b border-border bg-slate-900 px-4 py-3">
            <div className="space-y-0.5">
              <p className="font-medium text-white">Asistente</p>
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
                    ? 'ml-auto bg-tierra text-white'
                    : 'bg-slate-800 text-white',
                )}
              >
                {m.text}
              </div>
            ))}

            <div className="flex flex-wrap gap-2 pt-2">
              {suggestions.map((s) => (
                <button
                  key={s}
                  type="button"
                  className="rounded-full border border-border bg-slate-800 px-3 py-1 text-xs text-white hover:bg-slate-700"
                  onClick={() => send(s)}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>

          <form
            className="flex items-center gap-2 border-t border-border bg-slate-950 p-3"
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
              className="bg-slate-800 text-white placeholder:text-slate-400"
            />
            <Button type="submit" disabled={!canSend} aria-label="Enviar mensaje">
              <Send className="h-4 w-4" />
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
