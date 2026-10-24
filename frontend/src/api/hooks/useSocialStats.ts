// ===================
// © AngelaMos | 2026
// useSocialStats.ts
// ===================

import { useQuery } from '@tanstack/react-query'
import { API_ENDPOINTS, QUERY_KEYS } from '@/config'
import { apiClient } from '@/core/api'
import type { SocialStats } from '../types'

export function useSocialStats() {
  return useQuery({
    queryKey: QUERY_KEYS.SOCIAL.STATS,
    queryFn: async (): Promise<SocialStats> => {
      const { data } = await apiClient.get<SocialStats>(
        API_ENDPOINTS.SOCIAL.STATS
      )
      return data
    },
    staleTime: 60_000,
    refetchInterval: 5 * 60_000,
  })
}
