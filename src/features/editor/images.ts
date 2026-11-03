const MAX_IMAGE_BYTES = 3 * 1024 * 1024

/** Reads an image file into a data URL so it can be stored with the page locally. */
export function readImageFile(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    if (!file.type.startsWith('image/')) return reject(new Error('Only image files can be inserted'))
    if (file.size > MAX_IMAGE_BYTES) return reject(new Error('Images must be 3 MB or smaller'))
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result))
    reader.onerror = () => reject(new Error('Could not read image'))
    reader.readAsDataURL(file)
  })
}

export function isValidUrl(value: string, protocols = ['http:', 'https:', 'mailto:']): boolean {
  try {
    return protocols.includes(new URL(value).protocol)
  } catch {
    return false
  }
}

/** Adds https:// to bare domains like "example.com/docs". */
export function normalizeUrl(value: string): string {
  const trimmed = value.trim()
  if (/^[a-z][a-z0-9+.-]*:/i.test(trimmed)) return trimmed
  return `https://${trimmed}`
}
