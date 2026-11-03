import {
  ArrowDownUp,
  ChevronRight,
  Copy,
  ExternalLink,
  Filter,
  Folder as FolderIcon,
  FolderInput,
  FolderPlus,
  Menu,
  MoreHorizontal,
  Pencil,
  Pin,
  PinOff,
  Plus,
  Search,
  Trash2,
  X,
} from 'lucide-react'
import { useMemo, useState, type DragEvent } from 'react'
import { NavLink, useNavigate } from 'react-router'
import { Button } from '@/components/ui/Button'
import { EmptyState, ErrorState, ListSkeleton } from '@/components/ui/States'
import type { Folder, Page } from '@/data'
import { createFolder, deleteFolder, renameFolder } from '@/features/folders/folderActions'
import { untitled } from '@/lib/entities'
import { cn, formatRelative } from '@/lib/utils'
import { useFoldersStore, useProjectsStore } from '@/stores/collections'
import { openContextMenu, openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useUIStore } from '@/stores/uiStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { DEFAULT_PAGE_FILTERS, collectTags, filterPages, isFiltering, type PageFilters } from './filterPages'
import { createPage, deletePage, duplicatePage, updatePage } from './pageActions'
import { PAGE_KINDS, type PageKind } from './pageKinds'

const DRAG_TYPE = 'application/x-devspace-page'

export function PageList({ kind, activeId }: { kind: PageKind; activeId?: string }) {
  const config = PAGE_KINDS[kind]
  const ws = useWorkspaceId()
  const navigate = useNavigate()
  const { items, status, error, load } = config.useStore()
  const canEdit = useCan('content.edit')
  const allFolders = useFoldersStore((s) => s.items)
  const projects = useProjectsStore((s) => s.items)
  const openMobileNav = useUIStore((s) => s.setMobileSidebarOpen)
  const [filters, setFilters] = useState<PageFilters>(DEFAULT_PAGE_FILTERS)
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})
  const [dropTarget, setDropTarget] = useState<string | null>(null)

  const folders = useMemo(
    () => allFolders.filter((f) => f.kind === config.folderKind).sort((a, b) => a.name.localeCompare(b.name)),
    [allFolders, config.folderKind],
  )
  const visible = useMemo(() => filterPages(items, filters), [items, filters])
  const tags = useMemo(() => collectTags(items), [items])
  const filtering = isFiltering(filters)

  const newPage = async (folderId: string | null = null) => {
    const page = await createPage(kind, ws, { folderId })
    if (page) navigate(config.itemPath(ws, page.id))
  }

  const pageMenu = (page: Page): MenuItem[] => [
    { label: 'Open', icon: ExternalLink, onSelect: () => navigate(config.itemPath(ws, page.id)) },
    { label: page.pinned ? 'Unpin' : 'Pin to sidebar', icon: page.pinned ? PinOff : Pin, onSelect: () => void updatePage(kind, page.id, { pinned: !page.pinned }) },
    {
      label: 'Duplicate',
      icon: Copy,
      onSelect: async () => {
        const copy = await duplicatePage(kind, page)
        if (copy) navigate(config.itemPath(ws, copy.id))
      },
    },
    ...(folders.length || page.folderId
      ? ([
          { type: 'label', label: 'Move to' },
          ...(page.folderId ? [{ label: 'No folder', icon: FolderInput, onSelect: () => void updatePage(kind, page.id, { folderId: null }) }] : []),
          ...folders
            .filter((f) => f.id !== page.folderId)
            .map<MenuItem>((f) => ({ label: f.name, icon: FolderIcon, onSelect: () => void updatePage(kind, page.id, { folderId: f.id }) })),
        ] as MenuItem[])
      : []),
    { type: 'separator' },
    {
      label: 'Delete',
      icon: Trash2,
      danger: true,
      onSelect: async () => {
        if ((await deletePage(kind, page)) && page.id === activeId) navigate(config.listPath(ws))
      },
    },
  ]

  const folderMenu = (folder: Folder): MenuItem[] => [
    { label: `New ${config.label.toLowerCase()} here`, icon: Plus, onSelect: () => void newPage(folder.id) },
    { label: 'Rename folder', icon: Pencil, onSelect: () => void renameFolder(folder) },
    { type: 'separator' },
    { label: 'Delete folder', icon: Trash2, danger: true, onSelect: () => void deleteFolder(folder) },
  ]

  const openFilterMenu = (e: React.MouseEvent<HTMLButtonElement>) =>
    openDropdownMenu(e, [
      { label: 'Pinned only', checked: filters.pinnedOnly, onSelect: () => setFilters((f) => ({ ...f, pinnedOnly: !f.pinnedOnly })) },
      ...(projects.length
        ? ([
            { type: 'label', label: 'Project' },
            { label: 'Any project', checked: !filters.projectId, onSelect: () => setFilters((f) => ({ ...f, projectId: null })) },
            ...projects.map<MenuItem>((p) => ({ label: p.name, checked: filters.projectId === p.id, onSelect: () => setFilters((f) => ({ ...f, projectId: p.id })) })),
          ] as MenuItem[])
        : []),
      ...(tags.length
        ? ([
            { type: 'label', label: 'Tag' },
            { label: 'Any tag', checked: !filters.tag, onSelect: () => setFilters((f) => ({ ...f, tag: null })) },
            ...tags.map<MenuItem>((t) => ({ label: `#${t}`, checked: filters.tag === t, onSelect: () => setFilters((f) => ({ ...f, tag: t })) })),
          ] as MenuItem[])
        : []),
    ])

  const openSortMenu = (e: React.MouseEvent<HTMLButtonElement>) =>
    openDropdownMenu(e, [
      { type: 'label', label: 'Sort by' },
      { label: 'Last edited', checked: filters.sort === 'updated', onSelect: () => setFilters((f) => ({ ...f, sort: 'updated' })) },
      { label: 'Date created', checked: filters.sort === 'created', onSelect: () => setFilters((f) => ({ ...f, sort: 'created' })) },
      { label: 'Title', checked: filters.sort === 'title', onSelect: () => setFilters((f) => ({ ...f, sort: 'title' })) },
    ])

  const onDrop = (folderId: string | null) => (e: DragEvent) => {
    e.preventDefault()
    setDropTarget(null)
    const id = e.dataTransfer.getData(DRAG_TYPE)
    const page = items.find((p) => p.id === id)
    if (page && page.folderId !== folderId) void updatePage(kind, id, { folderId })
  }
  const dropProps = (key: string, folderId: string | null) => ({
    onDragOver: (e: DragEvent) => {
      if (!e.dataTransfer.types.includes(DRAG_TYPE)) return
      e.preventDefault()
      setDropTarget(key)
    },
    onDragLeave: () => setDropTarget((t) => (t === key ? null : t)),
    onDrop: onDrop(folderId),
  })

  const renderPage = (page: Page) => (
    <li key={page.id}>
      <NavLink
        to={config.itemPath(ws, page.id)}
        draggable={canEdit}
        onDragStart={(e) => {
          e.dataTransfer.setData(DRAG_TYPE, page.id)
          e.dataTransfer.effectAllowed = 'move'
        }}
        onContextMenu={canEdit ? (e) => openContextMenu(e, pageMenu(page)) : undefined}
        className={({ isActive }) =>
          cn('group block rounded-md px-2.5 py-2 transition-colors', isActive ? 'bg-accent-soft' : 'hover:bg-surface-2')
        }
      >
        <div className="flex items-center gap-1.5">
          {page.pinned && <Pin className="size-3 shrink-0 text-accent" aria-label="Pinned" />}
          <span className={cn('flex-1 truncate text-sm font-medium', !page.title && 'text-fg-subtle')}>{untitled(page.title)}</span>
          <span className="shrink-0 text-[11px] text-fg-subtle">{formatRelative(page.updatedAt)}</span>
        </div>
        <p className="mt-0.5 line-clamp-1 text-xs text-fg-muted">{page.plainText.trim() || 'No content'}</p>
      </NavLink>
    </li>
  )

  const byFolder = (folderId: string | null) => visible.filter((p) => p.folderId === folderId)
  const loose = byFolder(null)

  return (
    <>
      <div className="flex h-13 shrink-0 items-center gap-1 border-b border-line px-3">
        <button type="button" aria-label="Open navigation" onClick={() => openMobileNav(true)} className="flex size-8 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 md:hidden">
          <Menu className="size-4.5" />
        </button>
        <config.icon className="size-4 text-fg-muted" />
        <h1 className="flex-1 text-sm font-semibold">{config.plural}</h1>
        {canEdit && (
          <>
            <Button size="icon-sm" variant="ghost" aria-label="New folder" title="New folder" onClick={() => void createFolder(ws, config.folderKind)}>
              <FolderPlus className="size-4" />
            </Button>
            <Button size="icon-sm" variant="primary" aria-label={`New ${config.label.toLowerCase()}`} title={`New ${config.label.toLowerCase()}`} onClick={() => void newPage()}>
              <Plus className="size-4" />
            </Button>
          </>
        )}
      </div>

      <div className="flex items-center gap-1 border-b border-line px-3 py-2">
        <label className="relative flex-1">
          <span className="sr-only">Filter {config.plural.toLowerCase()}</span>
          <Search className="pointer-events-none absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-fg-subtle" />
          <input
            value={filters.query}
            onChange={(e) => setFilters((f) => ({ ...f, query: e.target.value }))}
            placeholder={`Search ${config.plural.toLowerCase()}…`}
            className="h-8 w-full rounded-md border border-line bg-canvas pr-2 pl-8 text-sm outline-none placeholder:text-fg-subtle focus:border-accent"
          />
        </label>
        <Button size="icon-sm" variant="ghost" aria-label="Filter" title="Filter" aria-haspopup="menu" onClick={openFilterMenu} className={cn((filters.pinnedOnly || filters.projectId || filters.tag) && 'text-accent')}>
          <Filter className="size-4" />
        </Button>
        <Button size="icon-sm" variant="ghost" aria-label="Sort" title="Sort" aria-haspopup="menu" onClick={openSortMenu}>
          <ArrowDownUp className="size-4" />
        </Button>
      </div>

      {filtering && (
        <div className="flex items-center justify-between border-b border-line px-3 py-1.5 text-xs text-fg-muted">
          <span>
            {visible.length} of {items.length} shown
          </span>
          <button type="button" className="inline-flex items-center gap-1 font-medium text-accent hover:underline" onClick={() => setFilters(DEFAULT_PAGE_FILTERS)}>
            <X className="size-3" /> Clear filters
          </button>
        </div>
      )}

      <div className="min-h-0 flex-1 overflow-y-auto p-2" {...dropProps('root', null)}>
        {status === 'loading' || status === 'idle' ? (
          <ListSkeleton />
        ) : status === 'error' ? (
          <ErrorState message={error ?? 'Could not load'} onRetry={() => void load(ws)} />
        ) : items.length === 0 && folders.length === 0 ? (
          <EmptyState
            icon={config.icon}
            title={config.emptyTitle}
            description={config.emptyDescription}
            action={
              canEdit && (
                <Button variant="primary" onClick={() => void newPage()}>
                  <Plus className="size-4" /> New {config.label.toLowerCase()}
                </Button>
              )
            }
          />
        ) : (
          <>
            {folders.map((folder) => {
              const pages = byFolder(folder.id)
              if (filtering && pages.length === 0) return null
              const isCollapsed = collapsed[folder.id] && !filtering
              return (
                <div key={folder.id} className="mb-1">
                  <div
                    {...dropProps(folder.id, folder.id)}
                    onContextMenu={canEdit ? (e) => openContextMenu(e, folderMenu(folder)) : undefined}
                    className={cn('group flex h-8 items-center gap-1 rounded-md pr-1 transition-colors', dropTarget === folder.id ? 'bg-accent-soft ring-1 ring-accent' : 'hover:bg-surface-2')}
                  >
                    <button
                      type="button"
                      aria-expanded={!isCollapsed}
                      onClick={() => setCollapsed((c) => ({ ...c, [folder.id]: !c[folder.id] }))}
                      className="flex h-full flex-1 items-center gap-1.5 pl-1.5 text-left text-[13px] font-medium text-fg-muted"
                    >
                      <ChevronRight className={cn('size-3.5 transition-transform', !isCollapsed && 'rotate-90')} />
                      <FolderIcon className="size-3.5" />
                      <span className="flex-1 truncate">{folder.name}</span>
                      <span className="text-[11px] font-normal text-fg-subtle">{pages.length}</span>
                    </button>
                    {canEdit && (
                      <button
                        type="button"
                        aria-label={`Folder actions for ${folder.name}`}
                        aria-haspopup="menu"
                        onClick={(e) => openDropdownMenu(e, folderMenu(folder))}
                        className="rounded p-1 text-fg-subtle opacity-0 group-hover:opacity-100 hover:bg-line hover:text-fg focus:opacity-100"
                      >
                        <MoreHorizontal className="size-3.5" />
                      </button>
                    )}
                  </div>
                  {!isCollapsed && (
                    <ul className="ml-3 border-l border-line pl-1.5">
                      {pages.length ? pages.map(renderPage) : <li className="px-2.5 py-1.5 text-xs text-fg-subtle">{canEdit ? 'Empty — drag items here' : 'Empty'}</li>}
                    </ul>
                  )}
                </div>
              )
            })}
            {folders.length > 0 && loose.length > 0 && <div className="mx-2.5 my-2 h-px bg-line" />}
            <ul className={cn('rounded-md', dropTarget === 'root' && folders.length > 0 && 'ring-1 ring-accent')}>{loose.map(renderPage)}</ul>
            {filtering && visible.length === 0 && <p className="px-3 py-8 text-center text-sm text-fg-muted">No {config.plural.toLowerCase()} match your filters.</p>}
          </>
        )}
      </div>
    </>
  )
}
