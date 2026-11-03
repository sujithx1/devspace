import { describe, expect, it } from 'vitest'
import type { Task } from '@/data'
import { projectProgress, scheduleLabel } from './projectLogic'

const t = (projectId: string | null, status: Task['status']) => ({ projectId, status }) as Task

describe('project logic', () => {
  it('computes progress from linked tasks only', () => {
    const tasks = [t('p', 'completed'), t('p', 'todo'), t('p', 'in_progress'), t('p', 'completed'), t('x', 'completed')]
    expect(projectProgress('p', tasks)).toEqual({ total: 4, completed: 2, percent: 50 })
    expect(projectProgress('none', tasks)).toEqual({ total: 0, completed: 0, percent: 0 })
  })

  it('labels schedules', () => {
    expect(scheduleLabel({ dueDate: null, status: 'active' })).toBeNull()
    expect(scheduleLabel({ dueDate: '2026-11-01', status: 'active' }, '2026-11-02')).toEqual({ label: '1d overdue', overdue: true })
    expect(scheduleLabel({ dueDate: '2026-11-07', status: 'active' }, '2026-11-02')).toEqual({ label: 'Due in 5d', overdue: false })
    expect(scheduleLabel({ dueDate: '2026-11-01', status: 'completed' }, '2026-11-02')?.overdue).toBe(false)
  })
})
