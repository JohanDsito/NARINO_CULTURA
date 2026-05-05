# Integracion de n8n para Nariño Cultura

Tu backend ya envia eventos a `n8n` usando la variable `N8N_WEBHOOK_URL`.

## 1. Variables recomendadas

Agrega o revisa estas variables en [.env](C:\Users\Usuario\Desktop\NARINO_CULTURA\.env):

```env
N8N_WEBHOOK_URL=http://n8n:5678/webhook/narinocultura
FRONTEND_BASE_URL=http://localhost:5173
API_BASE_URL=http://localhost:8000
```

## 2. Payload que recibe n8n

Cuando un usuario se registra, Django envia un POST como este:

```json
{
  "type": "EMAIL_VERIFICATION",
  "payload": {
    "email": "usuario@correo.com",
    "token": "token-seguro",
    "verification_url": "http://localhost:5173/verify-email?token=token-seguro",
    "verification_api_url": "http://localhost:8000/api/v1/auth/verify-email/"
  },
  "user": {
    "id": "uuid-del-usuario",
    "email": "usuario@correo.com",
    "first_name": "Nombre",
    "last_name": "Apellido"
  }
}
```

Para recuperacion de contraseña, el tipo sera `PASSWORD_RESET` y el payload incluira `reset_url`.

## 3. Importar workflow en n8n

1. Entra a `http://localhost:5678`.
2. Ve a `Workflows`.
3. Elige `Import from file`.
4. Importa [narinocultura-auth-email-workflow.json](C:\Users\Usuario\Desktop\NARINO_CULTURA\docs\n8n\narinocultura-auth-email-workflow.json).
5. Abre el nodo `Send Email` y asigna tus credenciales SMTP.
6. Activa el workflow.

## 4. SMTP para pruebas

Puedes usar Gmail con contraseña de aplicacion o un servicio como Mailtrap.

Campos clave del nodo `Send Email`:

- `To Email`: `={{ $json.to }}`
- `Subject`: `={{ $json.subject }}`
- `Email Format`: `HTML`
- `HTML`: `={{ $json.html }}`

## 5. Prueba completa

1. Levanta `docker compose up`.
2. Verifica que `n8n` este activo.
3. Registra un usuario nuevo en el frontend.
4. Revisa la ejecucion del workflow en `n8n`.
5. Abre el correo recibido y prueba el enlace.

## 6. Resultado esperado

- Registro: llega correo con boton de verificacion.
- Recuperacion: llega correo con boton para crear nueva contraseña.
- Si `n8n` falla, Django deja trazabilidad en `NotificationLog`.
