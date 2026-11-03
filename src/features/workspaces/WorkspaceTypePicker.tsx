import { Lock, Users, type LucideIcon } from 'lucide-react'
import type { WorkspaceType } from '@/data'
import { cn } from '@/lib/utils'

export const WORKSPACE_TYPE_META: Record<WorkspaceType, { label: string; description: string; icon: LucideIcon }> = {
  private: { label: 'Private', description: 'Just for you', icon: Lock },
  group: { label: 'Group', description: 'Members, roles & task assignment', icon: Users },
}

/** Radio cards for choosing between a private and a group workspace. */
export function WorkspaceTypePicker({ value, onChange, disabled }: { value: WorkspaceType; onChange: (type: WorkspaceType) => void; disabled?: boolean }) {
  return (
    <fieldset>
      <legend className="mb-1.5 text-xs font-medium text-fg-muted">Type</legend>
      <div role="radiogroup" aria-label="Workspace type" className="grid grid-cols-2 gap-2">
        {(Object.keys(WORKSPACE_TYPE_META) as WorkspaceType[]).map((type) => {
          const { label, description, icon: Icon } = WORKSPACE_TYPE_META[type]
          const selected = value === type
          return (
            <button
              key={type}
              type="button"
              role="radio"
              aria-checked={selected}
              disabled={disabled}
              onClick={() => onChange(type)}
              className={cn(
                'flex items-start gap-2.5 rounded-lg border p-3 text-left transition-colors disabled:pointer-events-none disabled:opacity-60',
                selected ? 'border-accent bg-accent-soft' : 'border-line hover:border-line-strong hover:bg-surface-2',
              )}
            >
              <Icon className={cn('mt-0.5 size-4 shrink-0', selected ? 'text-accent' : 'text-fg-muted')} />
              <span>
                <span className={cn('block text-sm font-medium', selected && 'text-accent')}>{label}</span>
                <span className="block text-xs text-fg-muted">{description}</span>
              </span>
            </button>
          )
        })}
      </div>
    </fieldset>
  )
}
