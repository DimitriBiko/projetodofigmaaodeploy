import { useState, useRef, useEffect } from 'react'
import { contacts, type ChatMessage } from '../lib/media'
import { useAuth } from '../lib/auth'
import {
  CONTACT_USER_IDS,
  fetchMessages,
  getOrCreateDmConversation,
  sendMessage as persistMessage,
} from '../lib/db'

function formatTime(iso: string) {
  const d = new Date(iso)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

export default function Chat({
  contactId,
  onBack,
}: {
  contactId: string
  onBack: () => void
}) {
  const { user } = useAuth()
  const contact = contacts.find((c) => c.id === contactId)
  const otherUserId = CONTACT_USER_IDS[contactId]

  const [conversationId, setConversationId] = useState<string | null>(null)
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [draft, setDraft] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  useEffect(() => {
    let cancelled = false
    async function load() {
      if (!user || !otherUserId) {
        setLoading(false)
        setError('Contato sem usuário no banco.')
        return
      }
      setLoading(true)
      setError(null)
      try {
        const convId = await getOrCreateDmConversation(user.id, otherUserId)
        if (cancelled) return
        setConversationId(convId)
        const rows = await fetchMessages(convId)
        if (cancelled) return
        setMessages(
          rows.map((m) => ({
            id: m.id,
            text: m.body,
            time: formatTime(m.sent_at),
            fromMe: m.sender_id === user.id,
          })),
        )
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Falha ao carregar conversa.')
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
  }, [user, otherUserId])

  const handleSend = async () => {
    const text = draft.trim()
    if (!text || !user || !conversationId || busy) return
    setBusy(true)
    setError(null)
    try {
      const saved = await persistMessage({
        conversationId,
        senderId: user.id,
        body: text,
      })
      setMessages((prev) => [
        ...prev,
        {
          id: saved.id,
          text: saved.body,
          time: formatTime(saved.sent_at),
          fromMe: true,
        },
      ])
      setDraft('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Não foi possível enviar.')
    } finally {
      setBusy(false)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      void handleSend()
    }
  }

  if (!contact) return null

  return (
    <div className="flex min-h-dvh flex-col bg-canvas">
      <header className="sticky top-0 z-20 flex items-center justify-between px-4 py-3 backdrop-blur-[40px] bg-white/95 border-b border-neutral-200">
        <button
          onClick={onBack}
          aria-label="Voltar"
          className="grid h-11 w-11 place-items-center rounded-xl text-ink transition-colors hover:bg-neutral-100"
        >
          <img src="/assets/132f9.svg" alt="" className="w-[22px] h-[22px]" />
        </button>

        <div className="flex items-center gap-3">
          <div className="text-right">
            <p className="text-[15px] font-semibold text-ink">{contact.name}</p>
            <p className={`text-[12px] ${contact.online ? 'text-green-500' : 'text-neutral-400'}`}>
              {contact.online ? 'online agora' : 'offline'}
            </p>
          </div>
          <div className="relative h-10 w-10 overflow-hidden rounded-full">
            <img src={contact.avatar} alt="" className="h-full w-full object-cover" />
          </div>
        </div>
      </header>

      <main className="mx-auto flex w-full max-w-[640px] flex-1 flex-col gap-3 overflow-y-auto px-4 py-6">
        {loading && (
          <p className="text-center text-[13px] text-neutral-400">Carregando conversa…</p>
        )}
        {!loading && messages.length === 0 && !error && (
          <p className="text-center text-[13px] text-neutral-400">
            Nenhuma mensagem ainda. Envie a primeira.
          </p>
        )}
        {messages.map((msg) => (
          <div key={msg.id} className={`flex flex-col ${msg.fromMe ? 'items-end' : 'items-start'}`}>
            <div
              className={`max-w-[72%] px-4 py-2.5 text-[15px] leading-snug text-ink ${msg.fromMe ? '[border-radius:18px_18px_4px_18px]' : 'bg-surface [border-radius:18px_18px_18px_4px]'}`}
              style={msg.fromMe ? { background: '#d4f535' } : undefined}
            >
              {msg.text}
            </div>
            <span className="mt-1 text-[11px] text-neutral-400">{msg.time}</span>
          </div>
        ))}
        {error && <p className="text-center text-[13px] text-red-600">{error}</p>}
        <div ref={bottomRef} />
      </main>

      <div className="sticky bottom-0 flex items-center gap-3 px-4 py-3 bg-canvas/95 backdrop-blur-md border-t border-neutral-200">
        <div className="flex flex-1 items-center rounded-full px-4 py-2.5 bg-neutral-100 border border-neutral-200">
          <input
            type="text"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Escreva uma mensagem..."
            disabled={!conversationId || busy}
            className="flex-1 bg-transparent text-[15px] text-ink outline-none placeholder:text-neutral-400"
          />
        </div>
        <button
          type="button"
          onClick={() => void handleSend()}
          disabled={!conversationId || busy || !draft.trim()}
          aria-label="Enviar"
          className="grid h-12 w-12 shrink-0 place-items-center rounded-full transition-opacity hover:opacity-80 active:scale-95 disabled:opacity-40"
          style={{ background: '#d4f535' }}
        >
          <svg viewBox="0 0 24 24" width={20} height={20} fill="none" className="text-ink">
            <path d="M22 2 11 13" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
            <path d="m22 2-7 20-4-9-9-4 20-7Z" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>
    </div>
  )
}
