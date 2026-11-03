import { create } from 'zustand'

export interface ConfirmOptions {
  title: string
  description?: string
  confirmLabel?: string
  destructive?: boolean
}

export interface PromptOptions {
  title: string
  label: string
  initialValue?: string
  placeholder?: string
  confirmLabel?: string
  /** Return an error message to block submission. */
  validate?: (value: string) => string | null
}

type DialogRequest =
  | { type: 'confirm'; options: ConfirmOptions; resolve: (ok: boolean) => void }
  | { type: 'prompt'; options: PromptOptions; resolve: (value: string | null) => void }

interface DialogState {
  current: DialogRequest | null
  close(): void
}

export const useDialogStore = create<DialogState>()((set) => ({
  current: null,
  close: () => set({ current: null }),
}))

/** Promise-based confirmation dialog. Resolves `true` when confirmed. */
export function confirmDialog(options: ConfirmOptions): Promise<boolean> {
  return new Promise((resolve) => {
    useDialogStore.setState({ current: { type: 'confirm', options, resolve } })
  })
}

/** Promise-based single-field prompt. Resolves the trimmed value, or `null` if cancelled. */
export function promptDialog(options: PromptOptions): Promise<string | null> {
  return new Promise((resolve) => {
    useDialogStore.setState({ current: { type: 'prompt', options, resolve } })
  })
}
