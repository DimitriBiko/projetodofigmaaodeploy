import { useState } from 'react'
import { ChevronLeft } from 'lucide-react'
import { contacts } from '../lib/media'

/** Lista de membros do grupo — usa contacts como base visual do mock. */
export default function Members({
  groupName,
  onBack,
  onOpenProfile,
}: {
  groupName?: string
  onBack: () => void
  onOpenProfile?: (id: string) => void
}) {
  const [followed, setFollowed] = useState<Set<string>>(new Set())

  const toggleFollow = (id: string) =>
    setFollowed((prev) => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })

  return (
    <div className="fixed inset-0 z-60 flex flex-col bg-canvas overflow-y-auto">
      <header className="sticky top-0 z-10 flex items-center gap-3 bg-surface px-4 py-3 border-b border-neutral-200">
        <button
          type="button"
          onClick={onBack}
          aria-label="Voltar"
          className="grid h-9 w-9 place-items-center rounded-full text-ink transition-colors hover:bg-neutral-100"
        >
          <ChevronLeft size={22} />
        </button>
        <div className="min-w-0 flex-1">
          <p className="truncate text-[17px] font-semibold text-ink">Membros</p>
          {groupName && <p className="truncate text-[12px] text-neutral-500">{groupName}</p>}
        </div>
      </header>

      <div className="mx-auto w-full max-w-[700px] px-4 pt-5 pb-10">
        <p className="mb-4 text-[13px] text-neutral-500">{contacts.length} membros</p>
        <ul className="space-y-1">
          {contacts.map((c) => (
            <li key={c.id} className="flex items-center gap-3 rounded-[14px] bg-surface px-3 py-3">
              <button
                type="button"
                onClick={() => onOpenProfile?.(c.id)}
                className="shrink-0"
                aria-label={`Abrir perfil de ${c.name}`}
              >
                <div className="h-11 w-11 overflow-hidden rounded-full">
                  <img src={c.avatar} alt="" className="h-full w-full object-cover" />
                </div>
              </button>
              <button
                type="button"
                onClick={() => onOpenProfile?.(c.id)}
                className="min-w-0 flex-1 text-left"
              >
                <p className="truncate text-[15px] font-semibold text-ink hover:underline">{c.name}</p>
                <p className="truncate text-[13px] text-neutral-400">{c.handle}</p>
              </button>
              <button
                type="button"
                onClick={() => toggleFollow(c.id)}
                className={`shrink-0 rounded-full px-3.5 py-1.5 text-[12px] font-semibold transition-colors ${
                  followed.has(c.id)
                    ? 'bg-neutral-100 text-neutral-700'
                    : 'bg-secondary-500 text-white'
                }`}
              >
                {followed.has(c.id) ? 'Seguindo' : 'Seguir'}
              </button>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
