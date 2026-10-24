// ===================
// © AngelaMos | 2026
// social.types.ts
// ===================

export interface SocialStats {
  followers: number
  media: number
  configured: boolean
  updatedAt: string
}

export function isSocialStats(value: unknown): value is SocialStats {
  if (typeof value !== 'object' || value === null) return false
  const v = value as Record<string, unknown>
  return (
    typeof v.followers === 'number' &&
    typeof v.media === 'number' &&
    typeof v.configured === 'boolean'
  )
}
