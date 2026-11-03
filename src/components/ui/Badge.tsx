import type { ReactNode } from 'react'
import type { Priority, ProjectStatus } from '@/data'
import { PRIORITY_META, PROJECT_STATUS_META } from '@/lib/meta'
import { cn } from '@/lib/utils'

export function Badge({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <span className={cn('inline-flex h-5 items-center gap-1 rounded px-1.5 text-[11px] font-medium whitespace-nowrap', className)}>
      {children}
    </span>
  )
}

export function PriorityBadge({ priority }: { priority: Priority }) {
  const meta = PRIORITY_META[priority]
  return <Badge className={meta.className}>{meta.label}</Badge>
}

export function ProjectStatusBadge({ status }: { status: ProjectStatus }) {
  const meta = PROJECT_STATUS_META[status]
  return <Badge className={meta.className}>{meta.label}</Badge>
}
