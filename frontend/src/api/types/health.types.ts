// ===================
// © AngelaMos | 2026
// health.types.ts
// ===================

export interface HealthCheck {
  name: string
  healthy: boolean
  latency?: string
  message?: string
}

export interface HealthStatus {
  status: string
  checks?: HealthCheck[]
}
