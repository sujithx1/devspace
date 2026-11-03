import { DevSpaceDB } from './dexie/db'
import { createDexieRepositories } from './dexie/repositories'
import type { Repositories } from './repositories'

/**
 * Single composition point for the data layer. Swap this for an HTTP-backed
 * implementation of `Repositories` to move DevSpace onto a backend; nothing
 * else in the app imports Dexie directly.
 */
export function createRepositories(): Repositories {
  return createDexieRepositories(new DevSpaceDB())
}

export const repositories: Repositories = createRepositories()

export * from './models'
export * from './errors'
export type * from './repositories'
