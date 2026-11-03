import { Menu } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'
import { useUIStore } from '@/stores/uiStore'

/** Top bar for every workspace page; includes the mobile navigation toggle. */
export function PageHeader({ title, icon, actions, children, className }: { title?: ReactNode; icon?: ReactNode; actions?: ReactNode; children?: ReactNode; className?: string }) {
  const openMobile = useUIStore((s) => s.setMobileSidebarOpen)
  return (
    <header className={cn('flex h-13 shrink-0 items-center gap-2 border-b border-line bg-surface/80 px-3 backdrop-blur md:px-5', className)}>
      <button
        type="button"
        aria-label="Open navigation"
        onClick={() => openMobile(true)}
        className="-ml-1 flex size-8 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 md:hidden"
      >
        <Menu className="size-4.5" />
      </button>
      {icon && <span className="text-fg-muted">{icon}</span>}
      {title && <h1 className="min-w-0 truncate text-sm font-semibold">{title}</h1>}
      <div className="flex min-w-0 flex-1 items-center gap-2">{children}</div>
      {actions && <div className="flex shrink-0 items-center gap-1.5">{actions}</div>}
    </header>
  )
}
