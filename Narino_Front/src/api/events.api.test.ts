import { describe, it, expect, beforeEach, vi } from 'vitest'

import axiosInstance from './axiosInstance'
import { eventsApi } from './events.api'

vi.mock('./axiosInstance', () => ({
  default: {
    delete: vi.fn(),
    get: vi.fn(),
    patch: vi.fn(),
    post: vi.fn(),
  },
}))

const mockedAxios = vi.mocked(axiosInstance)

describe('events.api', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('requests published events with default and custom params', () => {
    eventsApi.getPublishedEvents({
      event_type: 'TALLER',
    })

    expect(mockedAxios.get).toHaveBeenCalledWith(
      '/api/v1/events/',
      {
        params: {
          is_published: true,
          event_type: 'TALLER',
        },
      },
    )
  })

  it('requests admin event list without forcing published filter', () => {
    eventsApi.getAllEvents({
      start_date: '2026-01-01',
    })

    expect(mockedAxios.get).toHaveBeenCalledWith(
      '/api/v1/events/',
      {
        params: {
          start_date: '2026-01-01',
        },
      },
    )
  })

  it('calls detail and mutation endpoints', () => {
    const payload = {
      title: 'Concierto',
      description: 'Música tradicional',
      event_type: 'CONCIERTO',
      start_date: '2026-01-01T10:00:00.000Z',
      end_date: '2026-01-01T12:00:00.000Z',
      location: 'Pasto',
    }

    eventsApi.getEventById('1')
    eventsApi.createEvent(payload)
    eventsApi.updateEvent('1', {
      title: 'Taller',
    })
    eventsApi.deleteEvent('1')
    eventsApi.registerToEvent('1')

    expect(mockedAxios.get).toHaveBeenCalledWith(
      '/events/1/',
    )

    expect(mockedAxios.post).toHaveBeenCalledWith(
      '/events/',
      payload,
    )

    expect(mockedAxios.patch).toHaveBeenCalledWith(
      '/events/1/',
      {
        title: 'Taller',
      },
    )

    expect(mockedAxios.delete).toHaveBeenCalledWith(
      '/events/1/',
    )

    expect(mockedAxios.post).toHaveBeenCalledWith(
      '/events/1/register/',
      {},
    )
  })

  it('requests events by date range for calendar views', () => {
    eventsApi.getEventsByDateRange(
      '2026-01-01',
      '2026-01-31',
    )

    expect(mockedAxios.get).toHaveBeenCalledWith(
      '/api/v1/events/',
      {
        params: {
          is_published: true,
          start_date__gte: '2026-01-01',
          start_date__lte: '2026-01-31',
        },
      },
    )
  })
})