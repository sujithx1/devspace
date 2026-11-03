import type { Task, TaskInput, TaskStatus } from '@/data'
import { useTasksStore } from '@/stores/collections'
import { confirmDialog } from '@/stores/dialogStore'
import { useRecentsStore } from '@/stores/recentsStore'
import { toast } from '@/stores/toastStore'
import { groupByStatus, topOrder } from './taskLogic'

/** Creates a task at the top of its column. Throws on validation errors so forms can show them. */
export async function createTask(input: TaskInput): Promise<Task> {
  const store = useTasksStore.getState()
  const status = input.status ?? 'todo'
  const column = groupByStatus(store.items)[status]
  const task = await store.create({ ...input, status, order: input.order ?? topOrder(column) })
  toast.success('Task created')
  return task
}

export async function updateTask(id: string, patch: Partial<TaskInput>): Promise<Task | null> {
  try {
    return await useTasksStore.getState().update(id, patch)
  } catch (error) {
    toast.error(error, 'Could not update task')
    return null
  }
}

/** Moves a task to another status column, placing it at the top. */
export function moveTask(task: Task, status: TaskStatus) {
  if (task.status === status) return
  const column = groupByStatus(useTasksStore.getState().items)[status]
  return updateTask(task.id, { status, order: topOrder(column) })
}

export async function deleteTask(task: Task, { skipConfirm = false } = {}): Promise<boolean> {
  if (
    !skipConfirm &&
    !(await confirmDialog({ title: 'Delete task?', description: `“${task.title}” will be permanently deleted.`, confirmLabel: 'Delete', destructive: true }))
  ) {
    return false
  }
  try {
    await useTasksStore.getState().remove(task.id)
    useRecentsStore.getState().forget('task', task.id)
    toast.success('Task deleted')
    return true
  } catch (error) {
    toast.error(error, 'Could not delete task')
    return false
  }
}
