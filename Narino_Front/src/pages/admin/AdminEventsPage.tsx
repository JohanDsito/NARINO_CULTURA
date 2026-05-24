import { useAuthStore } from '@/store/authStore'
import { EventCalendar } from '@/components/events'

export default function AdminEventsPage() {
  const user = useAuthStore((s) => s.user)
  const isAdmin = user?.role === 'admin'

  return (
    <div className="min-h-screen bg-bg pt-16">
      <main className="mx-auto max-w-6xl px-6 py-8">
        <EventCalendar showCreateButton={isAdmin} />
      </main>
    </div>
  )
}
