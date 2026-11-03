import { DevSpaceDB } from '@/data/dexie/db'
import { createDexieRepositories } from '@/data/dexie/repositories'

let counter = 0

/** Fresh, isolated repositories backed by an in-memory IndexedDB. */
export function createTestRepositories() {
  const db = new DevSpaceDB(`devspace-test-${Date.now()}-${counter++}`)
  return { db, repos: createDexieRepositories(db) }
}
