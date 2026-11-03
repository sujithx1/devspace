import type { LucideIcon } from 'lucide-react'
import type { MouseEvent as ReactMouseEvent } from 'react'
import { create } from 'zustand'

export type MenuItem =
  | {
      type?: 'item'
      label: string
      icon?: LucideIcon
      shortcut?: string
      danger?: boolean
      disabled?: boolean
      checked?: boolean
      onSelect: () => void
    }
  | { type: 'separator' }
  | { type: 'label'; label: string }

interface MenuState {
  open: boolean
  x: number
  y: number
  items: MenuItem[]
  show(x: number, y: number, items: MenuItem[]): void
  hide(): void
}

export const useMenuStore = create<MenuState>()((set) => ({
  open: false,
  x: 0,
  y: 0,
  items: [],
  show: (x, y, items) => set({ open: true, x, y, items }),
  hide: () => set({ open: false }),
}))

/** Opens a context menu at the pointer. Use as an `onContextMenu` handler. */
export function openContextMenu(event: ReactMouseEvent, items: MenuItem[]) {
  event.preventDefault()
  event.stopPropagation()
  useMenuStore.getState().show(event.clientX, event.clientY, items)
}

/** Opens a dropdown menu anchored below the clicked element. */
export function openDropdownMenu(event: ReactMouseEvent<HTMLElement>, items: MenuItem[]) {
  event.preventDefault()
  event.stopPropagation()
  const rect = event.currentTarget.getBoundingClientRect()
  useMenuStore.getState().show(rect.left, rect.bottom + 4, items)
}
