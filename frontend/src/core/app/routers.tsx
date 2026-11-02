// ===================
// © AngelaMos | 2026
// routers.tsx
// ===================

import { createBrowserRouter, type RouteObject } from 'react-router-dom'
import { ROUTES } from '@/config'
import { ThemeLayout } from './theme-layout'

const routes: RouteObject[] = [
  {
    path: ROUTES.HOME,
    lazy: () => import('@/pages/landing'),
  },
  {
    path: ROUTES.COMPANY,
    lazy: () => import('@/pages/company'),
  },
  {
    path: ROUTES.CONTACT,
    lazy: () => import('@/pages/contact'),
  },
  {
    path: ROUTES.INDEX,
    lazy: () => import('@/pages/registry'),
  },
  {
    path: ROUTES.WORK,
    lazy: () => import('@/pages/work-with-me'),
  },
  {
    path: '*',
    lazy: () => import('@/pages/not-found'),
  },
]

export const router = createBrowserRouter([
  { element: <ThemeLayout />, children: routes },
])
