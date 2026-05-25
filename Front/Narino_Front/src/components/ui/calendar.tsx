import { useState, useMemo } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { 
  startOfMonth, 
  endOfMonth, 
  startOfWeek, 
  endOfWeek,
  addMonths,
  subMonths,
  isSameMonth,
  isSameDay,
  format,
  eachDayOfInterval
} from 'date-fns'
import { es } from 'date-fns/locale'
import { Button } from '@/components/ui/button'
import type { Event } from '@/api/events.api'

interface CalendarProps {
  events: Event[]
  isLoading?: boolean
  onSelectDate?: (date: Date) => void
  selectedDate?: Date
  currentMonth?: Date
  onMonthChange?: (date: Date) => void
}

export function Calendar({
  events,
  isLoading = false,
  onMonthChange,
  onSelectDate,
  selectedDate,
  currentMonth: controlledMonth,
}: CalendarProps) {
  const [uncontrolledMonth, setUncontrolledMonth] = useState(new Date())
  const currentMonth = controlledMonth ?? uncontrolledMonth

  const changeMonth = (date: Date) => {
    if (!controlledMonth) {
      setUncontrolledMonth(date)
    }
    onMonthChange?.(date)
  }

  // Crear un mapa de eventos por fecha
  const eventsByDate = useMemo(() => {
    const map = new Map<string, Event[]>()
    events.forEach((event) => {
      const date = format(new Date(event.start_date), 'yyyy-MM-dd')
      if (!map.has(date)) {
        map.set(date, [])
      }
      map.get(date)!.push(event)
    })
    return map
  }, [events])

  // Obtener todos los días del mes a mostrar
  const monthStart = startOfMonth(currentMonth)
  const monthEnd = endOfMonth(currentMonth)
  const startDate = startOfWeek(monthStart)
  const endDate = endOfWeek(monthEnd)

  const days = eachDayOfInterval({ start: startDate, end: endDate })

  const handlePrevMonth = () => {
    changeMonth(subMonths(currentMonth, 1))
  }

  const handleNextMonth = () => {
    changeMonth(addMonths(currentMonth, 1))
  }

  const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sab']

  return (
    <div className="w-full bg-card rounded-lg border p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-semibold capitalize">
            {format(currentMonth, 'MMMM yyyy', { locale: es })}
          </h3>
          {isLoading && (
            <p className="mt-1 text-xs text-muted-foreground">
              Actualizando eventos...
            </p>
          )}
        </div>
        <div className="flex gap-2">
          <Button
            type="button"
            variant="outline"
            size="icon"
            onClick={handlePrevMonth}
            aria-label="Mes anterior"
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <Button
            type="button"
            variant="outline"
            size="icon"
            onClick={handleNextMonth}
            aria-label="Mes siguiente"
          >
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Days of week */}
      <div className="grid grid-cols-7 gap-2 mb-2">
        {dayNames.map((day) => (
          <div
            key={day}
            className="text-center text-sm font-semibold text-muted-foreground py-2"
          >
            {day}
          </div>
        ))}
      </div>

      {/* Calendar grid */}
      <div className="grid grid-cols-7 gap-2">
        {days.map((day) => {
          const dateStr = format(day, 'yyyy-MM-dd')
          const dayEvents = eventsByDate.get(dateStr) || []
          const isCurrentMonth = isSameMonth(day, currentMonth)
          const isSelected = selectedDate && isSameDay(day, selectedDate)

          return (
            <div
              key={dateStr}
              onClick={() => onSelectDate?.(day)}
              className={`
                min-h-[80px] p-2 rounded-lg border cursor-pointer transition-colors
                ${!isCurrentMonth ? 'bg-muted/30 text-muted-foreground' : 'bg-background'}
                ${isSelected ? 'border-primary bg-primary/10' : 'border-border hover:border-primary/50'}
              `}
            >
              <div className="text-sm font-medium mb-1">
                {format(day, 'd')}
              </div>
              <div className="space-y-1">
                {dayEvents.slice(0, 2).map((event) => (
                  <div
                    key={event.id}
                    className="text-xs px-1.5 py-0.5 rounded bg-primary/10 text-primary truncate hover:bg-primary/20"
                    title={event.title}
                  >
                    {event.title}
                  </div>
                ))}
                {dayEvents.length > 2 && (
                  <div className="text-xs text-muted-foreground px-1.5">
                    +{dayEvents.length - 2} más
                  </div>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
