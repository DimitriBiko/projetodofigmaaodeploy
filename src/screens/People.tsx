import { useState } from 'react'
import { ChevronLeft } from 'lucide-react'
import { contacts } from '../lib/media'

export default function People({
  onBack,
  onOpenProfile,
}: {
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
        <span className="flex-1 text-[17px] font-semibold text-ink">Pessoas para seguir</span>
      </header>

      <div className="mx-auto w-full max-w-[700px] px-4 pt-5 pb-10">
        <p className="mb-4 text-[14px] text-neutral-500">
          Recomendações com base nos seus interesses e grupos.
        </p>
        <ul className="space-y-1">
          {contacts.map((c) => (
            <li
              key={c.id}
              className="flex items-center gap-3 rounded-[14px] bg-surface px-3 py-3"
            >
              <button
                type="button"
                onClick={() => onOpenProfile?.(c.id)}
                className="relative shrink-0"
                aria-label={`Abrir perfil de ${c.name}`}
              >
                <div className="h-12 w-12 overflow-hidden rounded-full">
                  <img src={c.avatar} alt="" className="h-full w-full object-cover" />
                </div>
                {c.online && (
                  <span className="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full border-2 border-white bg-green-500" />
                )}
              </button>
              <button
                type="button"
                onClick={() => onOpenProfile?.(c.id)}
                className="min-w-0 flex-1 text-left"
              >
                <p className="truncate text-[15px] font-semibold text-ink hover:underline">{c.name}</p>
                <p className="truncate text-[13px] text-neutral-400">
                  {c.handle}
                  {c.interests ? ` · ${c.interests} interesses em comum` : ''}
                </p>
              </button>
              <button
                type="button"
                onClick={() => toggleFollow(c.id)}
                className={`shrink-0 rounded-full px-4 py-2 text-[13px] font-semibold transition-colors ${
                  followed.has(c.id)
                    ? 'bg-neutral-100 text-neutral-700'
                    : 'bg-secondary-500 text-white hover:bg-secondary-600'
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
