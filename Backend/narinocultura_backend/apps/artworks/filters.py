import django_filters

from apps.artworks.models import Artwork


class ArtworkFilter(django_filters.FilterSet):
    """Filtros del catálogo: ?status=, ?category=, ?technique= (contiene), ?price_min=, ?price_max=."""

    technique = django_filters.CharFilter(field_name="technique", lookup_expr="icontains")
    price_min = django_filters.NumberFilter(field_name="price", lookup_expr="gte")
    price_max = django_filters.NumberFilter(field_name="price", lookup_expr="lte")

    class Meta:
        model = Artwork
        fields = ("status", "category", "technique", "price_min", "price_max")
