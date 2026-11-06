import { Outlet } from 'react-router-dom'

import { Navbar } from '@/components/layout/navbar'
import { Footer } from '@/components/layout/footer'
import { ErrorBoundary } from '@/components/layout/error-boundary'
import { ChatbotWidget } from '@/components/ai/chatbot-widget'

export function AppLayout() {
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      <main className="flex-1">
        <ErrorBoundary>
          <Outlet />
        </ErrorBoundary>
      </main>
      <Footer />
      <ChatbotWidget />
    </div>
  )
}

