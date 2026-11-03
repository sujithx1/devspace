/**
 * Permission checks for writes. Stores call `checkPermission` before every
 * mutation; the rules themselves are installed by `stores/permissions.ts`,
 * which keeps this module free of imports (and import cycles).
 */

export type Permission = 'content.edit' | 'members.manage' | 'workspace.manage'

export class PermissionError extends Error {
  readonly permission: Permission
  constructor(permission: Permission, message: string) {
    super(message)
    this.name = 'PermissionError'
    this.permission = permission
  }
}

let guard: (permission: Permission) => void = () => {}

export function setPermissionGuard(fn: (permission: Permission) => void) {
  guard = fn
}

/** Throws a `PermissionError` when the acting member may not perform this kind of write. */
export function checkPermission(permission: Permission) {
  guard(permission)
}
