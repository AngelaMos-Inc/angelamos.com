// ===================
// © AngelaMos | 2026
// useRepoStats.ts
// ===================

import { useQuery } from '@tanstack/react-query'
import { API_ENDPOINTS, QUERY_KEYS } from '@/config'
import { apiClient } from '@/core/api'
import type { RepoStats } from '../types'

export function useRepoStats() {
  return useQuery({
    queryKey: QUERY_KEYS.GITHUB.STARS,
    queryFn: async (): Promise<RepoStats> => {
      const { data } = await apiClient.get<RepoStats>(
        API_ENDPOINTS.GITHUB.STARS
      )
      return data
    },
    staleTime: 5 * 60_000,
    refetchInterval: 10 * 60_000,
    retry: false,
  })
}
