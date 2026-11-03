import { Search } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { Link, useSearchParams } from 'react-router'
import { PageHeader } from '@/components/layout/PageHeader'
import { EmptyState } from '@/components/ui/States'
import { ENTITY_TYPES, type EntityType } from '@/data'
import { ENTITY_META } from '@/lib/entities'
import { entityPath } from '@/lib/routes'
import { cn, formatRelative, pluralize } from '@/lib/utils'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { useSearch } from './useSearch'

function Highlight({ text, query }: { text: string; query: string }) {
  const terms = query.split(/\s+/).filter(Boolean).map((t) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
  if (!terms.length) return <>{text}</>
  const parts = text.split(new RegExp(`(${terms.join('|')})`, 'gi'))
  return (
    <>
      {parts.map((part, i) =>
        i % 2 === 1 ? (
          <mark key={i} className="rounded-sm bg-accent-soft px-0.5 text-accent">
            {part}
          </mark>
        ) : (
          part
        ),
      )}
    </>
  )
}

export function SearchPage() {
  const ws = useWorkspaceId()
  const [params, setParams] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') ?? '')
  const [types, setTypes] = useState<EntityType[]>([])
  const results = useSearch(query, { types })
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  useEffect(() => {
    const t = setTimeout(() => setParams(query ? { q: query } : {}, { replace: true }), 250)
    return () => clearTimeout(t)
  }, [query, setParams])

  const toggleType = (type: EntityType) => setTypes((ts) => (ts.includes(type) ? ts.filter((t) => t !== type) : [...ts, type]))

  return (
    <>
      <PageHeader title="Search" icon={<Search className="size-4" />} />
      <div className="min-h-0 flex-1 overflow-y-auto">
        <div className="mx-auto max-w-3xl p-4 md:p-8">
          <label className="relative block">
            <span className="sr-only">Search everything</span>
            <Search className="pointer-events-none absolute top-1/2 left-4 size-4.5 -translate-y-1/2 text-fg-subtle" />
            <input
              ref={inputRef}
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search notes, tasks, projects, docs and drawings…"
              className="h-12 w-full rounded-xl border border-line bg-surface pr-4 pl-11 text-[15px] shadow-xs outline-none placeholder:text-fg-subtle focus:border-accent focus:ring-4 focus:ring-accent/10"
            />
          </label>
          <div className="mt-3 flex flex-wrap gap-1.5" role="group" aria-label="Filter by type">
            {ENTITY_TYPES.map((type) => {
              const { plural, icon: Icon } = ENTITY_META[type]
              const active = types.includes(type)
              return (
                <button
                  key={type}
                  type="button"
                  aria-pressed={active}
                  onClick={() => toggleType(type)}
                  className={cn(
                    'flex h-7 items-center gap-1.5 rounded-full border px-3 text-xs font-medium transition-colors',
                    active ? 'border-accent bg-accent-soft text-accent' : 'border-line text-fg-muted hover:border-line-strong hover:text-fg',
                  )}
                >
                  <Icon className="size-3" /> {plural}
                </button>
              )
            })}
          </div>

          <div className="mt-6">
            {!query.trim() ? (
              <EmptyState icon={Search} title="Search your workspace" description="Find anything by title or content. All terms must match." />
            ) : results.length === 0 ? (
              <EmptyState icon={Search} title="No results" description={`Nothing matches “${query.trim()}”${types.length ? ' in the selected types' : ''}.`} />
            ) : (
              <>
                <p className="mb-3 text-xs text-fg-subtle" aria-live="polite">
                  {pluralize(results.length, 'result')}
                </p>
                <ul className="flex flex-col gap-2">
                  {results.map((r) => {
                    const Icon = ENTITY_META[r.type].icon
                    return (
                      <li key={`${r.type}:${r.id}`}>
                        <Link to={entityPath(ws, r.type, r.id)} className="flex gap-3 rounded-xl border border-line bg-surface p-4 transition-colors hover:border-line-strong">
                          <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-surface-2">
                            <Icon className="size-4 text-fg-muted" />
                          </span>
                          <span className="min-w-0 flex-1">
                            <span className="flex items-center gap-2">
                              <span className="truncate text-sm font-medium">
                                <Highlight text={r.title} query={query} />
                              </span>
                              <span className="shrink-0 text-[11px] text-fg-subtle">
                                {ENTITY_META[r.type].label}
                                {r.meta ? ` · ${r.meta}` : ''}
                              </span>
                            </span>
                            {r.snippet && (
                              <span className="mt-1 line-clamp-2 block text-xs leading-5 text-fg-muted">
                                <Highlight text={r.snippet} query={query} />
                              </span>
                            )}
                          </span>
                          <span className="hidden shrink-0 text-xs text-fg-subtle sm:block">{formatRelative(r.updatedAt)}</span>
                        </Link>
                      </li>
                    )
                  })}
                </ul>
              </>
            )}
          </div>
        </div>
      </div>
    </>
  )
}
