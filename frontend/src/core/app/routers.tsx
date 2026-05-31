// ===================
// © AngelaMos | 2026
// routers.tsx
// ===================

import { createBrowserRouter, type RouteObject } from 'react-router-dom'
import { ROUTES } from '@/config'
import { Shell } from './shell'

const routes: RouteObject[] = [
  {
    path: ROUTES.HOME,
    lazy: () => import('@/pages/landing'),
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
    path: ROUTES.ARCHIVE,
    lazy: () => import('@/pages/archive'),
  },
  {
    element: <Shell />,
    children: [
      {
        path: ROUTES.DASHBOARD,
        lazy: () => import('@/pages/dashboard'),
      },
      {
        path: ROUTES.SETTINGS,
        lazy: () => import('@/pages/settings'),
      },
    ],
  },
  {
    path: '*',
    lazy: () => import('@/pages/landing'),
  },
]

export const router = createBrowserRouter(routes)
