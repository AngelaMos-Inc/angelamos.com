// ===========================
// ©AngelaMos | 2026
// App.tsx
// ===========================

import { RouterProvider } from 'react-router-dom'
import { Toaster } from 'sonner'

import { router } from '@/core/app/routers'
import '@/core/app/toast.module.scss'

export default function App(): React.ReactElement {
  return (
    <div className="app">
      <RouterProvider router={router} />
      <Toaster
        position="top-right"
        duration={2000}
        theme="dark"
        toastOptions={{
          style: {
            background: 'hsl(0, 0%, 12.2%)',
            border: '1px solid hsl(0, 0%, 18%)',
            color: 'hsl(0, 0%, 98%)',
          },
        }}
      />
    </div>
  )
}
