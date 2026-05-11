import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import { eventsApi } from '@/api/events.api'
import { EventFormModal } from '@/components/events/event-form-modal'

jest.mock('@/api/events.api', () => ({
  eventsApi: {
    createEvent: jest.fn(),
  },
}))

jest.mock('sonner', () => ({
  toast: {
    error: jest.fn(),
    success: jest.fn(),
  },
}))

const mockedCreateEvent = jest.mocked(eventsApi.createEvent)

function renderEventFormModal(props?: Partial<Parameters<typeof EventFormModal>[0]>) {
  const queryClient = new QueryClient()
  const onOpenChange = jest.fn()
  const onSuccess = jest.fn()

  render(
    <QueryClientProvider client={queryClient}>
      <EventFormModal
        open
        onOpenChange={onOpenChange}
        onSuccess={onSuccess}
        {...props}
      />
    </QueryClientProvider>,
  )

  return { onOpenChange, onSuccess }
}

describe('EventFormModal', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('does not render while closed', () => {
    renderEventFormModal({ open: false })

    expect(screen.queryByText(/crear nuevo evento/i)).not.toBeInTheDocument()
  })

  it('validates required fields before creating an event', async () => {
    const user = userEvent.setup()
    renderEventFormModal()

    await user.click(screen.getByRole('button', { name: /crear evento/i }))

    expect(await screen.findByText(/título debe tener/i)).toBeInTheDocument()
    expect(mockedCreateEvent).not.toHaveBeenCalled()
  })

  it('submits normalized event payload and closes on success', async () => {
    const user = userEvent.setup()
    const { onOpenChange, onSuccess } = renderEventFormModal()
    mockedCreateEvent.mockResolvedValueOnce({ data: {} } as Awaited<ReturnType<typeof eventsApi.createEvent>>)

    await user.type(screen.getByLabelText(/título del evento/i), 'Concierto andino')
    await user.type(screen.getByLabelText(/descripción/i), 'Una muestra musical tradicional')
    await user.selectOptions(screen.getByLabelText(/tipo de evento/i), 'CONCIERTO')
    await user.type(screen.getByLabelText(/ubicación/i), 'Teatro Pasto')
    await user.type(screen.getByLabelText(/fecha y hora de inicio/i), '2026-01-01T10:00')
    await user.type(screen.getByLabelText(/fecha y hora de fin/i), '2026-01-01T12:00')
    await user.click(screen.getByRole('button', { name: /crear evento/i }))

    await waitFor(() => {
      expect(mockedCreateEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Concierto andino',
          event_type: 'CONCIERTO',
          is_published: true,
        }),
      )
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
    expect(onSuccess).toHaveBeenCalled()
  })
})
