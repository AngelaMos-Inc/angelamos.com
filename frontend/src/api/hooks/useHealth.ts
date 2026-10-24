// ===================
// © AngelaMos | 2026
// useHealth.ts
// ===================

import { useQuery } from '@tanstack/react-query'
import { API_ENDPOINTS, QUERY_KEYS } from '@/config'
import { apiClient } from '@/core/api'
import type { HealthStatus } from '../types'

export function useHealth() {
  return useQuery({
    queryKey: QUERY_KEYS.HEALTH.READY,
    queryFn: async (): Promise<HealthStatus> => {
      const { data } = await apiClient.get<HealthStatus>(
        API_ENDPOINTS.HEALTH.READY
      )
      return data
    },
    staleTime: 30_000,
    retry: false,
  })
}
