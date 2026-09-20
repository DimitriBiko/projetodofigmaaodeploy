/** Helpers de compartilhamento nativo / fallback clipboard. */

export async function shareContent(input: {
  title: string
  text?: string
  url?: string
}): Promise<'shared' | 'copied' | 'cancelled'> {
  const payload = {
    title: input.title,
    text: input.text ?? input.title,
    url: input.url ?? (typeof window !== 'undefined' ? window.location.href : ''),
  }

  try {
    if (typeof navigator !== 'undefined' && typeof navigator.share === 'function') {
      await navigator.share(payload)
      return 'shared'
    }
  } catch (err) {
    // AbortError = usuário cancelou
    if (err instanceof DOMException && err.name === 'AbortError') return 'cancelled'
  }

  try {
    const text = [payload.title, payload.text, payload.url].filter(Boolean).join('\n')
    await navigator.clipboard.writeText(text)
    return 'copied'
  } catch {
    return 'cancelled'
  }
}
