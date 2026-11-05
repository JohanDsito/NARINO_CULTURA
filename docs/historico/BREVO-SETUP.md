# 📧 Guía de Configuración - Brevo para Nariño Cultura

## ✅ Cambios Realizados

Tu backend ha sido **actualizado de Resend a Brevo**:

### Archivos modificados:
1. ✅ `services/email_service.py` - Reemplazado `_send_via_resend()` con `_send_via_brevo()`
2. ✅ `config/settings/base.py` - Agregadas variables de Brevo, Resend comentado

---

## 🔑 Configuración en Railway

### Paso 1: Obtener API Key de Brevo

1. Ve a: https://dashboard.brevo.com/
2. Login con tu cuenta Brevo
3. En la izquierda, click en **Settings** → **SMTP & API**
4. En la sección **API Keys**, copia tu clave (empieza con `xkeysib-`)

### Paso 2: Obtener Email Verificado en Brevo

1. En Brevo Dashboard, ve a **Senders & Lists** → **Senders**
2. Verifica que tengas al menos un email registrado
3. Ejemplo: `noreply@narinocultura.uk` o similar
4. **Importante:** Este email debe estar verificado en Brevo

### Paso 3: Configurar en Railway

En tu proyecto de Railway:

1. Ve a **Variables** en el dashboard
2. Agrega dos nuevas variables de entorno:

```
BREVO_API_KEY=xkeysib-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
BREVO_FROM_EMAIL=noreply@narinocultura.uk
```

**Nota:** Reemplaza con tus valores reales.

---

## 🧪 Probar Configuración Local

### En tu máquina local:

1. Crea un archivo `.env` en la raíz:

```
BREVO_API_KEY=xkeysib-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
BREVO_FROM_EMAIL=noreply@narinocultura.uk
```

2. Inicia el servidor:

```bash
python manage.py runserver
```

3. En Postman o cURL, registra un usuario:

```bash
curl -X POST http://localhost:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123!",
    "first_name": "Test",
    "last_name": "User",
    "role": "ARTISTA"
  }'
```

4. **Verifica los logs** en la consola:

```
✅ Si funciona:
2026-05-15 10:30:00 INFO     Email enviado a test@example.com vía Brevo

❌ Si falla:
2026-05-15 10:30:00 ERROR    Brevo API error 401: ...
```

---

## 🔍 Posibles Errores y Soluciones

### Error 1: "API key is invalid"
```
Brevo API error 401: API key is invalid
```

**Causa:** La API key de Brevo es incorrecta  
**Solución:**
1. Verifica que copiaste toda la clave (debe empezar con `xkeysib-`)
2. Ve a Brevo Dashboard y copia nuevamente
3. En Railway, actualiza `BREVO_API_KEY`

### Error 2: "Sender not verified"
```
Brevo API error 400: Sender not verified
```

**Causa:** El email en `BREVO_FROM_EMAIL` no está verificado en Brevo  
**Solución:**
1. Ve a Brevo Dashboard → **Senders**
2. Agrega el email si no existe
3. Brevo te enviará un email de confirmación
4. Haz click para verificar
5. Espera 5 minutos y reintenta

### Error 3: "Network is unreachable"
```
Error de red con Brevo: Network is unreachable
```

**Causa:** Railway no permite salida a la API de Brevo  
**Solución (probable):**
1. Verifica que el dominio `api.brevo.com` sea accesible
2. En Railway, reinicia el proyecto
3. Si persiste, contacta a soporte de Railway

### Error 4: "BREVO_API_KEY no configurada"
```
Error: Brevo API key no configurada
```

**Causa:** La variable de entorno no está configurada  
**Solución:**
1. En Railway, ve a **Variables**
2. Asegúrate de que `BREVO_API_KEY` está agregada
3. Redeploy la aplicación

---

## 📋 Estructura de la API de Brevo

**Endpoint:** `https://api.brevo.com/v3/smtp/email`

**Headers requeridos:**
```
api-key: xkeysib-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Content-Type: application/json
```

**Body esperado:**
```json
{
  "sender": {
    "name": "Nariño Cultura",
    "email": "noreply@narinocultura.uk"
  },
  "to": [
    {
      "email": "recipient@example.com"
    }
  ],
  "subject": "Verifica tu correo en Nariño Cultura",
  "htmlContent": "<html>...</html>",
  "textContent": "Verifica tu correo..."
}
```

---

## ✨ Ventajas de Brevo vs Resend

| Característica | Brevo | Resend |
|---|---|---|
| Dominio personalizado | ✅ Sí | ❌ Requiere verificación |
| API Key | ✅ `api-key` header | ❌ Bearer token |
| Limit gratuito | ✅ 300/día | ❌ Limitado |
| Usuarios ilimitados | ✅ Sí | ❌ No |
| Costo | ✅ Más económico | ❌ Más caro |

---

## 🔄 Flujo de Verificación de Email

Ahora con Brevo:

```
1. Usuario se registra
   ↓
2. Backend crea token de verificación
   ↓
3. Backend llama a Brevo API
   ↓
4. Brevo envía email con link de verificación
   ↓
5. Usuario hace click en link/verifica token
   ↓
6. Email verificado ✅
```

---

## 📞 Debugging

### Para ver más detalles en los logs:

En `views.py` ya hay logging detallado:

```python
logger.info(f"Email enviado a {user_email} vía Brevo")
logger.error(f"Brevo API error: {error_message}")
```

**En Railway:**
1. Ve a tu proyecto
2. Click en la pestaña **Logs**
3. Busca las líneas con "Brevo" o "Email"

---

## 🚀 Próximos Pasos

### En desarrollo:
```bash
1. Configura .env localmente
2. Prueba registro con Postman
3. Verifica que recibes el email
4. Confirma que puedes verificar email
```

### En producción (Railway):
```bash
1. Agrega variables en Railway
2. Redeploy la app
3. Prueba con usuario real
4. Monitorea logs
```

---

## ✅ Checklist Final

- [ ] Tengo API Key de Brevo
- [ ] Tengo email verificado en Brevo
- [ ] `BREVO_API_KEY` configurada en Railway
- [ ] `BREVO_FROM_EMAIL` configurada en Railway
- [ ] Redeploy hecho en Railway
- [ ] Probé registro y recibí email
- [ ] Email se puede verificar correctamente

---

**Documento generado:** Mayo 15, 2026  
**Versión:** 1.0 - Migración de Resend a Brevo  
**Estado:** ✅ Listo para usar

Si el email aún no funciona después de configurar, revisa los logs en Railway buscando "ERROR" o "Brevo".
