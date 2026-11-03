import { BookOpen, CalendarDays, CheckSquare, FileText, Pencil, Trash2 } from 'lucide-react'
import { Link } from 'react-router'
import { PriorityBadge, ProjectStatusBadge } from '@/components/ui/Badge'
import { ProgressBar } from '@/components/ui/ProgressBar'
import type { Project } from '@/data'
import { PROJECT_COLOR_META } from '@/lib/meta'
import { paths } from '@/lib/routes'
import { cn, formatDate } from '@/lib/utils'
import { openContextMenu, type MenuItem } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { deleteProject } from './projectActions'
import { scheduleLabel, type ProjectProgress } from './projectLogic'

export function projectMenu(project: Project, onDeleted?: () => void): MenuItem[] {
  return [
    { label: 'Edit project', icon: Pencil, onSelect: () => useQuickCreateStore.getState().openProject({ projectId: project.id }) },
    { type: 'separator' },
    {
      label: 'Delete project',
      icon: Trash2,
      danger: true,
      onSelect: async () => {
        if (await deleteProject(project)) onDeleted?.()
      },
    },
  ]
}

export function ProjectCard({ project, progress, noteCount, docCount }: { project: Project; progress: ProjectProgress; noteCount: number; docCount: number }) {
  const canEdit = useCan('content.edit')
  const schedule = scheduleLabel(project)
  const color = PROJECT_COLOR_META[project.color]
  return (
    <Link
      to={paths.project(project.workspaceId, project.id)}
      onContextMenu={canEdit ? (e) => openContextMenu(e, projectMenu(project)) : undefined}
      className="group flex flex-col rounded-xl border border-line bg-surface p-4 transition-[border-color,box-shadow] hover:border-line-strong hover:shadow-md hover:shadow-black/5"
    >
      <div className="flex items-start gap-3">
        <span className={cn('mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-lg text-sm font-bold', color.soft, color.text)}>
          {project.name.slice(0, 1).toUpperCase()}
        </span>
        <div className="min-w-0 flex-1">
          <h3 className="truncate text-sm font-semibold">{project.name}</h3>
          <div className="mt-1 flex flex-wrap gap-1.5">
            <ProjectStatusBadge status={project.status} />
            <PriorityBadge priority={project.priority} />
          </div>
        </div>
      </div>
      <p className="mt-3 line-clamp-2 min-h-10 text-[13px] leading-5 text-fg-muted">{project.description || 'No description'}</p>
      <div className="mt-4">
        <div className="mb-1.5 flex items-center justify-between text-xs">
          <span className="text-fg-muted">Progress</span>
          <span className="font-medium tabular-nums">{progress.percent}%</span>
        </div>
        <ProgressBar value={progress.percent} label={`${project.name} progress`} barClassName={color.swatch} />
      </div>
      <div className="mt-4 flex items-center gap-3 border-t border-line pt-3 text-xs text-fg-muted">
        <span className="flex items-center gap-1" title="Tasks completed">
          <CheckSquare className="size-3.5" /> {progress.completed}/{progress.total}
        </span>
        <span className="flex items-center gap-1" title="Notes">
          <FileText className="size-3.5" /> {noteCount}
        </span>
        <span className="flex items-center gap-1" title="Docs">
          <BookOpen className="size-3.5" /> {docCount}
        </span>
        <span className="flex-1" />
        {schedule ? (
          <span className={cn('flex items-center gap-1', schedule.overdue && 'text-danger')} title={project.dueDate ? `Due ${formatDate(project.dueDate)}` : undefined}>
            <CalendarDays className="size-3.5" /> {schedule.label}
          </span>
        ) : project.startDate ? (
          <span className="flex items-center gap-1">
            <CalendarDays className="size-3.5" /> Started {formatDate(project.startDate)}
          </span>
        ) : null}
      </div>
    </Link>
  )
}
