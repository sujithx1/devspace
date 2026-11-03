import { Hash, X } from 'lucide-react'
import { useState, type KeyboardEvent } from 'react'
import { cn } from '@/lib/utils'

const MAX_TAGS = 20

export function normalizeTag(value: string) {
  return value.trim().replace(/^#/, '').replace(/\s+/g, '-').toLowerCase().slice(0, 32)
}

export function TagInput({ tags, onChange, readOnly, className }: { tags: string[]; onChange: (tags: string[]) => void; readOnly?: boolean; className?: string }) {
  const [draft, setDraft] = useState('')

  const add = (raw: string) => {
    const tag = normalizeTag(raw)
    setDraft('')
    if (!tag || tags.includes(tag) || tags.length >= MAX_TAGS) return
    onChange([...tags, tag])
  }

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault()
      add(draft)
    } else if (e.key === 'Backspace' && !draft && tags.length) {
      onChange(tags.slice(0, -1))
    }
  }

  return (
    <div className={cn('flex flex-wrap items-center gap-1.5', className)}>
      {tags.map((tag) => (
        <span key={tag} className="inline-flex h-6 items-center gap-1 rounded-md bg-surface-2 pr-1 pl-2 text-xs text-fg-muted">
          #{tag}
          {!readOnly && (
            <button type="button" aria-label={`Remove tag ${tag}`} onClick={() => onChange(tags.filter((t) => t !== tag))} className="rounded p-0.5 hover:bg-line hover:text-fg">
              <X className="size-3" />
            </button>
          )}
        </span>
      ))}
      {!readOnly && tags.length < MAX_TAGS && (
        <label className="inline-flex h-6 items-center gap-1 text-xs text-fg-subtle">
          <Hash className="size-3" />
          <span className="sr-only">Add tag</span>
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={onKeyDown}
            onBlur={() => draft && add(draft)}
            placeholder={tags.length ? 'Add tag' : 'Add tags'}
            className="w-20 bg-transparent text-fg outline-none placeholder:text-fg-subtle"
          />
        </label>
      )}
    </div>
  )
}
