import { Suspense } from 'react'
import { Outlet, useParams } from 'react-router'
import { Spinner } from '@/components/ui/States'
import { cn } from '@/lib/utils'
import type { PageKind } from './pageKinds'
import { PageList } from './PageList'

/** Two-pane layout: list of pages (with folders) on the left, the open page on the right. */
export function PagesLayout({ kind }: { kind: PageKind }) {
  const { pageId } = useParams()
  return (
    <div className="flex min-h-0 flex-1">
      <aside className={cn('min-h-0 w-full shrink-0 flex-col border-r border-line bg-surface md:flex md:w-72 lg:w-80', pageId ? 'hidden' : 'flex')}>
        <PageList kind={kind} activeId={pageId} />
      </aside>
      <section className={cn('min-h-0 min-w-0 flex-1 flex-col', pageId ? 'flex' : 'hidden md:flex')}>
        <Suspense
          fallback={
            <div className="flex flex-1 items-center justify-center">
              <Spinner />
            </div>
          }
        >
          <Outlet />
        </Suspense>
      </section>
    </div>
  )
}
