import { SHORTCUTS } from '@/lib/shortcuts'
import { useUIStore } from '@/stores/uiStore'
import { Modal } from '../ui/Modal'
import { Kbd } from '../ui/States'

export function ShortcutsDialog() {
  const open = useUIStore((s) => s.shortcutsOpen)
  const setOpen = useUIStore((s) => s.setShortcutsOpen)
  return (
    <Modal open={open} onClose={() => setOpen(false)} title="Keyboard shortcuts" size="lg">
      <div className="grid gap-6 sm:grid-cols-2">
        {SHORTCUTS.map((group) => (
          <section key={group.group}>
            <h3 className="mb-2 text-[11px] font-medium tracking-wider text-fg-subtle uppercase">{group.group}</h3>
            <ul className="flex flex-col gap-1.5">
              {group.items.map((item) => (
                <li key={item.label} className="flex items-center justify-between gap-4 text-sm">
                  <span className="text-fg-muted">{item.label}</span>
                  <span className="flex gap-1">
                    {item.keys.map((k) => (
                      <Kbd key={k}>{k}</Kbd>
                    ))}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>
    </Modal>
  )
}
