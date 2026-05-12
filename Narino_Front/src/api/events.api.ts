import axiosInstance from './axiosInstance'

export interface Event {
  id: string
  title: string
  description: string
  event_type: 'CONCIERTO' | 'EXPOSICION' | 'TALLER' | 'FERIA' | 'ESPECTACULO' | 'OTRO'
  start_date: string
  end_date: string
  location: string
  latitude?: number
  longitude?: number
  image_url?: string
  is_published: boolean
  organizer: {
    id: number
    email: string
    first_name: string
    last_name: string
  }
  created_at: string
  updated_at: string
}

export interface CreateEventPayload {
  title: string
  description: string
  event_type: string
  start_date: string
  end_date: string
  location: string
  latitude?: number
  longitude?: number
  image_url?: string
  is_published?: boolean
}

interface PaginatedEventsResponse {
  results?: Event[]
}

export type EventsResponse = Event[] | PaginatedEventsResponse | null | undefined

export function normalizeEventsResponse(data: EventsResponse): Event[] {
  if (Array.isArray(data)) {
    return data
  }

  if (Array.isArray(data?.results)) {
    return data.results
  }

  return []
}

export const eventsApi = {
  // Obtener todos los eventos publicados
  getPublishedEvents: (params?: {
    event_type?: string
    start_date?: string
    end_date?: string
  }) => {
    return axiosInstance.get<EventsResponse>('/api/v1/events/', {
      params: {
        is_published: true,
        ...params,
      },
    })
  },

  // Obtener todos los eventos (solo para admin/cultural manager)
  getAllEvents: (params?: {
    event_type?: string
    start_date?: string
    end_date?: string
  }) => {
    return axiosInstance.get<EventsResponse>('/api/v1/events/', {
      params,
    })
  },

  // Obtener un evento específico
  getEventById: (id: string) => {
    return axiosInstance.get<Event>(`/api/v1/events/${id}/`)
  },

  // Crear un evento (solo admin/cultural manager)
  createEvent: (payload: CreateEventPayload) => {
    return axiosInstance.post<Event>('/api/v1/events/', payload)
  },

  // Actualizar un evento (solo el organizador/admin)
  updateEvent: (id: string, payload: Partial<CreateEventPayload>) => {
    return axiosInstance.patch<Event>(`/api/v1/events/${id}/`, payload)
  },

  // Eliminar un evento (solo el organizador/admin)
  deleteEvent: (id: string) => {
    return axiosInstance.delete(`/api/v1/events/${id}/`)
  },

  // Registrarse en un evento
  registerToEvent: (id: string) => {
    return axiosInstance.post(`/api/v1/events/${id}/register/`, {})
  },

  // Obtener eventos por mes (para el calendario)
  getEventsByDateRange: (startDate: string, endDate: string) => {
    return axiosInstance.get<EventsResponse>('/api/v1/events/', {
      params: {
        is_published: true,
        start_date__gte: startDate,
        start_date__lte: endDate,
      },
    })
  },
}
