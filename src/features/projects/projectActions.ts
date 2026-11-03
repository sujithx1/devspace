import type { Project } from '@/data'
import { useDocsStore, useDrawingsStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { confirmDialog } from '@/stores/dialogStore'
import { useRecentsStore } from '@/stores/recentsStore'
import { toast } from '@/stores/toastStore'

/** Deletes a project after confirmation. Linked items are kept but unlinked. */
export async function deleteProject(project: Project): Promise<boolean> {
  const ok = await confirmDialog({
    title: 'Delete project?',
    description: `“${project.name}” will be deleted. Its tasks, notes, docs and drawings are kept and unlinked from the project.`,
    confirmLabel: 'Delete project',
    destructive: true,
  })
  if (!ok) return false
  try {
    await useProjectsStore.getState().remove(project.id)
    useRecentsStore.getState().forget('project', project.id)
    // Storage unlinked related items; refresh the affected collections.
    await Promise.all([useTasksStore, useNotesStore, useDocsStore, useDrawingsStore].map((s) => s.getState().load(project.workspaceId)))
    toast.success('Project deleted')
    return true
  } catch (error) {
    toast.error(error, 'Could not delete project')
    return false
  }
}
