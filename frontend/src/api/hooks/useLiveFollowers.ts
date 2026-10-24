// ===================
// © AngelaMos | 2026
// useLiveFollowers.ts
// ===================

import { useEffect, useState } from 'react'
import { QUERY_KEYS } from '@/config'
import { queryClient } from '@/core/api'
import { openSocket } from '@/core/realtime'
import { isSocialStats, type SocialStats } from '../types'
import { useSocialStats } from './useSocialStats'

const WS_PATH = '/api/ws'

// Snapshot query kept live by the WebSocket: the server pushes the current
// stats on connect and on every change, which we write straight into the
// react-query cache so useSocialStats consumers re-render in real time.
export function useLiveFollowers() {
  const query = useSocialStats()
  const [isLive, setIsLive] = useState(false)

  useEffect(() => {
    const close = openSocket(WS_PATH, {
      onOpen: () => setIsLive(true),
      onClose: () => setIsLive(false),
      onMessage: (data) => {
        if (isSocialStats(data)) {
          queryClient.setQueryData<SocialStats>(QUERY_KEYS.SOCIAL.STATS, data)
        }
      },
    })
    return close
  }, [])

  return {
    ...query,
    isLive,
    stats: query.data,
    followers: query.data?.followers ?? null,
  }
}
