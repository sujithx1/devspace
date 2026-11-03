import { MoreHorizontal, Pencil, Trash2, UserPlus } from 'lucide-react'
import { useMemo, useState } from 'react'
import { Button } from '@/components/ui/Button'
import { MEMBER_ROLES, type Member, type Workspace } from '@/data'
import { MEMBER_ROLE_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import { useTasksStore } from '@/stores/collections'
import { openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { toast } from '@/stores/toastStore'
import { MemberAvatar } from './MemberAvatar'
import { MemberDialog } from './MemberDialog'
import { removeMember, updateMember } from './memberActions'
import { useMembers } from './useMembers'

/** Member list and management for a group workspace. */
export function MembersCard({ workspace }: { workspace: Workspace }) {
  const { members } = useMembers()
  const tasks = useTasksStore((s) => s.items)
  const [dialog, setDialog] = useState<{ member?: Member } | null>(null)
  const canManage = useCan('members.manage')

  const openTasks = useMemo(() => {
    const counts = new Map<string, number>()
    for (const t of tasks) if (t.assigneeId && t.status !== 'completed') counts.set(t.assigneeId, (counts.get(t.assigneeId) ?? 0) + 1)
    return counts
  }, [tasks])

  const changeRole = async (member: Member, role: Member['role']) => {
    try {
      await updateMember(member.id, { role })
      toast.success(`${member.name} is now ${MEMBER_ROLE_META[role].label.toLowerCase()}`)
    } catch (error) {
      toast.error(error, 'Could not change role')
    }
  }

  const menu = (member: Member): MenuItem[] => [
    { label: 'Edit member', icon: Pencil, onSelect: () => setDialog({ member }) },
    { type: 'label', label: 'Role' },
    ...MEMBER_ROLES.map<MenuItem>((role) => ({
      label: MEMBER_ROLE_META[role].label,
      checked: member.role === role,
      onSelect: () => void changeRole(member, role),
    })),
    { type: 'separator' },
    { label: 'Remove from workspace', icon: Trash2, danger: true, onSelect: () => void removeMember(member) },
  ]

  return (
    <>
      <div className="mb-3 flex items-center justify-between gap-3">
        <p className="text-xs text-fg-subtle">
          {members.length} member{members.length === 1 ? '' : 's'}
        </p>
        {canManage ? (
          <Button size="sm" variant="primary" onClick={() => setDialog({})}>
            <UserPlus className="size-3.5" /> Add member
          </Button>
        ) : (
          <p className="text-xs text-fg-subtle">Only owners can manage members.</p>
        )}
      </div>
      <ul className="divide-y divide-line overflow-hidden rounded-lg border border-line">
        {members.map((member) => {
          const open = openTasks.get(member.id) ?? 0
          return (
            <li key={member.id} className="flex items-center gap-3 px-3 py-2.5">
              <MemberAvatar member={member} size="md" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{member.name}</p>
                <p className="truncate text-xs text-fg-subtle">
                  {member.email || 'No email'} · {open} open task{open === 1 ? '' : 's'}
                </p>
              </div>
              <span
                className={cn(
                  'rounded px-1.5 py-0.5 text-[11px] font-medium',
                  member.role === 'owner' ? 'bg-accent-soft text-accent' : 'bg-surface-2 text-fg-muted',
                )}
              >
                {MEMBER_ROLE_META[member.role].label}
              </span>
              {canManage && (
                <Button size="icon-sm" variant="ghost" aria-label={`Actions for ${member.name}`} aria-haspopup="menu" onClick={(e) => openDropdownMenu(e, menu(member))}>
                  <MoreHorizontal className="size-4" />
                </Button>
              )}
            </li>
          )
        })}
      </ul>
      <p className="mt-3 text-xs text-fg-subtle">
        Members and roles are stored on this device. Inviting people to sign in and enforcing roles needs a server, which comes in a later phase.
      </p>
      <MemberDialog open={dialog !== null} member={dialog?.member} workspaceId={workspace.id} onClose={() => setDialog(null)} />
    </>
  )
}
