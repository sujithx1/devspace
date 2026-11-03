import { lazy, useEffect } from 'react'
import { createBrowserRouter, Link, RouterProvider, useRouteError } from 'react-router'
import { DialogHost } from '@/components/ui/DialogHost'
import { MenuHost } from '@/components/ui/MenuHost'
import { ErrorState } from '@/components/ui/States'
import { Toaster } from '@/components/ui/Toaster'
import { errorMessage } from '@/data'
import { DashboardPage } from '@/features/dashboard/DashboardPage'
import { DrawingEditorPage } from '@/features/drawings/DrawingEditorPage'
import { DrawingsPage } from '@/features/drawings/DrawingsPage'
import { PagesLayout } from '@/features/pages/PagesLayout'
import { PageIndex } from '@/features/pages/PageIndex'
import { ProjectDetailPage } from '@/features/projects/ProjectDetailPage'
import { ProjectsPage } from '@/features/projects/ProjectsPage'
import { SearchPage } from '@/features/search/SearchPage'
import { SettingsPage } from '@/features/settings/SettingsPage'
import { TasksPage } from '@/features/tasks/TasksPage'
import { OnboardingPage } from '@/features/workspaces/OnboardingPage'
import { RootRedirect } from '@/features/workspaces/RootRedirect'
import { WorkspaceLayout } from '@/features/workspaces/WorkspaceLayout'
import { useUIStore } from '@/stores/uiStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'

// The rich-text editor (Tiptap + syntax highlighting) is the heaviest part of the app shell; load it on demand.
const PageEditorRoute = lazy(() => import('@/features/pages/PageEditor').then((m) => ({ default: m.PageEditorRoute })))

function RouteError() {
  const error = useRouteError()
  return (
    <div className="flex h-full items-center justify-center">
      <ErrorState message={errorMessage(error, 'This page failed to load.')} onRetry={() => window.location.reload()} />
    </div>
  )
}

function NotFound() {
  return (
    <div className="flex h-full flex-col items-center justify-center gap-3 p-6 text-center">
      <p className="text-5xl font-bold text-fg-subtle">404</p>
      <h1 className="text-lg font-semibold">Page not found</h1>
      <Link to="/" className="text-sm font-medium text-accent hover:underline">
        Back to DevSpace
      </Link>
    </div>
  )
}

const router = createBrowserRouter([
  { path: '/', element: <RootRedirect />, errorElement: <RouteError /> },
  { path: '/welcome', element: <OnboardingPage />, errorElement: <RouteError /> },
  {
    path: '/w/:workspaceId',
    element: <WorkspaceLayout />,
    errorElement: <RouteError />,
    children: [
      { index: true, element: <DashboardPage /> },
      {
        path: 'notes',
        element: <PagesLayout kind="note" />,
        children: [
          { index: true, element: <PageIndex kind="note" /> },
          { path: ':pageId', element: <PageEditorRoute kind="note" /> },
        ],
      },
      {
        path: 'docs',
        element: <PagesLayout kind="doc" />,
        children: [
          { index: true, element: <PageIndex kind="doc" /> },
          { path: ':pageId', element: <PageEditorRoute kind="doc" /> },
        ],
      },
      { path: 'tasks', element: <TasksPage /> },
      { path: 'projects', element: <ProjectsPage /> },
      { path: 'projects/:projectId', element: <ProjectDetailPage /> },
      { path: 'drawings', element: <DrawingsPage /> },
      { path: 'drawings/:drawingId', element: <DrawingEditorPage /> },
      { path: 'search', element: <SearchPage /> },
      { path: 'settings', element: <SettingsPage /> },
      { path: '*', element: <NotFound /> },
    ],
  },
  { path: '*', element: <NotFound /> },
])

export default function App() {
  const init = useWorkspaceStore((s) => s.init)
  const syncSystemTheme = useUIStore((s) => s.syncSystemTheme)

  useEffect(() => {
    void init()
  }, [init])

  useEffect(() => {
    const media = matchMedia('(prefers-color-scheme: dark)')
    media.addEventListener('change', syncSystemTheme)
    return () => media.removeEventListener('change', syncSystemTheme)
  }, [syncSystemTheme])

  return (
    <>
      <RouterProvider router={router} />
      <MenuHost />
      <DialogHost />
      <Toaster />
    </>
  )
}
