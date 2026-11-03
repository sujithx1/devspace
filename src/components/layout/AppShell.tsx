import { Outlet } from 'react-router'
import { RoleBanner } from '@/features/members/ActingAs'
import { ProjectDialogHost } from '@/features/projects/ProjectDialog'
import { TaskDialogHost } from '@/features/tasks/TaskDialog'
import { CommandPalette } from './CommandPalette'
import { ShortcutsDialog } from './ShortcutsDialog'
import { Sidebar } from './Sidebar'
import { useGlobalShortcuts } from './useGlobalShortcuts'

export function AppShell() {
  useGlobalShortcuts()
  return (
    <div className="flex h-full overflow-hidden">
      <a href="#main" className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:rounded-md focus:bg-accent focus:px-3 focus:py-1.5 focus:text-accent-fg">
        Skip to content
      </a>
      <Sidebar />
      <main id="main" className="flex min-w-0 flex-1 flex-col overflow-hidden bg-canvas">
        <RoleBanner />
        <Outlet />
      </main>
      <CommandPalette />
      <ShortcutsDialog />
      <TaskDialogHost />
      <ProjectDialogHost />
    </div>
  )
}
