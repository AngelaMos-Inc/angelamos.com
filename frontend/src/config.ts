// ===================
// © AngelaMos | 2026
// config.ts
// ===================
const API_VERSION = 'v1'

export const API_ENDPOINTS = {
  HEALTH: {
    LIVE: '/healthz',
    READY: '/readyz',
  },
  USERS: {
    BASE: `/${API_VERSION}/users`,
    BY_ID: (id: string) => `/${API_VERSION}/users/${id}`,
  },
  CONTACT: {
    BASE: `/${API_VERSION}/contact`,
  },
  SOCIAL: {
    STATS: `/${API_VERSION}/social/stats`,
  },
  GITHUB: {
    STARS: `/${API_VERSION}/github/stars`,
  },
} as const

export const QUERY_KEYS = {
  HEALTH: {
    READY: ['health', 'ready'] as const,
  },
  USERS: {
    ALL: ['users'] as const,
    BY_ID: (id: string) => [...QUERY_KEYS.USERS.ALL, 'detail', id] as const,
  },
  SOCIAL: {
    STATS: ['social', 'stats'] as const,
  },
  GITHUB: {
    STARS: ['github', 'stars'] as const,
  },
} as const

export const ROUTES = {
  HOME: '/',
  COMPANY: '/company',
  CONTACT: '/contact',
  INDEX: '/index',
  WORK: '/work-with-me',
  DASHBOARD: '/dashboard',
  SETTINGS: '/settings',
} as const

export const STORAGE_KEYS = {
  UI: 'ui-storage',
} as const

export const QUERY_CONFIG = {
  STALE_TIME: {
    USER: 1000 * 60 * 5,
    STATIC: Infinity,
    FREQUENT: 1000 * 30,
  },
  GC_TIME: {
    DEFAULT: 1000 * 60 * 30,
    LONG: 1000 * 60 * 60,
  },
  RETRY: {
    DEFAULT: 3,
    NONE: 0,
  },
} as const

export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER: 500,
} as const

export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_SIZE: 20,
  MAX_SIZE: 100,
} as const

export type ApiEndpoint = typeof API_ENDPOINTS
export type QueryKey = typeof QUERY_KEYS
export type Route = typeof ROUTES
