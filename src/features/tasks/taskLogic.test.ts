import { describe, expect, it } from 'vitest'
import type { Task } from '@/data'
import { DEFAULT_TASK_FILTERS, dueLabel, filterTasks, groupByStatus, orderForInsert, taskStats, topOrder } from './taskLogic'

let n = 0
const task = (over: Partial<Task> = {}): Task => ({
  id: `t${++n}`,
  workspaceId: 'w',
  projectId: null,
  assigneeId: null,
  title: 'Task',
  description: '',
  status: 'todo',
  priority: 'medium',
  dueDate: null,
  order: 0,
  completedAt: null,
  createdAt: n,
  updatedAt: n,
  ...over,
})

describe('task ordering', () => {
  it('groups by status sorted by order', () => {
    const a = task({ order: 2 })
    const b = task({ order: 1 })
    const c = task({ status: 'completed' })
    const groups = groupByStatus([a, b, c])
    expect(groups.todo.map((t) => t.id)).toEqual([b.id, a.id])
    expect(groups.completed).toEqual([c])
    expect(groups.in_progress).toEqual([])
  })

  it('computes insert positions between, before and after cards', () => {
    const col = [task({ order: 0 }), task({ order: 1024 }), task({ order: 2048 })]
    expect(orderForInsert([], null)).toBe(0)
    expect(orderForInsert(col, null)).toBe(3072)
    expect(orderForInsert(col, col[1].id)).toBe(512)
    expect(orderForInsert(col, col[0].id)).toBeLessThan(0)
    expect(topOrder(col)).toBeLessThan(0)
  })
})

describe('task filters', () => {
  const today = '2026-11-02'
  const tasks = [
    task({ title: 'Fix login bug', priority: 'urgent', dueDate: '2026-11-01' }),
    task({ title: 'Write docs', description: 'API reference', dueDate: '2026-11-02' }),
    task({ title: 'Refactor', dueDate: '2026-11-08', projectId: 'p1' }),
    task({ title: 'Old done', status: 'completed', dueDate: '2026-10-01' }),
  ]

  it('searches title and description', () => {
    expect(filterTasks(tasks, { ...DEFAULT_TASK_FILTERS, query: 'api' }, today).map((t) => t.title)).toEqual(['Write docs'])
  })

  it('filters by due window, priority and project', () => {
    const titles = (f: Partial<typeof DEFAULT_TASK_FILTERS>) => filterTasks(tasks, { ...DEFAULT_TASK_FILTERS, ...f }, today).map((t) => t.title)
    expect(titles({ due: 'overdue' })).toEqual(['Fix login bug'])
    expect(titles({ due: 'today' })).toEqual(['Write docs'])
    expect(titles({ due: 'week' })).toEqual(['Write docs', 'Refactor'])
    expect(titles({ priority: 'urgent' })).toEqual(['Fix login bug'])
    expect(titles({ projectId: 'p1' })).toEqual(['Refactor'])
  })

  it('filters by assignee', () => {
    const assigned = [task({ title: 'Mine', assigneeId: 'm1' }), task({ title: 'Theirs', assigneeId: 'm2' }), task({ title: 'Nobody' })]
    const titles = (assignee: string) => filterTasks(assigned, { ...DEFAULT_TASK_FILTERS, assignee }, today).map((t) => t.title)
    expect(titles('any')).toEqual(['Mine', 'Theirs', 'Nobody'])
    expect(titles('unassigned')).toEqual(['Nobody'])
    expect(titles('m1')).toEqual(['Mine'])
  })

  it('computes stats and due labels', () => {
    expect(taskStats(tasks, today)).toMatchObject({ total: 4, completed: 1, todo: 3, overdue: 1, completionRate: 25 })
    expect(dueLabel('2026-11-02', today)).toBe('Today')
    expect(dueLabel('2026-11-03', today)).toBe('Tomorrow')
    expect(dueLabel('2026-10-30', today)).toBe('3d overdue')
  })
})
