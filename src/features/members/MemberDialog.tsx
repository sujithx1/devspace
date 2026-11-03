import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/Button'
import { Field, Input, Select } from '@/components/ui/Field'
import { Modal } from '@/components/ui/Modal'
import { MEMBER_ROLES, ValidationError, type Member, type MemberRole } from '@/data'
import { MEMBER_ROLE_META } from '@/lib/meta'
import { toast } from '@/stores/toastStore'
import { addMember, updateMember } from './memberActions'

interface Props {
  open: boolean
  onClose: () => void
  workspaceId: string
  /** When set, edits this member; otherwise adds a new one. */
  member?: Member
}

export function MemberDialog({ open, onClose, workspaceId, member }: Props) {
  return (
    <Modal open={open} onClose={onClose} title={member ? 'Edit member' : 'Add member'} size="sm">
      {open && <MemberForm key={member?.id ?? 'new'} workspaceId={workspaceId} member={member} onDone={onClose} />}
    </Modal>
  )
}

function MemberForm({ workspaceId, member, onDone }: { workspaceId: string; member?: Member; onDone: () => void }) {
  const [name, setName] = useState(member?.name ?? '')
  const [email, setEmail] = useState(member?.email ?? '')
  const [role, setRole] = useState<MemberRole>(member?.role ?? 'editor')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState(false)

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return setErrors({ name: 'Member name is required' })
    setSaving(true)
    try {
      if (member) {
        await updateMember(member.id, { name, email, role })
        toast.success('Member updated')
      } else {
        await addMember({ workspaceId, name, email, role })
      }
      onDone()
    } catch (error) {
      if (error instanceof ValidationError) setErrors(error.fieldErrors)
      else toast.error(error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      <Field label="Name" error={errors.name}>
        {(p) => (
          <Input
            {...p}
            autoFocus
            data-autofocus
            value={name}
            maxLength={60}
            placeholder="e.g. Priya Sharma"
            onChange={(e) => {
              setName(e.target.value)
              setErrors((x) => ({ ...x, name: '' }))
            }}
          />
        )}
      </Field>
      <Field label="Email (optional)" error={errors.email}>
        {(p) => (
          <Input
            {...p}
            type="email"
            value={email}
            maxLength={120}
            placeholder="priya@company.com"
            onChange={(e) => {
              setEmail(e.target.value)
              setErrors((x) => ({ ...x, email: '' }))
            }}
          />
        )}
      </Field>
      <Field label="Role" error={errors.role} hint={MEMBER_ROLE_META[role].description}>
        {(p) => (
          <Select
            {...p}
            value={role}
            onChange={(e) => {
              setRole(e.target.value as MemberRole)
              setErrors((x) => ({ ...x, role: '' }))
            }}
          >
            {MEMBER_ROLES.map((r) => (
              <option key={r} value={r}>
                {MEMBER_ROLE_META[r].label}
              </option>
            ))}
          </Select>
        )}
      </Field>
      <div className="flex justify-end gap-2 pt-1">
        <Button variant="ghost" onClick={onDone}>
          Cancel
        </Button>
        <Button type="submit" variant="primary" loading={saving}>
          {member ? 'Save' : 'Add member'}
        </Button>
      </div>
    </form>
  )
}
