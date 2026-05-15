# 📝 Resumen de Cambios - Migración de Resend a Brevo

## ✅ Cambios Realizados

### 1. **services/email_service.py**

#### ❌ Eliminado:
- Método `_send_via_resend()` - Ya no se usa Resend

#### ✅ Agregado:
- Método `_send_via_brevo()` - Implementación completa de API de Brevo

**Diferencias técnicas:**

| Aspecto | Resend | Brevo |
|--------|--------|-------|
| Endpoint | `https://api.resend.com/emails` | `https://api.brevo.com/v3/smtp/email` |
| Autenticación | `Authorization: Bearer {key}` | `api-key: {key}` |
| Email remitente | Fijo: `onboarding@resend.dev` | Configurable: `BREVO_FROM_EMAIL` |
| Formato JSON | `from`, `to`, `html`, `text` | `sender`, `to`, `htmlContent`, `textContent` |

#### 🔄 Actualizado:
- `_send_email()` - Ahora intenta Brevo primero, SMTP como fallback

---

### 2. **config/settings/base.py**

#### ❌ Comentado (mantiene compatibilidad):
```python
# RESEND_FROM_EMAIL = config("RESEND_FROM_EMAIL", default="onboarding@resend.dev")
# RESEND_API_KEY = config("RESEND_API_KEY", default="")
```

#### ✅ Agregado:
```python
# Configuración para Brevo
BREVO_API_KEY = config("BREVO_API_KEY", default="")
BREVO_FROM_EMAIL = config("BREVO_FROM_EMAIL", default="noreply@narinocultura.com")
```

#### Variables de Entorno Requeridas:
| Variable | Tipo | Ejemplo |
|----------|------|---------|
| `BREVO_API_KEY` | String | `xkeysib-abcd1234efgh5678...` |
| `BREVO_FROM_EMAIL` | Email | `noreply@narinocultura.com` |

---

## 🔍 Antes vs Después

### Antes (Resend):
```
Usuario registra → Backend crea token
  ↓
Intenta enviar con Resend
  ↓
❌ Error 401: API key invalid (porque API key de Brevo se pasó a Resend)
  ↓
Intenta fallback a SMTP
  ↓
❌ Error: Network is unreachable (Railway no permite salida SMTP)
  ↓
Email NO se envía ❌
```

### Ahora (Brevo):
```
Usuario registra → Backend crea token
  ↓
Intenta enviar con Brevo (API HTTP, sale sin problemas)
  ↓
✅ Brevo recibe y envía email
  ↓
Email se envía correctamente ✅
```

---

## 🚀 Próximos Pasos

### 1. En Railway (Producción):
```bash
Ir a: Variables de Entorno
Agregar:
  BREVO_API_KEY = xkeysib-XXXXXXX...
  BREVO_FROM_EMAIL = noreply@narinocultura.com
Redeploy la aplicación
```

### 2. En Local (.env):
```bash
BREVO_API_KEY=xkeysib-XXXXXXX...
BREVO_FROM_EMAIL=noreply@narinocultura.com
```

### 3. Probar:
```bash
# Registro
POST /api/v1/auth/register/

# Revisar logs para:
"Email enviado a ... vía Brevo" ✅
# O
"Brevo API error" ❌
```

---

## 📊 Comparativa de Código

### Antes:
```python
def _send_via_resend(...):
    from_email = "onboarding@resend.dev"
    payload = {
        "from": from_email,
        "to": [user_email],
        "html": html_message,
    }
    headers = {
        "Authorization": f"Bearer {settings.RESEND_API_KEY}",
    }
    response = requests.post("https://api.resend.com/emails", ...)
```

### Ahora:
```python
def _send_via_brevo(...):
    payload = {
        "sender": {
            "name": "Nariño Cultura",
            "email": brevo_from_email
        },
        "to": [{"email": user_email}],
        "htmlContent": html_message,
    }
    headers = {
        "api-key": brevo_api_key,
    }
    response = requests.post("https://api.brevo.com/v3/smtp/email", ...)
```

---

## 🔧 Configuración Mínima

Para que funcione, necesitas:

1. **Cuenta en Brevo:** https://www.brevo.com/
2. **API Key:** De https://dashboard.brevo.com/settings/ips,smtp
3. **Email verificado:** En Brevo → Senders & Lists → Senders
4. **Variables en Railway:**
   ```
   BREVO_API_KEY=xkeysib-...
   BREVO_FROM_EMAIL=noreply@narinocultura.com
   ```

---

## ✅ Validación

Para verificar que todo funciona:

### Log exitoso:
```
2026-05-15 10:30:00,000 INFO     Email enviado a user@example.com vía Brevo
```

### Log de error:
```
2026-05-15 10:30:00,000 ERROR    Brevo API error 401: API key is invalid
```

Si ves el primer mensaje, ¡todo está funcionando! ✅

---

## 📋 Archivos Generados

- `docs/BREVO-SETUP.md` - Guía completa de configuración

---

## 🎯 Estado

| Componente | Estado |
|-----------|--------|
| Email Service actualizado | ✅ Completo |
| Settings.py actualizado | ✅ Completo |
| Brevo integrado | ✅ Listo |
| SMTP fallback | ✅ Disponible |
| Documentación | ✅ Completa |

**Próximo paso:** Configura `BREVO_API_KEY` y `BREVO_FROM_EMAIL` en Railway y redeploy.

---

**Fecha:** Mayo 15, 2026  
**Versión:** 1.0 - Migración completa de Resend a Brevo
