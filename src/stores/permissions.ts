import { useMemo } from 'react'
import { create } from 'zustand'
import type { Member, MemberRole, Workspace } from '@/data'
import { useMembersStore } from './collections'
import { PermissionError, setPermissionGuard, type Permission } from './guard'
import { useWorkspaceStore } from './workspaceStore'

/**
 * Role-based permissions for group workspaces.
 *
 * Without a backend there is no sign-in, so the "acting member" is chosen
 * locally (Switch user) to preview what each role can do. The same rules are
 * enforced in the stores, so blocked writes fail no matter which UI path
 * triggers them.
 */

export const ROLE_PERMISSIONS: Record<MemberRole, readonly Permission[]> = {
  owner: ['content.edit', 'members.manage', 'workspace.manage'],
  editor: ['content.edit'],
  viewer: [],
}

export function roleCan(role: MemberRole, permission: Permission) {
  return ROLE_PERMISSIONS[role].includes(permission)
}

const DENIED: Record<Permission, string> = {
  'content.edit': 'Viewers can only read. Switch to an editor or owner to make changes.',
  'members.manage': 'Only owners can manage members.',
  'workspace.manage': 'Only owners can change workspace settings.',
}

// ---------------------------------------------------------------------------
// Acting member (per workspace, remembered on this device)
// ---------------------------------------------------------------------------

const ACTING_KEY = 'devspace:actingAs'

function readActing(): Record<string, string> {
  try {
    return JSON.parse(localStorage.getItem(ACTING_KEY) ?? '{}') as Record<string, string>
  } catch {
    return {}
  }
}

interface ActingState {
  /** workspaceId → memberId */
  actingAs: Record<string, string>
  actAs(workspaceId: string, memberId: string): void
}

export const useActingStore = create<ActingState>()((set, get) => ({
  actingAs: typeof localStorage === 'undefined' ? {} : readActing(),
  actAs(workspaceId, memberId) {
    const actingAs = { ...get().actingAs, [workspaceId]: memberId }
    try {
      localStorage.setItem(ACTING_KEY, JSON.stringify(actingAs))
    } catch {
      // Device preference only.
    }
    set({ actingAs })
  },
}))

/** The member being acted as: the chosen one, else the first owner. */
export function resolveActingMember(workspace: Workspace | undefined, members: Member[], actingAs: Record<string, string>): Member | null {
  if (!workspace || workspace.type !== 'group') return null
  const scoped = members.filter((m) => m.workspaceId === workspace.id)
  return scoped.find((m) => m.id === actingAs[workspace.id]) ?? scoped.find((m) => m.role === 'owner') ?? scoped[0] ?? null
}

/** Private workspaces (and group workspaces before members load) give full access. */
function effectiveRole(member: Member | null): MemberRole {
  return member?.role ?? 'owner'
}

function snapshot() {
  const ws = useWorkspaceStore.getState()
  const workspace = ws.workspaces.find((w) => w.id === ws.activeId)
  const member = resolveActingMember(workspace, useMembersStore.getState().items, useActingStore.getState().actingAs)
  return { workspace, member, role: effectiveRole(member) }
}

/** Non-hook permission check for actions and event handlers. */
export function canNow(permission: Permission): boolean {
  return roleCan(snapshot().role, permission)
}

export function deniedMessage(permission: Permission) {
  return DENIED[permission]
}

setPermissionGuard((permission) => {
  if (!canNow(permission)) throw new PermissionError(permission, DENIED[permission])
})

// ---------------------------------------------------------------------------
// Hooks
// ---------------------------------------------------------------------------

export function useActingMember(): { member: Member | null; role: MemberRole; isGroup: boolean } {
  const workspace = useWorkspaceStore((s) => s.workspaces.find((w) => w.id === s.activeId))
  const members = useMembersStore((s) => s.items)
  const actingAs = useActingStore((s) => s.actingAs)
  return useMemo(() => {
    const member = resolveActingMember(workspace, members, actingAs)
    return { member, role: effectiveRole(member), isGroup: workspace?.type === 'group' }
  }, [workspace, members, actingAs])
}

export function useCan(permission: Permission): boolean {
  return roleCan(useActingMember().role, permission)
}
