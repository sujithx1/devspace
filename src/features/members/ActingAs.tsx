import { ChevronsUpDown, Eye, PencilLine } from 'lucide-react'
import type { MouseEvent } from 'react'
import { MEMBER_ROLE_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import { openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { useActingMember, useActingStore } from '@/stores/permissions'
import { toast } from '@/stores/toastStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { MemberAvatar } from './MemberAvatar'
import { useMembers } from './useMembers'

/** Opens the "Switch user" menu listing every member of the group workspace. */
function useSwitchUserMenu() {
  const { members } = useMembers()
  const { member: current } = useActingMember()
  const workspaceId = useWorkspaceStore((s) => s.activeId)
  const actAs = useActingStore((s) => s.actAs)

  return (e: MouseEvent<HTMLElement>) => {
    if (!workspaceId) return
    const items: MenuItem[] = [
      { type: 'label', label: 'Switch user' },
      ...members.map<MenuItem>((m) => ({
        label: `${m.name} · ${MEMBER_ROLE_META[m.role].label}`,
        checked: m.id === current?.id,
        onSelect: () => {
          actAs(workspaceId, m.id)
          toast.info(`Now acting as ${m.name} (${MEMBER_ROLE_META[m.role].label})`)
        },
      })),
    ]
    openDropdownMenu(e, items)
  }
}

/** Sidebar control showing who you're acting as in a group workspace. */
export function ActingAsSwitcher({ collapsed }: { collapsed: boolean }) {
  const { member, isGroup } = useActingMember()
  const openMenu = useSwitchUserMenu()
  if (!isGroup || !member) return null
  return (
    <button
      type="button"
      onClick={openMenu}
      aria-haspopup="menu"
      aria-label={`Acting as ${member.name}, ${member.role}. Switch user`}
      title="Switch user"
      className={cn('flex w-full items-center gap-2 rounded-md p-1.5 text-left hover:bg-surface-2', collapsed && 'justify-center')}
    >
      <MemberAvatar member={member} size="sm" />
      {!collapsed && (
        <>
          <span className="min-w-0 flex-1">
            <span className="block truncate text-[13px] font-medium">{member.name}</span>
            <span className="block text-[11px] text-fg-subtle">{MEMBER_ROLE_META[member.role].label}</span>
          </span>
          <ChevronsUpDown className="size-3.5 text-fg-subtle" />
        </>
      )}
    </button>
  )
}

/** Thin bar shown to non-owners so it's always clear which permissions apply. */
export function RoleBanner() {
  const { member, role, isGroup } = useActingMember()
  const openMenu = useSwitchUserMenu()
  if (!isGroup || !member || role === 'owner') return null
  const viewer = role === 'viewer'
  return (
    <div
      role="status"
      className={cn(
        'flex shrink-0 items-center gap-2 border-b px-4 py-1.5 text-xs',
        viewer ? 'border-amber-500/30 bg-amber-500/10 text-amber-700 dark:text-amber-300' : 'border-sky-500/30 bg-sky-500/10 text-sky-700 dark:text-sky-300',
      )}
    >
      {viewer ? <Eye className="size-3.5 shrink-0" /> : <PencilLine className="size-3.5 shrink-0" />}
      <span className="min-w-0 flex-1 truncate">
        Acting as <strong className="font-semibold">{member.name}</strong> ({MEMBER_ROLE_META[role].label}) —{' '}
        {viewer ? 'read-only access' : 'can edit content, but not members or workspace settings'}
      </span>
      <button type="button" onClick={openMenu} aria-haspopup="menu" className="shrink-0 font-semibold underline-offset-2 hover:underline">
        Switch user
      </button>
    </div>
  )
}
