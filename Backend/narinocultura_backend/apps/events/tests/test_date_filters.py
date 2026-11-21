"""Calendario de eventos: filtros por día con start_date__gte y start_date__lte (hora de Colombia)."""

from datetime import datetime
from zoneinfo import ZoneInfo

from rest_framework.test import APITestCase

from tests.factories import EventFactory

URL = "/api/v1/events/"
BOGOTA = ZoneInfo("America/Bogota")


def titles(response):
    data = response.data["results"] if isinstance(response.data, dict) else response.data
    return sorted(row["title"] for row in data)


class EventDateFilterTests(APITestCase):
    def setUp(self):
        EventFactory(title="Fin de diciembre", start_date=datetime(2030, 12, 31, 23, 0, tzinfo=BOGOTA))
        EventFactory(title="Enero temprano", start_date=datetime(2031, 1, 1, 8, 0, tzinfo=BOGOTA))
        EventFactory(title="Último día de enero", start_date=datetime(2031, 1, 31, 21, 0, tzinfo=BOGOTA))
        EventFactory(title="Febrero", start_date=datetime(2031, 2, 1, 0, 30, tzinfo=BOGOTA))

    def month(self, start, end):
        return titles(self.client.get(URL, {"start_date__gte": start, "start_date__lte": end}))

    def test_el_mes_incluye_los_eventos_del_ultimo_dia_aunque_sean_de_noche(self):
        self.assertEqual(self.month("2031-01-01", "2031-01-31"), ["Enero temprano", "Último día de enero"])

    def test_usa_la_hora_de_colombia_y_no_utc(self):
        # 31 de diciembre a las 11 p. m. en Bogotá ya es 1 de enero en UTC: igual pertenece a diciembre
        self.assertEqual(self.month("2030-12-01", "2030-12-31"), ["Fin de diciembre"])

    def test_cada_limite_funciona_por_separado(self):
        self.assertEqual(
            titles(self.client.get(URL, {"start_date__gte": "2031-01-31"})), ["Febrero", "Último día de enero"]
        )
        self.assertEqual(titles(self.client.get(URL, {"start_date__lte": "2030-12-31"})), ["Fin de diciembre"])

    def test_se_combina_con_el_tipo_de_evento(self):
        EventFactory(title="Taller de enero", event_type="TALLER", start_date=datetime(2031, 1, 15, 10, 0, tzinfo=BOGOTA))
        r = self.client.get(URL, {"start_date__gte": "2031-01-01", "start_date__lte": "2031-01-31", "event_type": "TALLER"})
        self.assertEqual(titles(r), ["Taller de enero"])

    def test_una_fecha_invalida_responde_400(self):
        self.assertEqual(self.client.get(URL, {"start_date__gte": "no-es-fecha"}).status_code, 400)

    def test_acepta_tambien_el_formato_dia_mes_anio(self):
        self.assertEqual(titles(self.client.get(URL, {"start_date__gte": "01/02/2031"})), ["Febrero"])
