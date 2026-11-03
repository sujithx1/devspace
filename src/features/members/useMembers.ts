import { useMemo } from 'react'
import type { Member } from '@/data'
import { useMembersStore } from '@/stores/collections'
import { useActiveWorkspace } from '@/stores/workspaceStore'

const ROLE_RANK = { owner: 0, editor: 1, viewer: 2 } as const

export function sortMembers(members: Member[]): Member[] {
  return [...members].sort((a, b) => ROLE_RANK[a.role] - ROLE_RANK[b.role] || a.name.localeCompare(b.name))
}

/** Members of the active workspace, owners first. Empty for private workspaces. */
export function useMembers(): { isGroup: boolean; members: Member[]; byId: Map<string, Member> } {
  const workspace = useActiveWorkspace()
  const items = useMembersStore((s) => s.items)
  const isGroup = workspace?.type === 'group'
  return useMemo(() => {
    const members = isGroup ? sortMembers(items) : []
    return { isGroup, members, byId: new Map(members.map((m) => [m.id, m])) }
  }, [isGroup, items])
}
