# Guía de Prueba - Sistema de Email de Verificación

## Cambios Realizados

Se ha implementado un sistema de envío de emails directamente desde el backend Django, reemplazando la dependencia de n8n. Esto incluye:

### 1. **Configuración de Django**
- ✅ Agregadas variables de configuración SMTP en `config/settings/base.py`
- ✅ Configuración de carpeta de templates en `BASE_DIR/templates/`

### 2. **Nuevo Servicio de Email**
- ✅ Creado `services/email_service.py` con las siguientes funciones:
  - `send_verification_email()` - Envía email de verificación de cuenta
  - `send_password_reset_email()` - Envía email para resetear contraseña
  - `send_welcome_email()` - Envía email de bienvenida

### 3. **Templates de Email**
- ✅ `templates/emails/verify_email.html` - Template para verificación
- ✅ `templates/emails/reset_password.html` - Template para reset de contraseña
- ✅ `templates/emails/welcome.html` - Template de bienvenida

### 4. **Integración en Vistas**
- ✅ `RegisterAPIView` - Usa `EmailService.send_verification_email()`
- ✅ `PasswordResetRequestAPIView` - Usa `EmailService.send_password_reset_email()`

---

## Variables de Entorno Requeridas

Asegúrate de tener estas variables en tu archivo `.env`:

```env
# Email Configuration (SMTP)
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=narinocultura@gmail.com
EMAIL_HOST_PASSWORD=tu_contraseña_de_aplicación
DEFAULT_FROM_EMAIL=noreply@narinocultura.uk

# Frontend URL (para los links en los emails)
FRONTEND_URL=http://localhost:5173
```

### Para Gmail:
1. Habilita "Verificación en dos pasos"
2. Genera una "Contraseña de aplicación" específica para esta aplicación
3. Usa esa contraseña en `EMAIL_HOST_PASSWORD` (NO tu contraseña personal)

---

## Pruebas

### Opción 1: Prueba Manual en la API

```bash
# 1. Registrar un nuevo usuario
curl -X POST http://localhost:8000/api/users/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123!",
    "first_name": "Juan",
    "last_name": "Pérez",
    "role": "COMPRADOR"
  }'

# Respuesta esperada:
# {
#   "detail": "Registro exitoso. Revisa tu correo para verificar la cuenta."
# }

# 2. Verificar el email
curl -X POST http://localhost:8000/api/users/verify-email/ \
  -H "Content-Type: application/json" \
  -d '{
    "token": "TOKEN_RECIBIDO_EN_EL_EMAIL"
  }'

# Respuesta esperada:
# {
#   "detail": "Email verificado correctamente."
# }
```

### Opción 2: Prueba con Django Shell

```bash
python manage.py shell

# Dentro del shell:
from apps.users.models import User, EmailVerification
from services.email_service import EmailService

# Crear un usuario de prueba
user = User.objects.create_user(
    email='prueba@example.com',
    password='TestPassword123!',
    first_name='Prueba',
    last_name='Usuario',
    role='COMPRADOR',
    is_active=True,
    is_verified=False
)

# Crear verificación de email
verification = EmailVerification.issue_for_user(user)

# Enviar email
result = EmailService.send_verification_email(user.email, verification.token)
print(f"Email enviado: {result.ok}")
if not result.ok:
    print(f"Error: {result.error_message}")
```

### Opción 3: Prueba en Consola de Desarrollo

```bash
# En el shell de Django:
from django.core.mail import send_mail

send_mail(
    'Asunto de prueba',
    'Este es un mensaje de prueba',
    'from@example.com',
    ['to@example.com'],
    fail_silently=False,
)
```

---

## Debugging

### Si los emails no se envían:

1. **Verifica la configuración**:
```bash
python manage.py shell
from django.conf import settings
print(f"EMAIL_HOST: {settings.EMAIL_HOST}")
print(f"EMAIL_PORT: {settings.EMAIL_PORT}")
print(f"EMAIL_USE_TLS: {settings.EMAIL_USE_TLS}")
print(f"EMAIL_HOST_USER: {settings.EMAIL_HOST_USER}")
print(f"FRONTEND_URL: {settings.FRONTEND_URL}")
```

2. **Prueba conexión SMTP**:
```python
from django.core.mail.backends.smtp import EmailBackend
backend = EmailBackend()
connection = backend.connection
# Si no hay error, la conexión es exitosa
```

3. **Revisa los logs**:
- El servicio de email incluye logging en `services/email_service.py`
- Busca logs con `logger.info()` o `logger.error()`

### Errores comunes:

| Error | Causa | Solución |
|-------|-------|----------|
| `SMTPAuthenticationError` | Credenciales incorrectas | Verifica EMAIL_HOST_USER y EMAIL_HOST_PASSWORD |
| `SMTPNotSupportedError` | TLS no soportado | Asegúrate que EMAIL_USE_TLS=True para puerto 587 |
| `ConnectionRefusedError` | No se puede conectar al host SMTP | Verifica EMAIL_HOST y EMAIL_PORT |
| `Template not found` | Templates no están en la ruta correcta | Verifica que la carpeta `templates/emails/` exista |

---

## Próximos Pasos

### Mejorar notificaciones de eventos:
Las notificaciones de eventos en `apps/events/views.py` aún usan `NotificationService` (n8n). 
Considera migrarlas también al `EmailService` si deseas consolidar todo el sistema de emails.

### Implementar tareas asincrónicas:
Para aplicaciones con muchos usuarios, considera usar Celery con Redis para enviar emails de forma asincrónica:

```python
from celery import shared_task
from services.email_service import EmailService

@shared_task
def send_verification_email_async(user_email, token):
    return EmailService.send_verification_email(user_email, token)
```

### Monitorear fallos de email:
Implementar reintentos automáticos usando `NotificationLog`:

```python
from apps.notifications.models import NotificationLog

# Buscar fallos de email
failed_logs = NotificationLog.objects.filter(
    notification_type='EMAIL_VERIFICATION',
    status=NotificationLog.Status.FALLIDO
)
```

---

## Rollback a n8n

Si necesitas volver a usar n8n:

1. En `apps/users/views.py`, reemplaza `EmailService` por `NotificationService`
2. Reactiva el webhook de n8n
3. Reconfigura n8n para manejar los eventos de verificación de email

---

## Contacto y Soporte

Para cualquier issue durante el despliegue:
1. Verifica que las variables de entorno están correctas
2. Revisa los logs de la aplicación
3. Asegúrate que el servidor SMTP es accesible desde tu entorno
