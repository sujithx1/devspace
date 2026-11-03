import { motion } from 'framer-motion'
import { ArrowRight, BookOpen, CalendarClock, CheckSquare, Clock, FileText, FolderKanban, LayoutDashboard, PenTool, Plus, type LucideIcon } from 'lucide-react'
import { useMemo, useState, type ReactNode } from 'react'
import { Link } from 'react-router'
import { PageHeader } from '@/components/layout/PageHeader'
import { PriorityBadge } from '@/components/ui/Badge'
import { ProgressBar } from '@/components/ui/ProgressBar'
import { Skeleton } from '@/components/ui/States'
import { DrawingCard, useDrawingMenu } from '@/features/drawings/DrawingCard'
import { projectProgress, scheduleLabel } from '@/features/projects/projectLogic'
import { updateTask } from '@/features/tasks/taskActions'
import { compareForList, dueLabel, isOverdue, taskStats } from '@/features/tasks/taskLogic'
import { useCreateActions } from '@/features/useCreateActions'
import { ENTITY_META, untitled } from '@/lib/entities'
import { PROJECT_COLOR_META } from '@/lib/meta'
import { entityPath, paths } from '@/lib/routes'
import { cn, formatRelative } from '@/lib/utils'
import { useDocsStore, useDrawingsStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { useActiveWorkspace } from '@/stores/workspaceStore'
import { useRecentEntries } from './useRecentEntries'

function greeting(date = new Date()) {
  const h = date.getHours()
  return h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening'
}

export function DashboardPage() {
  const workspace = useActiveWorkspace()
  const ws = workspace?.id ?? ''
  const create = useCreateActions()
  const tasks = useTasksStore((s) => s.items)
  const tasksStatus = useTasksStore((s) => s.status)
  const projects = useProjectsStore((s) => s.items)
  const notes = useNotesStore((s) => s.items)
  const docs = useDocsStore((s) => s.items)
  const drawings = useDrawingsStore((s) => s.items)
  const recent = useRecentEntries(8)
  const drawingMenu = useDrawingMenu()
  const openTask = useQuickCreateStore((s) => s.openTask)
  const canEdit = useCan('content.edit')

  // Captured once per visit so render stays pure.
  const [now] = useState(() => new Date())
  const stats = useMemo(() => taskStats(tasks), [tasks])
  const completedThisWeek = useMemo(() => tasks.filter((t) => t.completedAt && now.getTime() - t.completedAt < 7 * 86_400_000).length, [tasks, now])
  const pending = useMemo(() => tasks.filter((t) => t.status !== 'completed').sort(compareForList).slice(0, 7), [tasks])
  const activeProjects = useMemo(
    () => projects.filter((p) => p.status === 'active' || p.status === 'planning').sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 4),
    [projects],
  )
  const recentDocs = useMemo(
    () =>
      [...notes.map((n) => ({ type: 'note' as const, page: n })), ...docs.map((d) => ({ type: 'doc' as const, page: d }))]
        .sort((a, b) => b.page.updatedAt - a.page.updatedAt)
        .slice(0, 5),
    [notes, docs],
  )
  const recentDrawings = useMemo(() => [...drawings].sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 4), [drawings])
  const loading = tasksStatus !== 'ready'

  const quick: { label: string; icon: LucideIcon; shortcut: string; run: () => void }[] = [
    { label: 'Note', icon: FileText, shortcut: 'N', run: () => void create.newNote() },
    { label: 'Task', icon: CheckSquare, shortcut: 'T', run: () => create.newTask() },
    { label: 'Project', icon: FolderKanban, shortcut: 'P', run: () => create.newProject() },
    { label: 'Doc', icon: BookOpen, shortcut: 'D', run: () => void create.newDoc() },
    { label: 'Drawing', icon: PenTool, shortcut: 'W', run: () => void create.newDrawing() },
  ]

  return (
    <>
      <PageHeader title="Dashboard" icon={<LayoutDashboard className="size-4" />} />
      <div className="min-h-0 flex-1 overflow-y-auto">
        <motion.div initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }} className="mx-auto flex max-w-6xl flex-col gap-6 p-4 md:p-8">
          <section className="flex flex-col gap-5 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="text-sm text-fg-muted">{now.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })}</p>
              <h1 className="mt-1 text-2xl font-semibold tracking-tight md:text-3xl">
                {greeting(now)} <span className="text-fg-muted">·</span> {workspace?.icon} {workspace?.name}
              </h1>
            </div>
            {canEdit && (
              <div className="flex flex-wrap gap-2" aria-label="Quick create">
                {quick.map((q) => (
                  <button
                    key={q.label}
                    type="button"
                    onClick={q.run}
                    title={`New ${q.label.toLowerCase()} (Alt+${q.shortcut})`}
                    className="flex h-9 items-center gap-2 rounded-lg border border-line bg-surface px-3 text-sm font-medium shadow-xs transition-colors hover:border-line-strong hover:bg-surface-2"
                  >
                    <Plus className="size-3.5 text-fg-subtle" />
                    <q.icon className="size-4 text-accent" />
                    {q.label}
                  </button>
                ))}
              </div>
            )}
          </section>

          <section aria-label="Task statistics" className="grid grid-cols-2 gap-3 lg:grid-cols-4">
            {loading ? (
              [0, 1, 2, 3].map((i) => <Skeleton key={i} className="h-24" />)
            ) : (
              <>
                <Stat label="Open tasks" value={stats.todo + stats.inProgress} detail={`${stats.todo} todo · ${stats.inProgress} in progress`} />
                <Stat label="Completion rate" value={`${stats.completionRate}%`} detail={`${stats.completed} of ${stats.total} done`}>
                  <ProgressBar value={stats.completionRate} label="Task completion rate" className="mt-3" />
                </Stat>
                <Stat label="Completed this week" value={completedThisWeek} detail="Last 7 days" />
                <Stat label="Overdue" value={stats.overdue} detail={stats.overdue ? 'Needs attention' : 'All on track'} tone={stats.overdue ? 'danger' : undefined} />
              </>
            )}
          </section>

          <div className="grid gap-6 lg:grid-cols-[1.4fr_1fr]">
            <Panel title="Pending tasks" icon={CheckSquare} to={paths.tasks(ws)}>
              {pending.length === 0 ? (
                <PanelEmpty text={tasks.length ? 'Everything is done. Nice work!' : 'No tasks yet.'} action={canEdit ? { label: 'Add a task', run: () => openTask() } : undefined} />
              ) : (
                <ul className="divide-y divide-line">
                  {pending.map((t) => (
                    <li key={t.id} className="flex items-center gap-3 px-4 py-2.5">
                      <input
                        type="checkbox"
                        checked={false}
                        disabled={!canEdit}
                        onChange={() => void updateTask(t.id, { status: 'completed' })}
                        aria-label={`Complete “${t.title}”`}
                        className="size-4 shrink-0 cursor-pointer accent-[var(--ds-accent)]"
                      />
                      <button type="button" onClick={() => openTask({ taskId: t.id })} className="min-w-0 flex-1 truncate text-left text-sm hover:text-accent">
                        {t.title}
                      </button>
                      {t.dueDate && (
                        <span className={cn('flex shrink-0 items-center gap-1 text-xs', isOverdue(t) ? 'text-danger' : 'text-fg-muted')}>
                          <CalendarClock className="size-3" /> {dueLabel(t.dueDate)}
                        </span>
                      )}
                      <PriorityBadge priority={t.priority} />
                    </li>
                  ))}
                </ul>
              )}
            </Panel>

            <Panel title="Recently opened" icon={Clock}>
              {recent.length === 0 ? (
                <PanelEmpty text="Pages you open will show up here." />
              ) : (
                <ul className="py-1">
                  {recent.map((r) => {
                    const Icon = ENTITY_META[r.type].icon
                    return (
                      <li key={`${r.type}:${r.id}`}>
                        <Link to={entityPath(ws, r.type, r.id)} className="flex items-center gap-3 px-4 py-2 hover:bg-surface-2/60">
                          <Icon className="size-4 shrink-0 text-fg-subtle" />
                          <span className="min-w-0 flex-1 truncate text-sm">{r.title}</span>
                          <span className="shrink-0 text-xs text-fg-subtle">{formatRelative(r.visitedAt)}</span>
                        </Link>
                      </li>
                    )
                  })}
                </ul>
              )}
            </Panel>
          </div>

          <Panel title="Active projects" icon={FolderKanban} to={paths.projects(ws)}>
            {activeProjects.length === 0 ? (
              <PanelEmpty text="No active projects." action={canEdit ? { label: 'Create a project', run: () => create.newProject() } : undefined} />
            ) : (
              <div className="-mb-px grid sm:grid-cols-2">
                {activeProjects.map((p) => {
                  const progress = projectProgress(p.id, tasks)
                  const schedule = scheduleLabel(p)
                  return (
                    <Link key={p.id} to={paths.project(ws, p.id)} className="flex flex-col gap-2.5 border-b border-line p-4 hover:bg-surface-2/50 sm:odd:border-r">
                      <div className="flex items-center gap-2">
                        <span className={cn('size-2.5 rounded-full', PROJECT_COLOR_META[p.color].swatch)} />
                        <span className="flex-1 truncate text-sm font-medium">{p.name}</span>
                        {schedule && <span className={cn('text-xs', schedule.overdue ? 'text-danger' : 'text-fg-subtle')}>{schedule.label}</span>}
                      </div>
                      <ProgressBar value={progress.percent} label={`${p.name} progress`} barClassName={PROJECT_COLOR_META[p.color].swatch} />
                      <span className="text-xs text-fg-muted">
                        {progress.percent}% · {progress.completed}/{progress.total} tasks
                      </span>
                    </Link>
                  )
                })}
              </div>
            )}
          </Panel>

          <div className="grid gap-6 lg:grid-cols-[1fr_1.4fr]">
            <Panel title="Recent notes & docs" icon={BookOpen} to={paths.docs(ws)}>
              {recentDocs.length === 0 ? (
                <PanelEmpty text="No notes or docs yet." action={canEdit ? { label: 'Write a note', run: () => void create.newNote() } : undefined} />
              ) : (
                <ul className="py-1">
                  {recentDocs.map(({ type, page }) => {
                    const Icon = ENTITY_META[type].icon
                    return (
                      <li key={page.id}>
                        <Link to={entityPath(ws, type, page.id)} className="flex items-start gap-3 px-4 py-2.5 hover:bg-surface-2/60">
                          <Icon className="mt-0.5 size-4 shrink-0 text-fg-subtle" />
                          <span className="min-w-0 flex-1">
                            <span className="block truncate text-sm font-medium">{untitled(page.title)}</span>
                            <span className="block truncate text-xs text-fg-muted">{page.plainText.trim() || 'No content'}</span>
                          </span>
                          <span className="shrink-0 text-xs text-fg-subtle">{formatRelative(page.updatedAt)}</span>
                        </Link>
                      </li>
                    )
                  })}
                </ul>
              )}
            </Panel>
            <Panel title="Recent drawings" icon={PenTool} to={paths.drawings(ws)}>
              {recentDrawings.length === 0 ? (
                <PanelEmpty text="No drawings yet." action={canEdit ? { label: 'Start a drawing', run: () => void create.newDrawing() } : undefined} />
              ) : (
                <div className="grid grid-cols-2 gap-3 p-3">
                  {recentDrawings.map((d) => (
                    <DrawingCard key={d.id} drawing={d} menu={drawingMenu(d)} />
                  ))}
                </div>
              )}
            </Panel>
          </div>
        </motion.div>
      </div>
    </>
  )
}

function Stat({ label, value, detail, tone, children }: { label: string; value: ReactNode; detail?: string; tone?: 'danger'; children?: ReactNode }) {
  return (
    <div className="rounded-xl border border-line bg-surface p-4">
      <p className="text-xs font-medium text-fg-muted">{label}</p>
      <p className={cn('mt-1.5 text-2xl font-semibold tracking-tight tabular-nums', tone === 'danger' && 'text-danger')}>{value}</p>
      {detail && <p className="mt-0.5 text-xs text-fg-subtle">{detail}</p>}
      {children}
    </div>
  )
}

function Panel({ title, icon: Icon, to, children }: { title: string; icon: LucideIcon; to?: string; children: ReactNode }) {
  return (
    <section className="flex flex-col overflow-hidden rounded-xl border border-line bg-surface">
      <header className="flex h-11 items-center gap-2 border-b border-line px-4">
        <Icon className="size-4 text-fg-subtle" />
        <h2 className="flex-1 text-sm font-semibold">{title}</h2>
        {to && (
          <Link to={to} className="flex items-center gap-1 text-xs font-medium text-fg-muted hover:text-accent">
            View all <ArrowRight className="size-3" />
          </Link>
        )}
      </header>
      <div className="flex-1">{children}</div>
    </section>
  )
}

function PanelEmpty({ text, action }: { text: string; action?: { label: string; run: () => void } }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-4 py-10 text-center">
      <p className="text-sm text-fg-muted">{text}</p>
      {action && (
        <button type="button" onClick={action.run} className="text-sm font-medium text-accent hover:underline">
          {action.label}
        </button>
      )}
    </div>
  )
}
