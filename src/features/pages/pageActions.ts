import type { Page, PageInput } from '@/data'
import { confirmDialog } from '@/stores/dialogStore'
import { useRecentsStore } from '@/stores/recentsStore'
import { toast } from '@/stores/toastStore'
import { untitled } from '@/lib/entities'
import { PAGE_KINDS, type PageKind } from './pageKinds'

/**
 * Business operations for notes and documents. Components call these instead
 * of talking to stores directly so behaviour (toasts, confirmations, recents
 * bookkeeping) stays consistent everywhere a page can be acted on.
 */

export async function createPage(kind: PageKind, workspaceId: string, input: Partial<PageInput> = {}): Promise<Page | null> {
  try {
    return await PAGE_KINDS[kind].useStore.getState().create({ title: '', ...input, workspaceId })
  } catch (error) {
    toast.error(error, `Could not create ${PAGE_KINDS[kind].label.toLowerCase()}`)
    return null
  }
}

export async function duplicatePage(kind: PageKind, page: Page): Promise<Page | null> {
  try {
    const copy = await PAGE_KINDS[kind].useStore.getState().create({
      workspaceId: page.workspaceId,
      folderId: page.folderId,
      projectId: page.projectId,
      title: `${untitled(page.title)} (copy)`.slice(0, 200),
      content: page.content ? structuredClone(page.content) : null,
      plainText: page.plainText,
      tags: [...page.tags],
      pinned: false,
    })
    toast.success(`Duplicated “${untitled(page.title)}”`)
    return copy
  } catch (error) {
    toast.error(error, 'Could not duplicate')
    return null
  }
}

/** Asks for confirmation and deletes. Resolves `true` when the page was deleted. */
export async function deletePage(kind: PageKind, page: Page): Promise<boolean> {
  const { label } = PAGE_KINDS[kind]
  const ok = await confirmDialog({
    title: `Delete ${label.toLowerCase()}?`,
    description: `“${untitled(page.title)}” will be permanently deleted. This cannot be undone.`,
    confirmLabel: 'Delete',
    destructive: true,
  })
  if (!ok) return false
  try {
    await PAGE_KINDS[kind].useStore.getState().remove(page.id)
    useRecentsStore.getState().forget(kind, page.id)
    toast.success(`${label} deleted`)
    return true
  } catch (error) {
    toast.error(error, 'Could not delete')
    return false
  }
}

/** Persists a patch. Resolves `false` (after notifying the user) when saving failed. */
export async function updatePage(kind: PageKind, id: string, patch: Partial<PageInput>): Promise<boolean> {
  try {
    await PAGE_KINDS[kind].useStore.getState().update(id, patch)
    return true
  } catch (error) {
    toast.error(error, 'Could not save changes')
    return false
  }
}
