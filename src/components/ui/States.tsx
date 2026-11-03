import type { LucideIcon } from 'lucide-react'
import { AlertTriangle } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { Button } from './Button'

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  className,
}: {
  icon: LucideIcon
  title: string
  description?: string
  action?: ReactNode
  className?: string
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center px-6 py-16 text-center', className)}>
      <div className="mb-4 flex size-12 items-center justify-center rounded-xl border border-line bg-surface-2">
        <Icon className="size-5 text-fg-muted" />
      </div>
      <h3 className="text-sm font-semibold">{title}</h3>
      {description && <p className="mt-1 max-w-sm text-sm text-fg-muted">{description}</p>}
      {action && <div className="mt-5">{action}</div>}
    </div>
  )
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div role="alert" className="flex flex-col items-center justify-center px-6 py-16 text-center">
      <div className="mb-4 flex size-12 items-center justify-center rounded-xl bg-danger-soft">
        <AlertTriangle className="size-5 text-danger" />
      </div>
      <h3 className="text-sm font-semibold">Something went wrong</h3>
      <p className="mt-1 max-w-sm text-sm text-fg-muted">{message}</p>
      {onRetry && (
        <Button className="mt-5" variant="outline" onClick={onRetry}>
          Try again
        </Button>
      )}
    </div>
  )
}

export function Skeleton({ className }: { className?: string }) {
  return <div className={cn('animate-shimmer rounded-md bg-surface-2', className)} />
}

export function ListSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="flex flex-col gap-2" aria-busy="true" aria-label="Loading">
      {Array.from({ length: rows }, (_, i) => (
        <Skeleton key={i} className="h-14" />
      ))}
    </div>
  )
}

export function Spinner({ className }: { className?: string }) {
  return (
    <span
      role="progressbar"
      aria-label="Loading"
      className={cn('inline-block size-5 animate-spin rounded-full border-2 border-line-strong border-t-accent', className)}
    />
  )
}

export function Kbd({ children }: { children: ReactNode }) {
  return (
    <kbd className="inline-flex h-5 min-w-5 items-center justify-center rounded border border-line bg-surface-2 px-1 font-sans text-[11px] font-medium text-fg-muted">
      {children}
    </kbd>
  )
}
