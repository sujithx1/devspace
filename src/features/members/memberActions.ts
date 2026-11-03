import type { Member, MemberInput, Workspace } from '@/data'
import { useMembersStore, useTasksStore } from '@/stores/collections'
import { confirmDialog } from '@/stores/dialogStore'
import { toast } from '@/stores/toastStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'

/** Adds a member. Throws so forms can show field errors. */
export async function addMember(input: MemberInput): Promise<Member> {
  const member = await useMembersStore.getState().create(input)
  toast.success(`${member.name} added`)
  return member
}

/** Updates a member. Throws so forms can show field errors. */
export async function updateMember(id: string, patch: Partial<Omit<MemberInput, 'workspaceId'>>): Promise<Member> {
  return useMembersStore.getState().update(id, patch)
}

export async function removeMember(member: Member): Promise<boolean> {
  const assigned = useTasksStore.getState().items.filter((t) => t.assigneeId === member.id).length
  const ok = await confirmDialog({
    title: `Remove ${member.name}?`,
    description: assigned
      ? `${member.name} will be removed from this workspace and unassigned from ${assigned} task${assigned === 1 ? '' : 's'}.`
      : `${member.name} will be removed from this workspace.`,
    confirmLabel: 'Remove',
    destructive: true,
  })
  if (!ok) return false
  try {
    await useMembersStore.getState().remove(member.id)
    // Storage unassigned their tasks; refresh the in-memory copy.
    if (assigned) await useTasksStore.getState().load(member.workspaceId)
    toast.success(`${member.name} removed`)
    return true
  } catch (error) {
    toast.error(error, 'Could not remove member')
    return false
  }
}

/** Turns a private workspace into a group workspace, creating its first owner. */
export async function convertToGroup(workspace: Workspace, ownerName: string): Promise<void> {
  const members = useMembersStore.getState()
  if (!members.items.some((m) => m.role === 'owner')) {
    await members.create({ workspaceId: workspace.id, name: ownerName, role: 'owner' })
  }
  await useWorkspaceStore.getState().update(workspace.id, { type: 'group' })
  toast.success(`${workspace.name} is now a group workspace`)
}

/** Turns a group workspace back into a private one. Members are kept so the change can be undone. */
export async function convertToPrivate(workspace: Workspace): Promise<boolean> {
  const ok = await confirmDialog({
    title: 'Make this workspace private?',
    description: 'Members and task assignments are hidden but kept, so you can switch back to a group workspace later.',
    confirmLabel: 'Make private',
  })
  if (!ok) return false
  await useWorkspaceStore.getState().update(workspace.id, { type: 'private' })
  toast.success(`${workspace.name} is now private`)
  return true
}
