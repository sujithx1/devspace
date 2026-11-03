import { BookOpen, CheckSquare, FileText, FolderKanban, PenTool, type LucideIcon } from 'lucide-react'
import type { EntityType } from '@/data'

export const ENTITY_META: Record<EntityType, { label: string; plural: string; icon: LucideIcon }> = {
  note: { label: 'Note', plural: 'Notes', icon: FileText },
  doc: { label: 'Document', plural: 'Docs', icon: BookOpen },
  task: { label: 'Task', plural: 'Tasks', icon: CheckSquare },
  project: { label: 'Project', plural: 'Projects', icon: FolderKanban },
  drawing: { label: 'Drawing', plural: 'Drawings', icon: PenTool },
}

export const untitled = (title: string, fallback = 'Untitled') => title.trim() || fallback
