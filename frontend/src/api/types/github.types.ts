// ===================
// © AngelaMos | 2026
// github.types.ts
// ===================

export interface RepoStats {
  stars: number
  forks: number
  available: boolean
  updatedAt: string
}

export function isRepoStats(value: unknown): value is RepoStats {
  if (typeof value !== 'object' || value === null) return false
  const v = value as Record<string, unknown>
  return (
    typeof v.stars === 'number' &&
    typeof v.forks === 'number' &&
    typeof v.available === 'boolean'
  )
}
