import type { EntityType } from '@/data'

export const paths = {
  workspace: (ws: string) => `/w/${ws}`,
  notes: (ws: string) => `/w/${ws}/notes`,
  note: (ws: string, id: string) => `/w/${ws}/notes/${id}`,
  docs: (ws: string) => `/w/${ws}/docs`,
  doc: (ws: string, id: string) => `/w/${ws}/docs/${id}`,
  tasks: (ws: string, taskId?: string) => `/w/${ws}/tasks${taskId ? `?task=${taskId}` : ''}`,
  projects: (ws: string) => `/w/${ws}/projects`,
  project: (ws: string, id: string) => `/w/${ws}/projects/${id}`,
  drawings: (ws: string) => `/w/${ws}/drawings`,
  drawing: (ws: string, id: string) => `/w/${ws}/drawings/${id}`,
  search: (ws: string, q = '') => `/w/${ws}/search${q ? `?q=${encodeURIComponent(q)}` : ''}`,
  settings: (ws: string) => `/w/${ws}/settings`,
}

export function entityPath(ws: string, type: EntityType, id: string): string {
  switch (type) {
    case 'note':
      return paths.note(ws, id)
    case 'doc':
      return paths.doc(ws, id)
    case 'task':
      return paths.tasks(ws, id)
    case 'project':
      return paths.project(ws, id)
    case 'drawing':
      return paths.drawing(ws, id)
  }
}
