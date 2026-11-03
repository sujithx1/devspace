import type {
  Doc,
  Drawing,
  DrawingInput,
  EntityType,
  Folder,
  FolderInput,
  Member,
  MemberInput,
  Note,
  PageInput,
  Project,
  ProjectInput,
  RecentVisit,
  Task,
  TaskInput,
  Workspace,
  WorkspaceInput,
} from './models'

/**
 * Storage-agnostic repository contracts.
 *
 * The UI talks to these interfaces only. Today they are backed by IndexedDB
 * (see ./dexie); a future HTTP implementation only needs to satisfy the same
 * contracts and be returned from `createRepositories` in ./index.ts.
 */

export interface CollectionRepository<T, CreateInput, UpdateInput = Partial<CreateInput>> {
  listByWorkspace(workspaceId: string): Promise<T[]>
  get(id: string): Promise<T | undefined>
  create(input: CreateInput): Promise<T>
  update(id: string, patch: UpdateInput): Promise<T>
  remove(id: string): Promise<void>
}

export interface WorkspaceRepository {
  list(): Promise<Workspace[]>
  get(id: string): Promise<Workspace | undefined>
  create(input: WorkspaceInput): Promise<Workspace>
  update(id: string, patch: Partial<WorkspaceInput>): Promise<Workspace>
  /** Removes the workspace and everything inside it. */
  remove(id: string): Promise<void>
}

export type MemberRepository = CollectionRepository<Member, MemberInput, Partial<Omit<MemberInput, 'workspaceId'>>>
export type FolderRepository = CollectionRepository<Folder, FolderInput, Pick<FolderInput, 'name'>>
export type NoteRepository = CollectionRepository<Note, PageInput>
export type DocRepository = CollectionRepository<Doc, PageInput>
export type TaskRepository = CollectionRepository<Task, TaskInput>
export type ProjectRepository = CollectionRepository<Project, ProjectInput>
export type DrawingRepository = CollectionRepository<Drawing, DrawingInput>

export interface RecentRepository {
  listByWorkspace(workspaceId: string, limit?: number): Promise<RecentVisit[]>
  touch(workspaceId: string, entityType: EntityType, entityId: string): Promise<RecentVisit>
  forget(entityType: EntityType, entityId: string): Promise<void>
}

export interface Repositories {
  workspaces: WorkspaceRepository
  members: MemberRepository
  folders: FolderRepository
  notes: NoteRepository
  docs: DocRepository
  tasks: TaskRepository
  projects: ProjectRepository
  drawings: DrawingRepository
  recents: RecentRepository
}
