import { BookOpen, FileText, type LucideIcon } from 'lucide-react'
import type { FolderKind, Page, PageInput } from '@/data'
import type { CollectionState } from '@/stores/createCollectionStore'
import { useDocsStore, useNotesStore } from '@/stores/collections'
import { paths } from '@/lib/routes'
import type { StoreApi, UseBoundStore } from 'zustand'

export type PageKind = 'note' | 'doc'

export type PageStore = UseBoundStore<StoreApi<CollectionState<Page, PageInput, Partial<PageInput>>>>

export interface PageKindConfig {
  kind: PageKind
  label: string
  plural: string
  icon: LucideIcon
  folderKind: FolderKind
  useStore: PageStore
  listPath: (ws: string) => string
  itemPath: (ws: string, id: string) => string
  placeholder: string
  emptyTitle: string
  emptyDescription: string
}

export const PAGE_KINDS: Record<PageKind, PageKindConfig> = {
  note: {
    kind: 'note',
    label: 'Note',
    plural: 'Notes',
    icon: FileText,
    folderKind: 'note',
    useStore: useNotesStore,
    listPath: paths.notes,
    itemPath: paths.note,
    placeholder: 'Start writing, or type ``` for a code block…',
    emptyTitle: 'No notes yet',
    emptyDescription: 'Capture ideas, meeting notes, snippets and checklists.',
  },
  doc: {
    kind: 'doc',
    label: 'Document',
    plural: 'Docs',
    icon: BookOpen,
    folderKind: 'doc',
    useStore: useDocsStore,
    listPath: paths.docs,
    itemPath: paths.doc,
    placeholder: 'Write documentation. Markdown shortcuts work: #, ##, -, 1., ```, >…',
    emptyTitle: 'No documentation yet',
    emptyDescription: 'Write technical docs, runbooks, ADRs and API references, and link them to projects.',
  },
}
