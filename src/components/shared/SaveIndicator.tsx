import { AlertCircle, Check, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'

export type SaveState = 'saved' | 'pending' | 'saving' | 'error'

const CONTENT: Record<SaveState, { icon: React.ReactNode; label: string }> = {
  saved: { icon: <Check className="size-3.5" />, label: 'Saved' },
  pending: { icon: <span className="size-1.5 rounded-full bg-warning" />, label: 'Unsaved' },
  saving: { icon: <Loader2 className="size-3.5 animate-spin" />, label: 'Saving…' },
  error: { icon: <AlertCircle className="size-3.5" />, label: 'Not saved' },
}

/** Autosave status shown in editor headers. */
export function SaveIndicator({ state, className }: { state: SaveState; className?: string }) {
  const { icon, label } = CONTENT[state]
  return (
    <span role="status" aria-live="polite" className={cn('items-center gap-1.5 text-xs', state === 'error' ? 'text-danger' : 'text-fg-subtle', className)}>
      {icon}
      {label}
    </span>
  )
}
