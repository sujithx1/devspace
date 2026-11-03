import { FolderKanban } from 'lucide-react'
import { useProjectsStore } from '@/stores/collections'
import { cn } from '@/lib/utils'

/** Compact select for linking an entity to a project. */
export function ProjectSelect({
  value,
  onChange,
  className,
  id,
  compact,
  disabled,
}: {
  value: string | null
  onChange: (projectId: string | null) => void
  className?: string
  id?: string
  compact?: boolean
  disabled?: boolean
}) {
  const projects = useProjectsStore((s) => s.items)
  return (
    <label className={cn('relative inline-flex items-center', className)}>
      {compact && <FolderKanban className="pointer-events-none absolute left-2 size-3.5 text-fg-subtle" />}
      <span className="sr-only">Project</span>
      <select
        id={id}
        value={value ?? ''}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value || null)}
        className={cn(
          'w-full cursor-pointer rounded-md disabled:cursor-default disabled:opacity-70 border border-line bg-surface text-sm text-fg outline-none focus:border-accent',
          compact ? 'h-7 max-w-44 pr-6 pl-7 text-xs text-fg-muted' : 'h-9 px-3',
        )}
      >
        <option value="">{compact ? 'No project' : 'None'}</option>
        {projects
          .slice()
          .sort((a, b) => a.name.localeCompare(b.name))
          .map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
      </select>
    </label>
  )
}
