import django_filters

from apps.events.models import Event


class EventFilter(django_filters.FilterSet):
    """Filtros del listado de eventos.

    `start_date__gte` y `start_date__lte` reciben una fecha (AAAA-MM-DD) y comparan el **día** del evento en
    hora de Colombia: el calendario pide un mes como `2026-01-01`..`2026-01-31`, y comparar contra la
    medianoche dejaría por fuera los eventos del último día.
    """

    start_date__gte = django_filters.DateFilter(field_name="start_date", lookup_expr="date__gte")
    start_date__lte = django_filters.DateFilter(field_name="start_date", lookup_expr="date__lte")

    class Meta:
        model = Event
        fields = ("event_type", "is_published")
