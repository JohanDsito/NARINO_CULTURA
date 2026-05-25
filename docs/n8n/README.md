# Integracion de n8n para Narino Cultura

Tu backend envia eventos a `n8n` usando la variable `N8N_WEBHOOK_URL`.

## 1. Variables recomendadas

Revisa estas variables en [.env](C:\Users\Usuario\Desktop\NARINO_CULTURA\.env):

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

Para recuperacion de contrasena, el tipo sera `PASSWORD_RESET` y el payload incluira `reset_url`.

## 3. Mejoras del correo

El workflow actualizado:

- saluda al usuario con el primer nombre y el primer apellido
- usa `payload.verification_url` en el boton de verificacion
- muestra un enlace completo utilizable como respaldo
- conserva el token como apoyo para pruebas manuales

## 4. Importar workflow en n8n

1. Entra a `http://localhost:5678`.
2. Ve a `Workflows`.
3. Elige `Import from file`.
4. Importa [narinocultura-auth-email-workflow.json](C:\Users\Usuario\Desktop\NARINO_CULTURA\docs\n8n\narinocultura-auth-email-workflow.json).
5. Abre el nodo `Send Email` y asigna tus credenciales SMTP.
6. Activa el workflow.
7. Si ya tenias un workflow funcionando, reimporta este archivo o reemplaza manualmente el codigo del nodo `Build Email`.

## 5. SMTP para pruebas

Puedes usar Gmail con contrasena de aplicacion o un servicio como Mailtrap.

Campos clave del nodo `Send Email`:

- `To Email`: `={{ $json.to }}`
- `Subject`: `={{ $json.subject }}`
- `Email Format`: `HTML`
- `HTML`: `={{ $json.html }}`

## 6. Prueba completa

1. Levanta `docker compose up`.
2. Verifica que `n8n` este activo.
3. Registra un usuario nuevo en el frontend.
4. Revisa la ejecucion del workflow en `n8n`.
5. Abre el correo recibido y prueba el boton.

## 7. Resultado esperado

- Registro: llega correo con boton de verificacion.
- El saludo usa el primer nombre y el primer apellido del usuario.
- Si el cliente de correo no abre bien el boton, el mensaje incluye una URL completa utilizable.
- Recuperacion: llega correo con boton para crear nueva contrasena.
- Si `n8n` falla, Django deja trazabilidad en `NotificationLog`.
