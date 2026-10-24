// ===================
// © AngelaMos | 2026
// socket.ts
// ===================

export interface SocketHandlers {
  onMessage: (data: unknown) => void
  onOpen?: () => void
  onClose?: () => void
}

const BASE_BACKOFF = 1000
const MAX_BACKOFF = 30000

// Opens a self-reconnecting WebSocket to a same-origin path (proxied by nginx).
// Returns a disposer that permanently closes the socket and stops reconnects.
export function openSocket(path: string, handlers: SocketHandlers): () => void {
  let ws: WebSocket | null = null
  let closed = false
  let attempt = 0
  let timer: ReturnType<typeof setTimeout> | undefined

  const resolveUrl = (): string => {
    const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    return `${proto}//${window.location.host}${path}`
  }

  const connect = (): void => {
    if (closed) return
    ws = new WebSocket(resolveUrl())

    ws.onopen = (): void => {
      attempt = 0
      handlers.onOpen?.()
    }

    ws.onmessage = (event: MessageEvent): void => {
      try {
        handlers.onMessage(JSON.parse(event.data as string))
      } catch {
        // ignore malformed frames
      }
    }

    ws.onclose = (): void => {
      handlers.onClose?.()
      if (closed) return
      const delay = Math.min(BASE_BACKOFF * 2 ** attempt, MAX_BACKOFF)
      attempt += 1
      timer = setTimeout(connect, delay)
    }

    ws.onerror = (): void => {
      ws?.close()
    }
  }

  connect()

  return (): void => {
    closed = true
    if (timer) clearTimeout(timer)
    ws?.close()
  }
}
