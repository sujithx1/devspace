import { AnimatePresence, motion } from 'framer-motion'
import {
  ArrowRight,
  BookOpen,
  CheckSquare,
  CornerDownLeft,
  FileText,
  FolderKanban,
  LayoutDashboard,
  Monitor,
  Moon,
  PanelLeft,
  PenTool,
  Plus,
  Search,
  Settings,
  Sun,
  type LucideIcon,
} from 'lucide-react'
import { useEffect, useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { useNavigate } from 'react-router'
import { useCreateActions } from '@/features/useCreateActions'
import { useSearch } from '@/features/search/useSearch'
import { useRecentEntries } from '@/features/dashboard/useRecentEntries'
import { ENTITY_META } from '@/lib/entities'
import { entityPath, paths } from '@/lib/routes'
import { cn } from '@/lib/utils'
import { useCan } from '@/stores/permissions'
import { useUIStore } from '@/stores/uiStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { Kbd } from '../ui/States'

interface Command {
  id: string
  group: string
  label: string
  hint?: string
  icon: LucideIcon
  keywords?: string
  run: () => void
}

export function CommandPalette() {
  const open = useUIStore((s) => s.commandPaletteOpen)
  const setOpen = useUIStore((s) => s.setCommandPaletteOpen)
  return createPortal(
    <AnimatePresence>{open && <PaletteDialog onClose={() => setOpen(false)} />}</AnimatePresence>,
    document.body,
  )
}

function PaletteDialog({ onClose }: { onClose: () => void }) {
  const navigate = useNavigate()
  const ws = useWorkspaceStore((s) => s.activeId) ?? ''
  const workspaces = useWorkspaceStore((s) => s.workspaces)
  const create = useCreateActions()
  const { setTheme, toggleSidebar } = useUIStore.getState()
  const [query, setQuery] = useState('')
  const [active, setActive] = useState(0)
  const listRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const results = useSearch(query, { limit: 20 })
  const recent = useRecentEntries(5)

  const canEdit = useCan('content.edit')
  const commands = useMemo<Command[]>(() => {
    const go = (to: string) => () => navigate(to)
    const all: Command[] = [
      { id: 'new-note', group: 'Create', label: 'New note', icon: Plus, keywords: 'create add', run: () => void create.newNote() },
      { id: 'new-task', group: 'Create', label: 'New task', icon: Plus, keywords: 'create add todo', run: () => create.newTask() },
      { id: 'new-project', group: 'Create', label: 'New project', icon: Plus, keywords: 'create add', run: () => create.newProject() },
      { id: 'new-doc', group: 'Create', label: 'New document', icon: Plus, keywords: 'create add docs documentation', run: () => void create.newDoc() },
      { id: 'new-drawing', group: 'Create', label: 'New drawing', icon: Plus, keywords: 'create add whiteboard diagram canvas', run: () => void create.newDrawing() },
      { id: 'go-dashboard', group: 'Navigate', label: 'Go to Dashboard', icon: LayoutDashboard, keywords: 'home', run: go(paths.workspace(ws)) },
      { id: 'go-notes', group: 'Navigate', label: 'Go to Notes', icon: FileText, run: go(paths.notes(ws)) },
      { id: 'go-tasks', group: 'Navigate', label: 'Go to Tasks', icon: CheckSquare, keywords: 'kanban board', run: go(paths.tasks(ws)) },
      { id: 'go-projects', group: 'Navigate', label: 'Go to Projects', icon: FolderKanban, run: go(paths.projects(ws)) },
      { id: 'go-docs', group: 'Navigate', label: 'Go to Docs', icon: BookOpen, keywords: 'documentation', run: go(paths.docs(ws)) },
      { id: 'go-drawings', group: 'Navigate', label: 'Go to Drawings', icon: PenTool, keywords: 'whiteboard', run: go(paths.drawings(ws)) },
      { id: 'go-settings', group: 'Navigate', label: 'Workspace settings', icon: Settings, run: go(paths.settings(ws)) },
      ...workspaces
        .filter((w) => w.id !== ws)
        .map<Command>((w) => ({ id: `ws-${w.id}`, group: 'Workspaces', label: `Switch to ${w.name}`, icon: ArrowRight, run: go(paths.workspace(w.id)) })),
      { id: 'theme-light', group: 'Preferences', label: 'Use light theme', icon: Sun, keywords: 'appearance', run: () => setTheme('light') },
      { id: 'theme-dark', group: 'Preferences', label: 'Use dark theme', icon: Moon, keywords: 'appearance', run: () => setTheme('dark') },
      { id: 'theme-system', group: 'Preferences', label: 'Use system theme', icon: Monitor, keywords: 'appearance auto', run: () => setTheme('system') },
      { id: 'sidebar', group: 'Preferences', label: 'Toggle sidebar', icon: PanelLeft, run: toggleSidebar },
    ]
    return canEdit ? all : all.filter((c) => c.group !== 'Create')
  }, [navigate, ws, workspaces, create, setTheme, toggleSidebar, canEdit])

  const items = useMemo<Command[]>(() => {
    const q = query.trim().toLowerCase()
    if (!q) {
      const recents = recent.map<Command>((r) => ({
        id: `recent-${r.type}-${r.id}`,
        group: 'Recent',
        label: r.title,
        hint: ENTITY_META[r.type].label,
        icon: ENTITY_META[r.type].icon,
        run: () => navigate(entityPath(ws, r.type, r.id)),
      }))
      return [...recents, ...commands]
    }
    const matchingCommands = commands.filter((c) => `${c.label} ${c.keywords ?? ''}`.toLowerCase().includes(q))
    const found = results.map<Command>((r) => ({
      id: `result-${r.type}-${r.id}`,
      group: 'Results',
      label: r.title,
      hint: r.meta ? `${ENTITY_META[r.type].label} · ${r.meta}` : ENTITY_META[r.type].label,
      icon: ENTITY_META[r.type].icon,
      run: () => navigate(entityPath(ws, r.type, r.id)),
    }))
    const all: Command = {
      id: 'search-all',
      group: 'Search',
      label: `Search everything for “${query.trim()}”`,
      icon: Search,
      run: () => navigate(paths.search(ws, query.trim())),
    }
    return [...matchingCommands, ...found, all]
  }, [query, results, commands, recent, navigate, ws])

  useEffect(() => setActive(0), [query])
  useEffect(() => {
    listRef.current?.querySelector(`[data-index="${active}"]`)?.scrollIntoView({ block: 'nearest' })
  }, [active])

  const run = (cmd: Command | undefined) => {
    if (!cmd) return
    onClose()
    cmd.run()
  }

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setActive((i) => Math.min(i + 1, items.length - 1))
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setActive((i) => Math.max(i - 1, 0))
    } else if (e.key === 'Enter') {
      e.preventDefault()
      run(items[active])
    } else if (e.key === 'Escape') {
      e.preventDefault()
      onClose()
    }
  }

  let lastGroup = ''
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center p-4 pt-[10vh]">
      <motion.div className="absolute inset-0 bg-black/40 backdrop-blur-[2px]" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose} />
      <motion.div
        role="dialog"
        aria-modal="true"
        aria-label="Command palette"
        initial={{ opacity: 0, scale: 0.98, y: -6 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98 }}
        transition={{ duration: 0.14 }}
        className="relative w-full max-w-xl overflow-hidden rounded-xl border border-line bg-elevated shadow-2xl shadow-black/25"
      >
        <div className="flex items-center gap-3 border-b border-line px-4">
          <Search className="size-4 text-fg-subtle" />
          <input
            ref={inputRef}
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={onKeyDown}
            placeholder="Search or type a command…"
            role="combobox"
            aria-expanded="true"
            aria-controls="palette-list"
            aria-activedescendant={items[active] ? `palette-${items[active].id}` : undefined}
            className="h-12 flex-1 bg-transparent text-[15px] outline-none placeholder:text-fg-subtle"
          />
          <Kbd>esc</Kbd>
        </div>
        <div ref={listRef} id="palette-list" role="listbox" className="max-h-[min(420px,60vh)] overflow-y-auto p-1.5">
          {items.length === 0 && <p className="px-3 py-8 text-center text-sm text-fg-muted">No results</p>}
          {items.map((cmd, index) => {
            const header = cmd.group !== lastGroup ? cmd.group : null
            lastGroup = cmd.group
            const Icon = cmd.icon
            return (
              <div key={cmd.id}>
                {header && <div className="px-2.5 pt-2.5 pb-1 text-[11px] font-medium tracking-wider text-fg-subtle uppercase">{header}</div>}
                <div
                  id={`palette-${cmd.id}`}
                  role="option"
                  aria-selected={index === active}
                  data-index={index}
                  onMouseMove={() => setActive(index)}
                  onClick={() => run(cmd)}
                  className={cn('flex cursor-pointer items-center gap-3 rounded-md px-2.5 py-2 text-sm', index === active ? 'bg-surface-2 text-fg' : 'text-fg-muted')}
                >
                  <Icon className="size-4 shrink-0" />
                  <span className="flex-1 truncate text-fg">{cmd.label}</span>
                  {cmd.hint && <span className="shrink-0 text-xs text-fg-subtle">{cmd.hint}</span>}
                  {index === active && <CornerDownLeft className="size-3.5 shrink-0 text-fg-subtle" />}
                </div>
              </div>
            )
          })}
        </div>
      </motion.div>
    </div>
  )
}
