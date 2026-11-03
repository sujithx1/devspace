import type { Member } from '@/data'
import { cn } from '@/lib/utils'

const PALETTE = ['bg-indigo-500', 'bg-emerald-500', 'bg-amber-500', 'bg-rose-500', 'bg-sky-500', 'bg-violet-500', 'bg-teal-500', 'bg-orange-500']

export function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  return ((parts[0]?.[0] ?? '?') + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase()
}

/** Stable colour per member so avatars are recognisable across views. */
function colorFor(id: string) {
  let hash = 0
  for (const ch of id) hash = (hash * 31 + ch.charCodeAt(0)) | 0
  return PALETTE[Math.abs(hash) % PALETTE.length]
}

export function MemberAvatar({ member, size = 'sm', className }: { member: Pick<Member, 'id' | 'name'>; size?: 'xs' | 'sm' | 'md'; className?: string }) {
  return (
    <span
      title={member.name}
      aria-label={member.name}
      className={cn(
        'inline-flex shrink-0 items-center justify-center rounded-full font-semibold text-white select-none',
        colorFor(member.id),
        size === 'xs' && 'size-5 text-[9px]',
        size === 'sm' && 'size-6 text-[10px]',
        size === 'md' && 'size-8 text-xs',
        className,
      )}
    >
      {initials(member.name)}
    </span>
  )
}
