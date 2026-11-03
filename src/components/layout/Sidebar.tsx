import { AnimatePresence, motion } from 'framer-motion'
import {
  BookOpen,
  CheckSquare,
  ChevronsUpDown,
  FileText,
  FolderKanban,
  Keyboard,
  LayoutDashboard,
  Monitor,
  Moon,
  PanelLeftClose,
  PanelLeftOpen,
  PenTool,
  Pencil,
  Pin,
  Plus,
  Search,
  Settings,
  Sun,
  type LucideIcon,
} from 'lucide-react'
import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router'
import { ActingAsSwitcher } from '@/features/members/ActingAs'
import { WorkspaceDialog } from '@/features/workspaces/WorkspaceDialog'
import { WORKSPACE_TYPE_META } from '@/features/workspaces/WorkspaceTypePicker'
import { ENTITY_META, untitled } from '@/lib/entities'
import { PROJECT_COLOR_META } from '@/lib/meta'
import { entityPath, paths } from '@/lib/routes'
import { cn, modKey } from '@/lib/utils'
import { useDocsStore, useDrawingsStore, useMembersStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { useUIStore } from '@/stores/uiStore'
import { useActiveWorkspace, useWorkspaceStore } from '@/stores/workspaceStore'
import { useRecentEntries } from '@/features/dashboard/useRecentEntries'
import { LogoMark } from './Logo'

export function Sidebar() {
  const collapsed = useUIStore((s) => s.sidebarCollapsed)
  const mobileOpen = useUIStore((s) => s.mobileSidebarOpen)
  const setMobileOpen = useUIStore((s) => s.setMobileSidebarOpen)
  const { pathname } = useLocation()

  // Any navigation (links, shortcuts, palette) closes the mobile drawer.
  useEffect(() => setMobileOpen(false), [pathname, setMobileOpen])

  return (
    <>
      {/* Desktop */}
      <motion.aside
        initial={false}
        animate={{ width: collapsed ? 56 : 252 }}
        transition={{ duration: 0.18, ease: 'easeOut' }}
        className="hidden h-full shrink-0 border-r border-line bg-surface md:block"
        aria-label="Main navigation"
      >
        <SidebarContent collapsed={collapsed} />
      </motion.aside>

      {/* Mobile drawer */}
      <AnimatePresence>
        {mobileOpen && (
          <div className="fixed inset-0 z-40 md:hidden">
            <motion.div
              className="absolute inset-0 bg-black/40"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileOpen(false)}
            />
            <motion.aside
              initial={{ x: -280 }}
              animate={{ x: 0 }}
              exit={{ x: -280 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
              className="absolute inset-y-0 left-0 w-[264px] border-r border-line bg-surface shadow-xl"
              aria-label="Main navigation"
            >
              <SidebarContent collapsed={false} />
            </motion.aside>
          </div>
        )}
      </AnimatePresence>
    </>
  )
}

function SidebarContent({ collapsed }: { collapsed: boolean }) {
  const workspace = useActiveWorkspace()
  const ws = workspace?.id ?? ''
  const toggleSidebar = useUIStore((s) => s.toggleSidebar)
  const setPaletteOpen = useUIStore((s) => s.setCommandPaletteOpen)
  const setShortcutsOpen = useUIStore((s) => s.setShortcutsOpen)

  const noteCount = useNotesStore((s) => s.items.length)
  const docCount = useDocsStore((s) => s.items.length)
  const openTaskCount = useTasksStore((s) => s.items.filter((t) => t.status !== 'completed').length)
  const projectCount = useProjectsStore((s) => s.items.length)
  const drawingCount = useDrawingsStore((s) => s.items.length)

  const nav: { to: string; label: string; icon: LucideIcon; count?: number; end?: boolean }[] = [
    { to: paths.workspace(ws), label: 'Dashboard', icon: LayoutDashboard, end: true },
    { to: paths.notes(ws), label: 'Notes', icon: FileText, count: noteCount },
    { to: paths.tasks(ws), label: 'Tasks', icon: CheckSquare, count: openTaskCount },
    { to: paths.projects(ws), label: 'Projects', icon: FolderKanban, count: projectCount },
    { to: paths.docs(ws), label: 'Docs', icon: BookOpen, count: docCount },
    { to: paths.drawings(ws), label: 'Drawings', icon: PenTool, count: drawingCount },
  ]

  return (
    <div className="flex h-full flex-col overflow-hidden">
      <div className={cn('flex h-13 items-center gap-1 px-2.5 pt-1', collapsed && 'justify-center px-0')}>
        <WorkspaceSwitcher collapsed={collapsed} />
      </div>

      <div className={cn('px-2.5 pb-2', collapsed && 'px-2')}>
        <button
          type="button"
          onClick={() => setPaletteOpen(true)}
          title={collapsed ? `Search (${modKey}K)` : undefined}
          className={cn(
            'flex h-8 w-full items-center gap-2 rounded-md border border-line bg-canvas px-2.5 text-sm text-fg-subtle transition-colors hover:border-line-strong hover:text-fg-muted',
            collapsed && 'justify-center px-0',
          )}
        >
          <Search className="size-3.5 shrink-0" />
          {!collapsed && (
            <>
              <span className="flex-1 text-left">Search…</span>
              <span className="text-[11px] tracking-wide">{modKey}K</span>
            </>
          )}
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto px-2.5 pb-4" aria-label="Sections">
        <ul className="flex flex-col gap-0.5">
          {nav.map((item) => (
            <li key={item.label}>
              <SidebarLink {...item} collapsed={collapsed} />
            </li>
          ))}
        </ul>
        {!collapsed && ws && (
          <>
            <ProjectsSection ws={ws} />
            <PinnedSection ws={ws} />
            <RecentSection ws={ws} />
          </>
        )}
      </nav>

      <div className={cn('border-t border-line px-2 pt-2', collapsed && 'px-1.5')}>
        <ActingAsSwitcher collapsed={collapsed} />
      </div>
      <div className={cn('flex items-center gap-1 p-2', collapsed && 'flex-col')}>
        <ThemeButton />
        <IconButton label="Keyboard shortcuts" onClick={() => setShortcutsOpen(true)}>
          <Keyboard className="size-4" />
        </IconButton>
        <NavLink
          to={paths.settings(ws)}
          aria-label="Workspace settings"
          title="Workspace settings"
          className={({ isActive }) =>
            cn('flex size-8 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 hover:text-fg', isActive && 'bg-surface-2 text-fg')
          }
        >
          <Settings className="size-4" />
        </NavLink>
        <div className={cn(!collapsed && 'flex-1')} />
        <IconButton label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'} onClick={toggleSidebar} className="hidden md:flex">
          {collapsed ? <PanelLeftOpen className="size-4" /> : <PanelLeftClose className="size-4" />}
        </IconButton>
      </div>
    </div>
  )
}

function SidebarLink({ to, label, icon: Icon, count, end, collapsed }: { to: string; label: string; icon: LucideIcon; count?: number; end?: boolean; collapsed: boolean }) {
  return (
    <NavLink
      to={to}
      end={end}
      title={collapsed ? label : undefined}
      className={({ isActive }) =>
        cn(
          'group flex h-8 items-center gap-2.5 rounded-md px-2.5 text-sm transition-colors',
          isActive ? 'bg-surface-2 font-medium text-fg' : 'text-fg-muted hover:bg-surface-2/70 hover:text-fg',
          collapsed && 'justify-center px-0',
        )
      }
    >
      <Icon className="size-4 shrink-0" />
      {!collapsed && (
        <>
          <span className="flex-1 truncate">{label}</span>
          {!!count && <span className="text-xs text-fg-subtle tabular-nums">{count}</span>}
        </>
      )}
    </NavLink>
  )
}

function Section({ title, action, children }: { title: string; action?: ReactNode; children: ReactNode }) {
  return (
    <section className="mt-5">
      <div className="mb-1 flex h-6 items-center justify-between px-2.5">
        <h2 className="text-[11px] font-medium tracking-wider text-fg-subtle uppercase">{title}</h2>
        {action}
      </div>
      <ul className="flex flex-col gap-0.5">{children}</ul>
    </section>
  )
}

function SmallLink({ to, icon, children }: { to: string; icon: ReactNode; children: ReactNode }) {
  return (
    <li>
      <NavLink
        to={to}
        className={({ isActive }) =>
          cn(
            'flex h-7 items-center gap-2.5 rounded-md px-2.5 text-[13px] transition-colors',
            isActive ? 'bg-surface-2 text-fg' : 'text-fg-muted hover:bg-surface-2/70 hover:text-fg',
          )
        }
      >
        {icon}
        <span className="truncate">{children}</span>
      </NavLink>
    </li>
  )
}

function ProjectsSection({ ws }: { ws: string }) {
  const projects = useProjectsStore((s) => s.items)
  const openProject = useQuickCreateStore((s) => s.openProject)
  const canEdit = useCan('content.edit')
  const visible = useMemo(
    () => projects.filter((p) => p.status !== 'completed').sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 6),
    [projects],
  )
  return (
    <Section
      title="Projects"
      action={
        canEdit && (
          <button type="button" aria-label="New project" title="New project" onClick={() => openProject()} className="rounded p-0.5 text-fg-subtle hover:bg-surface-2 hover:text-fg">
            <Plus className="size-3.5" />
          </button>
        )
      }
    >
      {visible.length === 0 ? (
        <li className="px-2.5 py-1 text-xs text-fg-subtle">No active projects</li>
      ) : (
        visible.map((p) => (
          <SmallLink key={p.id} to={paths.project(ws, p.id)} icon={<span className={cn('size-2 shrink-0 rounded-full', PROJECT_COLOR_META[p.color].swatch)} />}>
            {p.name}
          </SmallLink>
        ))
      )}
    </Section>
  )
}

function PinnedSection({ ws }: { ws: string }) {
  const notes = useNotesStore((s) => s.items)
  const docs = useDocsStore((s) => s.items)
  const pinned = useMemo(
    () => [
      ...notes.filter((n) => n.pinned).map((n) => ({ type: 'note' as const, item: n })),
      ...docs.filter((d) => d.pinned).map((d) => ({ type: 'doc' as const, item: d })),
    ],
    [notes, docs],
  )
  if (pinned.length === 0) return null
  return (
    <Section title="Pinned">
      {pinned.map(({ type, item }) => (
        <SmallLink key={item.id} to={entityPath(ws, type, item.id)} icon={<Pin className="size-3.5 shrink-0" />}>
          {untitled(item.title)}
        </SmallLink>
      ))}
    </Section>
  )
}

function RecentSection({ ws }: { ws: string }) {
  const entries = useRecentEntries(6)
  if (entries.length === 0) return null
  return (
    <Section title="Recent">
      {entries.map((e) => {
        const Icon = ENTITY_META[e.type].icon
        return (
          <SmallLink key={`${e.type}:${e.id}`} to={entityPath(ws, e.type, e.id)} icon={<Icon className="size-3.5 shrink-0" />}>
            {e.title}
          </SmallLink>
        )
      })}
    </Section>
  )
}

function WorkspaceSwitcher({ collapsed }: { collapsed: boolean }) {
  const navigate = useNavigate()
  const workspace = useActiveWorkspace()
  const workspaces = useWorkspaceStore((s) => s.workspaces)
  const memberCount = useMembersStore((s) => s.items.length)
  const [dialog, setDialog] = useState<'create' | 'rename' | null>(null)
  const canManage = useCan('workspace.manage')

  const openMenu = (e: React.MouseEvent<HTMLButtonElement>) => {
    const items: MenuItem[] = [
      { type: 'label', label: 'Workspaces' },
      ...workspaces.map<MenuItem>((w) => ({
        label: `${w.icon}  ${w.name}`,
        icon: WORKSPACE_TYPE_META[w.type].icon,
        checked: w.id === workspace?.id,
        onSelect: () => navigate(paths.workspace(w.id)),
      })),
      { type: 'separator' },
      { label: 'Create workspace', icon: Plus, onSelect: () => setDialog('create') },
      { label: 'Rename workspace', icon: Pencil, onSelect: () => setDialog('rename'), disabled: !workspace || !canManage },
      { label: 'Workspace settings', icon: Settings, onSelect: () => workspace && navigate(paths.settings(workspace.id)) },
    ]
    openDropdownMenu(e, items)
  }

  return (
    <>
      <button
        type="button"
        onClick={openMenu}
        aria-haspopup="menu"
        aria-label="Switch workspace"
        className={cn('flex h-10 min-w-0 flex-1 items-center gap-2 rounded-md px-1.5 text-left hover:bg-surface-2', collapsed && 'flex-none justify-center px-0')}
      >
        {workspace ? (
          <span className="flex size-7 shrink-0 items-center justify-center rounded-md bg-surface-2 text-base">{workspace.icon}</span>
        ) : (
          <LogoMark />
        )}
        {!collapsed && (
          <>
            <span className="min-w-0 flex-1">
              <span className="block truncate text-sm font-semibold">{workspace?.name ?? 'DevSpace'}</span>
              {workspace && (
                <span className="block truncate text-[11px] text-fg-subtle">
                  {workspace.type === 'group' ? `Group · ${memberCount} member${memberCount === 1 ? '' : 's'}` : 'Private'}
                </span>
              )}
            </span>
            <ChevronsUpDown className="size-3.5 shrink-0 text-fg-subtle" />
          </>
        )}
      </button>
      <WorkspaceDialog
        open={dialog !== null}
        workspace={dialog === 'rename' ? workspace : undefined}
        onClose={() => setDialog(null)}
        onSaved={(w) => dialog === 'create' && navigate(paths.workspace(w.id))}
      />
    </>
  )
}

function ThemeButton() {
  const theme = useUIStore((s) => s.theme)
  const cycleTheme = useUIStore((s) => s.cycleTheme)
  const Icon = theme === 'light' ? Sun : theme === 'dark' ? Moon : Monitor
  return (
    <IconButton label={`Theme: ${theme} (click to change)`} onClick={cycleTheme}>
      <Icon className="size-4" />
    </IconButton>
  )
}

function IconButton({ label, onClick, children, className }: { label: string; onClick: () => void; children: ReactNode; className?: string }) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      onClick={onClick}
      className={cn('flex size-8 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 hover:text-fg', className)}
    >
      {children}
    </button>
  )
}
