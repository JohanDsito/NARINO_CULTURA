import { useAuthStore } from '@/store/authStore'
import { EventCalendar } from '@/components/events'

export default function EventsPage() {
  const user = useAuthStore((s) => s.user)
  const canCreate = user?.role === 'admin' || user?.role === 'cultural_manager'

  return (
    <div className="min-h-screen bg-bg pt-16">
      <main className="mx-auto max-w-6xl px-6 py-8">
        <EventCalendar showCreateButton={canCreate} />
      </main>
    </div>
  )
}
