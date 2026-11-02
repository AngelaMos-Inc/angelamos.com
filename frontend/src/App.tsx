// ===========================
// ©AngelaMos | 2026
// App.tsx
// ===========================

import { QueryClientProvider } from '@tanstack/react-query'
import { RouterProvider } from 'react-router-dom'

import { queryClient } from '@/core/api'
import { router } from '@/core/app/routers'
import '@/core/app/toast.module.scss'

export default function App(): React.ReactElement {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="app">
        <RouterProvider router={router} />
      </div>
    </QueryClientProvider>
  )
}
