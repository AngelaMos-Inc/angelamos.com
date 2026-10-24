// ===================
// © AngelaMos | 2026
// useSubmitContact.ts
// ===================

import { useMutation } from '@tanstack/react-query'
import { API_ENDPOINTS } from '@/config'
import { apiClient } from '@/core/api'
import type { ContactResult, ContactSubmit } from '../types'

export function useSubmitContact() {
  return useMutation({
    mutationFn: async (input: ContactSubmit): Promise<ContactResult> => {
      const { data } = await apiClient.post<ContactResult>(
        API_ENDPOINTS.CONTACT.BASE,
        input
      )
      return data
    },
  })
}
