import { useEffect, useState, type FormEvent } from 'react'
import { useDialogStore, type PromptOptions } from '@/stores/dialogStore'
import { Button } from './Button'
import { Field, Input } from './Field'
import { Modal } from './Modal'

/** Hosts the promise-based confirm and prompt dialogs. Mounted once at the app root. */
export function DialogHost() {
  const { current, close } = useDialogStore()

  if (current?.type === 'prompt') {
    return (
      <PromptDialog
        key={current.options.title}
        options={current.options}
        onDone={(value) => {
          current.resolve(value)
          close()
        }}
      />
    )
  }

  const confirm = current?.type === 'confirm' ? current : null
  const finish = (ok: boolean) => {
    confirm?.resolve(ok)
    close()
  }
  return (
    <Modal
      open={!!confirm}
      onClose={() => finish(false)}
      title={confirm?.options.title ?? ''}
      description={confirm?.options.description}
      size="sm"
      footer={
        <>
          {/* Destructive confirmations focus Cancel so Enter never deletes by accident. */}
          <Button variant="ghost" onClick={() => finish(false)} data-autofocus={confirm?.options.destructive || undefined}>
            Cancel
          </Button>
          <Button variant={confirm?.options.destructive ? 'danger' : 'primary'} onClick={() => finish(true)} data-autofocus={!confirm?.options.destructive || undefined}>
            {confirm?.options.confirmLabel ?? 'Confirm'}
          </Button>
        </>
      }
    >
      {null}
    </Modal>
  )
}

function PromptDialog({ options, onDone }: { options: PromptOptions; onDone: (value: string | null) => void }) {
  const [value, setValue] = useState(options.initialValue ?? '')
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(true)

  useEffect(() => setError(null), [value])

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const trimmed = value.trim()
    const message = trimmed ? (options.validate?.(trimmed) ?? null) : `${options.label} is required`
    if (message) return setError(message)
    setOpen(false)
    onDone(trimmed)
  }

  return (
    <Modal
      open={open}
      onClose={() => {
        setOpen(false)
        onDone(null)
      }}
      title={options.title}
      size="sm"
    >
      <form onSubmit={submit} className="flex flex-col gap-4">
        <Field label={options.label} error={error ?? undefined}>
          {(props) => (
            <Input
              {...props}
              autoFocus
              data-autofocus
              value={value}
              placeholder={options.placeholder}
              onChange={(e) => setValue(e.target.value)}
              onFocus={(e) => e.currentTarget.select()}
            />
          )}
        </Field>
        <div className="flex justify-end gap-2">
          <Button
            variant="ghost"
            onClick={() => {
              setOpen(false)
              onDone(null)
            }}
          >
            Cancel
          </Button>
          <Button type="submit" variant="primary">
            {options.confirmLabel ?? 'Save'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
