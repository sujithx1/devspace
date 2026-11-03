import { Plus } from 'lucide-react'
import { useNavigate } from 'react-router'
import { Button } from '@/components/ui/Button'
import { EmptyState } from '@/components/ui/States'
import { useCan } from '@/stores/permissions'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { createPage } from './pageActions'
import { PAGE_KINDS, type PageKind } from './pageKinds'

/** Shown in the right pane when no page is open. */
export function PageIndex({ kind }: { kind: PageKind }) {
  const config = PAGE_KINDS[kind]
  const ws = useWorkspaceId()
  const navigate = useNavigate()
  const count = config.useStore((s) => s.items.length)
  const canEdit = useCan('content.edit')
  return (
    <div className="flex flex-1 items-center justify-center">
      <EmptyState
        icon={config.icon}
        title={count ? `Select a ${config.label.toLowerCase()}` : config.emptyTitle}
        description={count ? (canEdit ? 'Choose one from the list, or start something new.' : 'Choose one from the list to read it.') : config.emptyDescription}
        action={
          canEdit && (
            <Button
              variant="primary"
              onClick={async () => {
                const page = await createPage(kind, ws)
                if (page) navigate(config.itemPath(ws, page.id))
              }}
            >
              <Plus className="size-4" /> New {config.label.toLowerCase()}
            </Button>
          )
        }
      />
    </div>
  )
}
