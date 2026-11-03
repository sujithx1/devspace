import { Folder as FolderIcon, FolderPlus, MoreHorizontal, PenTool, Plus, Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/Button'
import { EmptyState, ErrorState, Skeleton } from '@/components/ui/States'
import { createFolder, deleteFolder, renameFolder } from '@/features/folders/folderActions'
import { useCreateActions } from '@/features/useCreateActions'
import { cn } from '@/lib/utils'
import { useDrawingsStore, useFoldersStore, useProjectsStore } from '@/stores/collections'
import { openDropdownMenu } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { DrawingCard, useDrawingMenu } from './DrawingCard'

const ALL = '__all__'
const UNFILED = '__unfiled__'

export function DrawingsPage() {
  const ws = useWorkspaceId()
  const { items, status, error, load } = useDrawingsStore()
  const allFolders = useFoldersStore((s) => s.items)
  const projects = useProjectsStore((s) => s.items)
  const create = useCreateActions()
  const menu = useDrawingMenu()
  const canEdit = useCan('content.edit')
  const [folderFilter, setFolderFilter] = useState(ALL)
  const [projectFilter, setProjectFilter] = useState('')
  const [query, setQuery] = useState('')

  const folders = useMemo(() => allFolders.filter((f) => f.kind === 'drawing').sort((a, b) => a.name.localeCompare(b.name)), [allFolders])
  const activeFolder = folders.find((f) => f.id === folderFilter)

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase()
    return items
      .filter((d) => folderFilter === ALL || (folderFilter === UNFILED ? !d.folderId : d.folderId === folderFilter))
      .filter((d) => !projectFilter || d.projectId === projectFilter)
      .filter((d) => !q || (d.title || 'untitled').toLowerCase().includes(q))
      .sort((a, b) => b.updatedAt - a.updatedAt)
  }, [items, folderFilter, projectFilter, query])

  const newDrawing = () =>
    void create.newDrawing({
      folderId: activeFolder?.id ?? null,
      projectId: projectFilter || null,
    })

  const chip = (id: string, label: string, count: number) => (
    <button
      key={id}
      type="button"
      role="tab"
      aria-selected={folderFilter === id}
      onClick={() => setFolderFilter(id)}
      className={cn('flex h-7 items-center gap-1.5 rounded-md px-2.5 text-xs font-medium whitespace-nowrap transition-colors', folderFilter === id ? 'bg-fg text-canvas' : 'text-fg-muted hover:bg-surface-2 hover:text-fg')}
    >
      {id !== ALL && id !== UNFILED && <FolderIcon className="size-3" />}
      {label}
      <span className="opacity-60">{count}</span>
    </button>
  )

  return (
    <>
      <PageHeader
        title="Drawings"
        icon={<PenTool className="size-4" />}
        actions={
          canEdit && (
            <>
              <Button size="sm" variant="ghost" onClick={() => void createFolder(ws, 'drawing')}>
                <FolderPlus className="size-3.5" /> <span className="hidden sm:inline">New folder</span>
              </Button>
              <Button size="sm" variant="primary" onClick={newDrawing}>
                <Plus className="size-3.5" /> New drawing
              </Button>
            </>
          )
        }
      />
      <div className="min-h-0 flex-1 overflow-y-auto p-4 md:p-6">
        {status === 'error' ? (
          <ErrorState message={error ?? 'Could not load drawings'} onRetry={() => void load(ws)} />
        ) : status !== 'ready' ? (
          <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4">
            {[0, 1, 2, 3].map((i) => (
              <Skeleton key={i} className="aspect-[4/3]" />
            ))}
          </div>
        ) : items.length === 0 && folders.length === 0 ? (
          <EmptyState
            icon={PenTool}
            title="No drawings yet"
            description="Sketch system architecture, flows and wireframes on an infinite canvas with shapes, arrows, freehand and text."
            action={
              canEdit && (
                <Button variant="primary" onClick={newDrawing}>
                  <Plus className="size-4" /> New drawing
                </Button>
              )
            }
          />
        ) : (
          <div className="mx-auto max-w-6xl">
            <div className="mb-5 flex flex-wrap items-center gap-2">
              <div role="tablist" aria-label="Folders" className="flex max-w-full items-center gap-1 overflow-x-auto">
                {chip(ALL, 'All', items.length)}
                {chip(UNFILED, 'Unfiled', items.filter((d) => !d.folderId).length)}
                {folders.map((f) => chip(f.id, f.name, items.filter((d) => d.folderId === f.id).length))}
              </div>
              {activeFolder && canEdit && (
                <Button
                  size="icon-sm"
                  variant="ghost"
                  aria-label="Folder actions"
                  aria-haspopup="menu"
                  onClick={(e) =>
                    openDropdownMenu(e, [
                      { label: 'Rename folder', onSelect: () => void renameFolder(activeFolder) },
                      {
                        label: 'Delete folder',
                        danger: true,
                        onSelect: async () => {
                          if (await deleteFolder(activeFolder)) setFolderFilter(ALL)
                        },
                      },
                    ])
                  }
                >
                  <MoreHorizontal className="size-4" />
                </Button>
              )}
              <div className="flex-1" />
              {projects.length > 0 && (
                <select
                  aria-label="Filter by project"
                  value={projectFilter}
                  onChange={(e) => setProjectFilter(e.target.value)}
                  className="h-8 cursor-pointer rounded-md border border-line bg-surface px-2 text-xs text-fg-muted outline-none focus:border-accent"
                >
                  <option value="">Any project</option>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name}
                    </option>
                  ))}
                </select>
              )}
              <label className="relative">
                <span className="sr-only">Search drawings</span>
                <Search className="pointer-events-none absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-fg-subtle" />
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search drawings…"
                  className="h-8 w-48 rounded-md border border-line bg-surface pr-2 pl-8 text-sm outline-none placeholder:text-fg-subtle focus:border-accent"
                />
              </label>
            </div>
            {visible.length === 0 ? (
              <EmptyState icon={PenTool} title="Nothing here" description="No drawings match this view." className="py-12" />
            ) : (
              <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4">
                {visible.map((d) => (
                  <DrawingCard key={d.id} drawing={d} menu={menu(d, folders)} />
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </>
  )
}
