"""RF33 / HU-B10: recordatorio a los inscritos antes de que empiece el evento, una sola vez."""

from datetime import timedelta
from unittest import mock

from django.conf import settings
from django.template.loader import render_to_string
from django.test import TestCase, override_settings
from django.utils import timezone

from apps.events.models import EventRegistration
from apps.events.tasks import send_event_reminders
from apps.notifications.models import Notification, NotificationLog
from services import event_reminders
from services.event_reminders import send_due_reminders
from services.notification_emails import build_notification_email
from services.notification_inbox import build_inbox_items
from tests.factories import EventFactory, UserFactory


class EventReminderTests(TestCase):
    def setUp(self):
        self.now = timezone.now()
        self.user = UserFactory(first_name="Ana", email="ana@narino.test")
        self.event = EventFactory(title="Concierto andino", start_date=self.now + timedelta(hours=20))
        self.registration = EventRegistration.objects.create(event=self.event, user=self.user)

    def reminders(self):
        return Notification.objects.filter(notification_type="EVENT_REMINDER")

    def test_avisa_a_los_inscritos_de_un_evento_que_empieza_en_menos_de_24_horas(self):
        self.assertEqual(send_due_reminders(self.now), 1)
        self.registration.refresh_from_db()
        self.assertEqual(self.registration.reminder_sent_at, self.now)
        (aviso,) = self.reminders()
        self.assertEqual(aviso.recipient_id, self.user.id)
        self.assertEqual(aviso.title, "Tu evento está por empezar")
        self.assertIn("Concierto andino", aviso.body)
        self.assertIn("Teatro Imperial", aviso.body)
        self.assertEqual(aviso.data["url"], f"/events/{self.event.id}")

    def test_nunca_envia_dos_veces(self):
        self.assertEqual(send_due_reminders(self.now), 1)
        self.assertEqual(send_due_reminders(self.now + timedelta(minutes=15)), 0)
        self.assertEqual(self.reminders().count(), 1)
        self.assertEqual(NotificationLog.objects.filter(notification_type="EVENT_REMINDER").count(), 1)

    def test_si_otro_worker_ya_lo_tomo_no_se_envia(self):
        pendientes = list(event_reminders.due_registrations(self.now))
        EventRegistration.objects.update(reminder_sent_at=self.now)  # otro worker se adelantó
        with mock.patch.object(event_reminders, "due_registrations", return_value=pendientes):
            self.assertEqual(send_due_reminders(self.now), 0)
        self.assertFalse(self.reminders().exists())

    def test_espera_hasta_que_falten_24_horas(self):
        self.event.start_date = self.now + timedelta(hours=30)
        self.event.save(update_fields=["start_date"])
        self.assertEqual(send_due_reminders(self.now), 0)
        self.assertEqual(send_due_reminders(self.now + timedelta(hours=7)), 1)

    def test_no_recuerda_eventos_que_ya_empezaron(self):
        self.event.start_date = self.now - timedelta(minutes=5)
        self.event.save(update_fields=["start_date"])
        self.assertEqual(send_due_reminders(self.now), 0)

    def test_no_recuerda_eventos_sin_publicar(self):
        self.event.is_published = False
        self.event.save(update_fields=["is_published"])
        self.assertEqual(send_due_reminders(self.now), 0)

    def test_quien_cancelo_su_inscripcion_no_recibe_recordatorio(self):
        self.registration.delete()
        self.assertEqual(send_due_reminders(self.now), 0)

    def test_avisa_a_cada_inscrito(self):
        otro = UserFactory()
        EventRegistration.objects.create(event=self.event, user=otro)
        self.assertEqual(send_due_reminders(self.now), 2)
        self.assertEqual(set(self.reminders().values_list("recipient_id", flat=True)), {self.user.id, otro.id})

    @override_settings(EVENT_REMINDER_HOURS=2)
    def test_la_anticipacion_se_configura(self):
        self.assertEqual(send_due_reminders(self.now), 0)
        self.assertEqual(send_due_reminders(self.now + timedelta(hours=18, minutes=30)), 1)

    def test_el_aviso_sin_lugar_no_deja_texto_colgando(self):
        self.event.location = ""
        self.event.save(update_fields=["location"])
        send_due_reminders(self.now)
        self.assertTrue(self.reminders().get().body.endswith("."))
        self.assertNotIn(" en .", self.reminders().get().body)

    def test_el_correo_lleva_los_datos_del_evento_y_se_renderiza(self):
        send_due_reminders(self.now)
        log = NotificationLog.objects.get(notification_type="EVENT_REMINDER")
        email = build_notification_email(log)
        self.assertEqual(email.to, "ana@narino.test")
        self.assertEqual(email.subject, "Recordatorio: Concierto andino")
        html = render_to_string(email.template, email.context)
        self.assertIn("Concierto andino", html)
        self.assertIn(f"/events/{self.event.id}", html)

    def test_sin_evento_o_sin_usuario_no_crea_aviso(self):
        sin_evento = {"event_id": "00000000-0000-0000-0000-000000000000", "user_id": str(self.user.id)}
        self.assertEqual(build_inbox_items("EVENT_REMINDER", sin_evento), [])
        self.assertEqual(build_inbox_items("EVENT_REMINDER", {"event_id": str(self.event.id)}), [])

    def test_la_tarea_de_celery_envia_los_pendientes(self):
        self.assertEqual(send_event_reminders(), 1)

    def test_celery_beat_la_programa_cada_15_minutos(self):
        tarea = settings.CELERY_BEAT_SCHEDULE["send-event-reminders"]
        self.assertEqual(tarea["task"], "apps.events.tasks.send_event_reminders")
        self.assertEqual(tarea["schedule"], 900.0)
