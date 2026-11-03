import { ArrowLeft, BookOpen, FolderKanban, CalendarDays, CheckSquare, FileText, Link2, MoreHorizontal, Pencil, PenTool, Plus, Unlink } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { PageHeader } from '@/components/layout/PageHeader'
import { PriorityBadge, ProjectStatusBadge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { ProgressBar } from '@/components/ui/ProgressBar'
import { EmptyState, Spinner } from '@/components/ui/States'
import { PROJECT_STATUSES, type Page, type Project, type ProjectStatus } from '@/data'
import { trackVisit } from '@/features/dashboard/useRecentEntries'
import { DrawingCard, useDrawingMenu } from '@/features/drawings/DrawingCard'
import { updatePage } from '@/features/pages/pageActions'
import { PAGE_KINDS, type PageKind } from '@/features/pages/pageKinds'
import { useMembers } from '@/features/members/useMembers'
import { KanbanBoard } from '@/features/tasks/KanbanBoard'
import { TaskFilterBar } from '@/features/tasks/TaskFilterBar'
import { DEFAULT_TASK_FILTERS, filterTasks, taskStats, type TaskFilters } from '@/features/tasks/taskLogic'
import { TaskList } from '@/features/tasks/TaskList'
import { useCreateActions } from '@/features/useCreateActions'
import { untitled } from '@/lib/entities'
import { PROJECT_COLOR_META, PROJECT_STATUS_META } from '@/lib/meta'
import { paths } from '@/lib/routes'
import { cn, formatDate, formatRelative } from '@/lib/utils'
import { useDocsStore, useDrawingsStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { toast } from '@/stores/toastStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { projectMenu } from './ProjectCard'
import { projectProgress, scheduleLabel } from './projectLogic'

type Tab = 'tasks' | 'notes' | 'docs' | 'drawings'

export function ProjectDetailPage() {
  const { projectId = '' } = useParams()
  const ws = useWorkspaceId()
  const status = useProjectsStore((s) => s.status)
  const project = useProjectsStore((s) => s.items.find((p) => p.id === projectId))
  const exists = !!project

  useEffect(() => {
    if (exists) trackVisit(ws, 'project', projectId)
  }, [exists, ws, projectId])

  if (status !== 'ready') {
    return (
      <div className="flex flex-1 items-center justify-center">
        <Spinner />
      </div>
    )
  }
  if (!project) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <EmptyState
          icon={FolderKanban}
          title="Project not found"
          description="It may have been deleted."
          action={
            <Link to={paths.projects(ws)} className="text-sm font-medium text-accent hover:underline">
              Back to projects
            </Link>
          }
        />
      </div>
    )
  }
  return <ProjectDetail project={project} />
}

function ProjectDetail({ project }: { project: Project }) {
  const ws = useWorkspaceId()
  const navigate = useNavigate()
  const tasks = useTasksStore((s) => s.items)
  const notes = useNotesStore((s) => s.items)
  const docs = useDocsStore((s) => s.items)
  const drawings = useDrawingsStore((s) => s.items)
  const projects = useProjectsStore((s) => s.items)
  const openProject = useQuickCreateStore((s) => s.openProject)
  const canEdit = useCan('content.edit')
  const [tab, setTab] = useState<Tab>('tasks')

  const projectTasks = useMemo(() => tasks.filter((t) => t.projectId === project.id), [tasks, project.id])
  const projectNotes = useMemo(() => notes.filter((n) => n.projectId === project.id), [notes, project.id])
  const projectDocs = useMemo(() => docs.filter((d) => d.projectId === project.id), [docs, project.id])
  const projectDrawings = useMemo(() => drawings.filter((d) => d.projectId === project.id), [drawings, project.id])
  const progress = projectProgress(project.id, tasks)
  const stats = taskStats(projectTasks)
  const schedule = scheduleLabel(project)
  const color = PROJECT_COLOR_META[project.color]

  const setStatus = async (status: ProjectStatus) => {
    try {
      await useProjectsStore.getState().update(project.id, { status })
    } catch (error) {
      toast.error(error, 'Could not update project')
    }
  }

  const tabs: { id: Tab; label: string; icon: typeof FileText; count: number }[] = [
    { id: 'tasks', label: 'Tasks', icon: CheckSquare, count: projectTasks.length },
    { id: 'notes', label: 'Notes', icon: FileText, count: projectNotes.length },
    { id: 'docs', label: 'Docs', icon: BookOpen, count: projectDocs.length },
    { id: 'drawings', label: 'Drawings', icon: PenTool, count: projectDrawings.length },
  ]

  return (
    <>
      <PageHeader
        title={
          <span className="flex items-center gap-2">
            <Link to={paths.projects(ws)} className="hidden font-normal text-fg-muted hover:text-fg sm:inline">
              Projects
            </Link>
            <span className="hidden text-fg-subtle sm:inline">/</span>
            {project.name}
          </span>
        }
        icon={
          <Link to={paths.projects(ws)} aria-label="Back to projects" className="sm:hidden">
            <ArrowLeft className="size-4" />
          </Link>
        }
        actions={
          canEdit && (
            <>
              <Button size="sm" variant="outline" onClick={() => openProject({ projectId: project.id })}>
                <Pencil className="size-3.5" /> Edit
              </Button>
              <Button size="icon-sm" variant="ghost" aria-label="More actions" aria-haspopup="menu" onClick={(e) => openDropdownMenu(e, projectMenu(project, () => navigate(paths.projects(ws))))}>
                <MoreHorizontal className="size-4" />
              </Button>
            </>
          )
        }
      />

      <div className="min-h-0 flex-1 overflow-y-auto">
        <div className="mx-auto flex max-w-6xl flex-col gap-5 p-4 md:p-6">
          <section className="grid gap-4 lg:grid-cols-[1fr_320px]">
            <div className="rounded-xl border border-line bg-surface p-5">
              <div className="flex items-start gap-3">
                <span className={cn('flex size-10 shrink-0 items-center justify-center rounded-xl text-lg font-bold', color.soft, color.text)}>{project.name.slice(0, 1).toUpperCase()}</span>
                <div className="min-w-0">
                  <h2 className="text-xl font-semibold tracking-tight">{project.name}</h2>
                  <div className="mt-1.5 flex flex-wrap items-center gap-1.5">
                    <ProjectStatusBadge status={project.status} />
                    <PriorityBadge priority={project.priority} />
                    <span className="text-xs text-fg-subtle">Updated {formatRelative(project.updatedAt)}</span>
                  </div>
                </div>
              </div>
              <p className={cn('mt-4 text-sm leading-6 whitespace-pre-wrap', project.description ? 'text-fg-muted' : 'text-fg-subtle italic')}>
                {project.description || 'No description yet. Click Edit to add goals and scope.'}
              </p>
            </div>
            <div className="flex flex-col gap-4 rounded-xl border border-line bg-surface p-5">
              <div>
                <div className="mb-2 flex items-baseline justify-between">
                  <span className="text-xs font-medium text-fg-muted">Progress</span>
                  <span className="text-2xl font-semibold tabular-nums">{progress.percent}%</span>
                </div>
                <ProgressBar value={progress.percent} label="Project progress" barClassName={color.swatch} className="h-2" />
                <p className="mt-2 text-xs text-fg-subtle">
                  {progress.completed} of {progress.total} tasks completed
                  {stats.overdue ? <span className="text-danger"> · {stats.overdue} overdue</span> : null}
                </p>
              </div>
              <dl className="grid grid-cols-2 gap-3 text-sm">
                <div>
                  <dt className="text-xs text-fg-subtle">Start</dt>
                  <dd className="mt-0.5 flex items-center gap-1.5">
                    <CalendarDays className="size-3.5 text-fg-subtle" />
                    {project.startDate ? formatDate(project.startDate) : '—'}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs text-fg-subtle">Due</dt>
                  <dd className={cn('mt-0.5 flex items-center gap-1.5', schedule?.overdue && 'text-danger')}>
                    <CalendarDays className="size-3.5 text-fg-subtle" />
                    {project.dueDate ? formatDate(project.dueDate) : '—'}
                  </dd>
                </div>
              </dl>
              <label className="flex flex-col gap-1">
                <span className="text-xs text-fg-subtle">Status</span>
                <select
                  value={project.status}
                  disabled={!canEdit}
                  onChange={(e) => void setStatus(e.target.value as ProjectStatus)}
                  className="h-8 cursor-pointer rounded-md border border-line bg-surface px-2 text-sm outline-none focus:border-accent"
                >
                  {PROJECT_STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {PROJECT_STATUS_META[s].label}
                    </option>
                  ))}
                </select>
              </label>
            </div>
          </section>

          <section>
            <div role="tablist" aria-label="Project content" className="mb-4 flex gap-1 overflow-x-auto border-b border-line">
              {tabs.map((t) => (
                <button
                  key={t.id}
                  type="button"
                  role="tab"
                  aria-selected={tab === t.id}
                  onClick={() => setTab(t.id)}
                  className={cn(
                    '-mb-px flex h-9 items-center gap-1.5 border-b-2 px-3 text-sm font-medium whitespace-nowrap transition-colors',
                    tab === t.id ? 'border-accent text-fg' : 'border-transparent text-fg-muted hover:text-fg',
                  )}
                >
                  <t.icon className="size-3.5" /> {t.label}
                  <span className="text-xs text-fg-subtle">{t.count}</span>
                </button>
              ))}
            </div>
            <div role="tabpanel">
              {tab === 'tasks' && <ProjectTasks project={project} tasks={projectTasks} projects={projects} />}
              {tab === 'notes' && <ProjectPages kind="note" project={project} pages={projectNotes} all={notes} />}
              {tab === 'docs' && <ProjectPages kind="doc" project={project} pages={projectDocs} all={docs} />}
              {tab === 'drawings' && <ProjectDrawings project={project} />}
            </div>
          </section>
        </div>
      </div>
    </>
  )
}

function ProjectTasks({ project, tasks, projects }: { project: Project; tasks: ReturnType<typeof useTasksStore.getState>['items']; projects: Project[] }) {
  const [filters, setFilters] = useState<TaskFilters>(DEFAULT_TASK_FILTERS)
  const { members } = useMembers()
  const canEdit = useCan('content.edit')
  const openTask = useQuickCreateStore((s) => s.openTask)
  const visible = useMemo(() => filterTasks(tasks, filters), [tasks, filters])
  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        <div className="flex-1">
          <TaskFilterBar filters={filters} onChange={setFilters} projects={projects} members={members} hideProject />
        </div>
        {canEdit && (
          <Button size="sm" variant="primary" onClick={() => openTask({ defaults: { projectId: project.id } })}>
            <Plus className="size-3.5" /> Add task
          </Button>
        )}
      </div>
      <KanbanBoard tasks={visible} projects={projects} workspaceId={project.workspaceId} projectId={project.id} className="hidden h-[560px] sm:grid" />
      <div className="sm:hidden">
        {visible.length ? <TaskList tasks={visible} projects={projects} /> : <p className="py-8 text-center text-sm text-fg-muted">No tasks in this project yet.</p>}
      </div>
    </div>
  )
}

function ProjectPages({ kind, project, pages, all }: { kind: PageKind; project: Project; pages: Page[]; all: Page[] }) {
  const config = PAGE_KINDS[kind]
  const create = useCreateActions()
  const ws = project.workspaceId
  const unlinked = all.filter((p) => p.projectId !== project.id)
  const canEdit = useCan('content.edit')

  const linkExisting = (e: React.MouseEvent<HTMLButtonElement>) =>
    openDropdownMenu(e, [
      { type: 'label', label: `Link a ${config.label.toLowerCase()}` },
      ...unlinked
        .sort((a, b) => b.updatedAt - a.updatedAt)
        .slice(0, 20)
        .map<MenuItem>((p) => ({ label: untitled(p.title), icon: config.icon, onSelect: () => void updatePage(kind, p.id, { projectId: project.id }) })),
    ])

  return (
    <div className="flex flex-col gap-3">
      {canEdit && (
        <div className="flex justify-end gap-2">
          {unlinked.length > 0 && (
            <Button size="sm" variant="outline" aria-haspopup="menu" onClick={linkExisting}>
              <Link2 className="size-3.5" /> Link existing
            </Button>
          )}
          <Button size="sm" variant="primary" onClick={() => void (kind === 'note' ? create.newNote({ projectId: project.id }) : create.newDoc({ projectId: project.id }))}>
            <Plus className="size-3.5" /> New {config.label.toLowerCase()}
          </Button>
        </div>
      )}
      {pages.length === 0 ? (
        <EmptyState icon={config.icon} title={`No ${config.plural.toLowerCase()} linked`} description={`Create a ${config.label.toLowerCase()} for this project or link an existing one.`} className="py-10" />
      ) : (
        <ul className="divide-y divide-line overflow-hidden rounded-xl border border-line bg-surface">
          {[...pages]
            .sort((a, b) => b.updatedAt - a.updatedAt)
            .map((p) => (
              <li key={p.id} className="group flex items-center gap-3 px-4 py-3 hover:bg-surface-2/60">
                <config.icon className="size-4 shrink-0 text-fg-subtle" />
                <Link to={config.itemPath(ws, p.id)} className="min-w-0 flex-1">
                  <span className="block truncate text-sm font-medium">{untitled(p.title)}</span>
                  <span className="block truncate text-xs text-fg-muted">{p.plainText.trim() || 'No content'}</span>
                </Link>
                <span className="hidden text-xs text-fg-subtle sm:inline">{formatRelative(p.updatedAt)}</span>
                {canEdit && (
                  <button
                    type="button"
                    aria-label={`Unlink ${untitled(p.title)} from project`}
                    title="Unlink from project"
                    onClick={() => void updatePage(kind, p.id, { projectId: null })}
                    className="rounded p-1 text-fg-subtle opacity-0 group-hover:opacity-100 hover:bg-line hover:text-fg focus:opacity-100"
                  >
                    <Unlink className="size-3.5" />
                  </button>
                )}
              </li>
            ))}
        </ul>
      )}
    </div>
  )
}

function ProjectDrawings({ project }: { project: Project }) {
  const drawings = useDrawingsStore((s) => s.items)
  const create = useCreateActions()
  const menu = useDrawingMenu()
  const canEdit = useCan('content.edit')
  const linked = drawings.filter((d) => d.projectId === project.id).sort((a, b) => b.updatedAt - a.updatedAt)
  return (
    <div className="flex flex-col gap-3">
      {canEdit && (
        <div className="flex justify-end">
          <Button size="sm" variant="primary" onClick={() => void create.newDrawing({ projectId: project.id })}>
            <Plus className="size-3.5" /> New drawing
          </Button>
        </div>
      )}
      {linked.length === 0 ? (
        <EmptyState icon={PenTool} title="No drawings linked" description="Sketch architecture diagrams and flows for this project." className="py-10" />
      ) : (
        <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4">
          {linked.map((d) => (
            <DrawingCard key={d.id} drawing={d} menu={menu(d)} />
          ))}
        </div>
      )}
    </div>
  )
}
