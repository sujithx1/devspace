import { modKey } from './utils'

const alt = modKey === '⌘' ? '⌥' : 'Alt'

export const SHORTCUTS: { group: string; items: { keys: string[]; label: string }[] }[] = [
  {
    group: 'General',
    items: [
      { keys: [modKey, 'K'], label: 'Command palette & search' },
      { keys: [modKey, '\\'], label: 'Toggle sidebar' },
      { keys: [modKey, '⇧', 'L'], label: 'Cycle theme' },
      { keys: ['?'], label: 'Show keyboard shortcuts' },
    ],
  },
  {
    group: 'Create',
    items: [
      { keys: [alt, 'N'], label: 'New note' },
      { keys: [alt, 'T'], label: 'New task' },
      { keys: [alt, 'P'], label: 'New project' },
      { keys: [alt, 'D'], label: 'New document' },
      { keys: [alt, 'W'], label: 'New drawing' },
    ],
  },
  {
    group: 'Navigate',
    items: [
      { keys: ['G', 'H'], label: 'Dashboard' },
      { keys: ['G', 'N'], label: 'Notes' },
      { keys: ['G', 'T'], label: 'Tasks' },
      { keys: ['G', 'P'], label: 'Projects' },
      { keys: ['G', 'D'], label: 'Docs' },
      { keys: ['G', 'W'], label: 'Drawings' },
    ],
  },
  {
    group: 'Editor',
    items: [
      { keys: [modKey, 'B'], label: 'Bold' },
      { keys: [modKey, 'I'], label: 'Italic' },
      { keys: [modKey, 'E'], label: 'Inline code' },
      { keys: [modKey, '⌥', 'C'], label: 'Code block' },
      { keys: [modKey, 'K'], label: 'Insert link (in editor)' },
      { keys: ['#', 'Space'], label: 'Heading (markdown)' },
      { keys: ['[ ]', 'Space'], label: 'Checklist (markdown)' },
    ],
  },
]
