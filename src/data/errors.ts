import { ZodError } from 'zod'

/** Thrown when user input fails schema validation. `message` is safe to show to users. */
export class ValidationError extends Error {
  readonly fieldErrors: Record<string, string>

  constructor(message: string, fieldErrors: Record<string, string> = {}) {
    super(message)
    this.name = 'ValidationError'
    this.fieldErrors = fieldErrors
  }

  static fromZod(error: ZodError): ValidationError {
    const fieldErrors: Record<string, string> = {}
    for (const issue of error.issues) {
      const key = issue.path.join('.') || '_'
      if (!fieldErrors[key]) fieldErrors[key] = issue.message
    }
    return new ValidationError(error.issues[0]?.message ?? 'Invalid input', fieldErrors)
  }
}

export class NotFoundError extends Error {
  constructor(entity: string, id: string) {
    super(`${entity} not found (${id})`)
    this.name = 'NotFoundError'
  }
}

/** Converts any thrown value into a message suitable for a toast. */
export function errorMessage(error: unknown, fallback = 'Something went wrong'): string {
  if (error instanceof ValidationError || error instanceof NotFoundError) return error.message
  if (error instanceof ZodError) return ValidationError.fromZod(error).message
  if (error instanceof Error && error.name === 'QuotaExceededError') {
    return 'Browser storage is full. Remove large images or drawings and try again.'
  }
  if (error instanceof Error && error.message) return error.message
  return fallback
}
