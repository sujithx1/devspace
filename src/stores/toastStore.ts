import { create } from 'zustand'
import { createId } from '@/lib/id'
import { errorMessage } from '@/data'

export type ToastKind = 'success' | 'error' | 'info'

export interface Toast {
  id: string
  kind: ToastKind
  message: string
  action?: { label: string; onClick: () => void }
}

interface ToastState {
  toasts: Toast[]
  push(toast: Omit<Toast, 'id'>, durationMs?: number): string
  dismiss(id: string): void
}

export const useToastStore = create<ToastState>()((set, get) => ({
  toasts: [],
  push(toast, durationMs = 4000) {
    const id = createId()
    set((s) => ({ toasts: [...s.toasts.slice(-3), { ...toast, id }] }))
    setTimeout(() => get().dismiss(id), durationMs)
    return id
  },
  dismiss(id) {
    set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }))
  },
}))

/** Imperative helpers usable from anywhere (stores, event handlers). */
export const toast = {
  success: (message: string, action?: Toast['action']) => useToastStore.getState().push({ kind: 'success', message, action }),
  info: (message: string) => useToastStore.getState().push({ kind: 'info', message }),
  error: (error: unknown, fallback?: string) =>
    useToastStore.getState().push({ kind: 'error', message: errorMessage(error, fallback) }, 6000),
}
