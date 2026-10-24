// ===================
// © AngelaMos | 2026
// api.config.ts
// ===================

import axios, { type AxiosError, type AxiosInstance } from 'axios'
import { ApiError, ApiErrorCode, transformAxiosError } from './errors'

const getBaseURL = (): string => {
  return import.meta.env.VITE_API_URL ?? '/api'
}

export const apiClient: AxiosInstance = axios.create({
  baseURL: getBaseURL(),
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,
})

interface Envelope<T> {
  success: boolean
  data?: T
  error?: { code?: string; message?: string }
}

const isEnvelope = (body: unknown): body is Envelope<unknown> =>
  typeof body === 'object' && body !== null && 'success' in body

// The Go API wraps /v1 responses as { success, data, error }. Unwrap so callers
// receive the bare payload; raw responses (e.g. /healthz) pass through untouched.
apiClient.interceptors.response.use(
  (response) => {
    const body: unknown = response.data
    if (isEnvelope(body)) {
      if (body.success === false) {
        throw new ApiError(
          body.error?.message ?? 'Request failed',
          ApiErrorCode.SERVER_ERROR,
          response.status
        )
      }
      response.data = body.data
    }
    return response
  },
  (error: AxiosError) => Promise.reject(transformAxiosError(error))
)
