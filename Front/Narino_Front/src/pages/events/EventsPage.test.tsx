import { describe, it, expect, vi, beforeEach } from 'vitest'
import { screen } from '@testing-library/react'

import EventsPage from '@/pages/events/EventsPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

vi.mock('@/components/events', () => ({
  EventCalendar: ({ showCreateButton }: { showCreateButton: boolean }) => <div>calendario:{String(showCreateButton)}</div>,
}))

describe('EventsPage', () => {
  beforeEach(() => useAuthStore.setState({ user: null }))

  it.each([
    ['admin', 'true'],
    ['cultural_manager', 'true'],
    ['buyer', 'false'],
    ['artist', 'false'],
  ])('rol %s: ofrece crear eventos = %s', (role, expected) => {
    useAuthStore.setState({ user: { id: 'u', email: 'a@b.c', first_name: 'A', last_name: 'B', role } as User })
    renderWithProviders(<EventsPage />)
    expect(screen.getByText(`calendario:${expected}`)).toBeInTheDocument()
  })

  it('invitado: no ofrece crear', () => {
    renderWithProviders(<EventsPage />)
    expect(screen.getByText('calendario:false')).toBeInTheDocument()
  })
})
