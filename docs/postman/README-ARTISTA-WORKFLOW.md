# Guía de Uso - Colección Postman Artista Workflow

## 📋 Descripción

Colección completa para probar todos los endpoints de la API de **Nariño Cultura** desde el rol de **ARTISTA**.

## 🚀 Primeros Pasos

### 1. Importar Colección en Postman

1. Abre Postman
2. Click en **Import** (esquina superior izquierda)
3. Selecciona el archivo `Artista-Workflow.postman_collection.json`
4. Se importará automáticamente con todas las requests organizadas

### 2. Configurar Variables de Entorno

La colección ya incluye variables por defecto. Solo necesitas actualizar:

| Variable | Valor por Defecto | Descripción |
|----------|------------------|-------------|
| `base_url` | `http://localhost:8000` | URL de tu servidor backend |
| `access_token` | Vacío | Se genera automáticamente al hacer login |
| `refresh_token` | Vacío | Se genera automáticamente al hacer login |
| `artist_id` | Vacío | ID del artista, obtén después de crear perfil |
| `artwork_id` | Vacío | ID de una obra, obtén después de crear |
| `auction_id` | Vacío | ID de una subasta, obtén después de crear |

**Para actualizar la URL base:**
- Click en el ojo (👁️) en la esquina superior derecha
- Busca `base_url` y actualiza con tu URL

## 📝 Flujo Recomendado de Pruebas

### Fase 1: Autenticación
1. **Registro como Artista** → Crea un nuevo usuario con rol ARTISTA
2. **Verificar Email** → Usa el token que recibas en el correo (consulta en logs)
3. **Login como Artista** → Se guardarán los tokens automáticamente
4. **Logout** → Prueba cierre de sesión

### Fase 2: Configurar Perfil
5. **Obtener Mi Perfil** → Verifica que el usuario esté creado
6. **Actualizar Mi Perfil** → Completa información personal
7. **Crear/Actualizar Perfil de Artista** → Agrega nombre artístico y redes sociales
8. **Obtener Mi Perfil de Artista** → Verifica que se guardó

### Fase 3: Crear Obras de Arte
9. **Listar Categorías** → Obtén una `category_id`
10. **Crear Nueva Obra de Arte** → Usa la `category_id`, guarda el `artwork_id`
11. **Listar Mis Obras** → Filtra por tu `artist_id`
12. **Actualizar Obra de Arte** → Modifica precio o disponibilidad

### Fase 4: Subastas
13. **Crear Nueva Subasta** → Usa el `artwork_id`, guarda el `auction_id`
14. **Listar Subastas** → Ve todas las subastas activas
15. **Obtener Detalle de Subasta** → Verifica detalles específicos
16. **Hacer Una Puja** → Participa en subastas
17. **Listar Mis Subastas como Vendedor** → Ve solo tus subastas

### Fase 5: Marketplace
18. **Obtener Mis Ventas** → Ve todas tus ventas realizadas
19. **Agregar Obra a Favoritos** → Marca obras que te interesen
20. **Obtener Mis Favoritos** → Lista de obras marcadas

## 🔑 Variables Clave

### Después de cada operación, guarda estos IDs:

```
✅ Después de Registro → Espera verificación email
✅ Después de Login → access_token y refresh_token se guardan automáticamente
✅ Después de "Crear Perfil Artista" → Obtén tu artist_id
✅ Después de "Crear Obra" → Obtén artwork_id
✅ Después de "Crear Subasta" → Obtén auction_id
```

**Para establecer variables manualmente:**
1. Click en el ojo (👁️) 
2. Busca la variable
3. Click en el valor y edita

## 📧 Verificación de Email

**Para obtener el token de verificación:**

1. Cuando ejecutes "Registro como Artista", el backend enviará un email
2. En desarrollo con SMTP:
   - Revisa la consola del servidor donde ves los logs
   - Busca: `Token generado: xxxxxxxx...`
3. Con Resend API:
   - Revisa tu email configurado (inbox o spam)
   - El link contiene el token en query param `?token=xxxxxx`

**En la request "Verificar Email":**
- Reemplaza `{{verification_token}}` con el token real
- Envía la request

## 🔄 Manejo de Tokens

### Auto-guardado de Tokens

Cuando haces **Login**, Postman automáticamente:
- Extrae `access_token` de la respuesta
- Guarda en la variable `{{access_token}}`
- Se usará en todas las requests autenticadas

### Cuando expira el token

Si ves error `401 Unauthorized`:
1. Ejecuta **Refresh Token** 
2. Proporciona el `refresh_token`
3. Obtendrás un nuevo `access_token` automáticamente

## 🛠️ Tips de Debugging

### Ver la respuesta completa
1. Ejecuta cualquier request
2. Abre la pestaña **Response**
3. Usa el botón **Pretty** para ver formato legible

### Ver IDs de respuestas
```
Respuesta típica:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",  ← Copia este ID
  "email": "artista@narinocultura.com",
  ...
}
```

### Copiar variables dinámicamente
Si quieres automatizar esto más:
1. Usa Scripts en Postman (Tests tab)
2. Ejemplo:
```javascript
if (pm.response.code === 201) {
    var jsonData = pm.response.json();
    pm.environment.set('artwork_id', jsonData.id);
}
```

## ❌ Errores Comunes

| Error | Solución |
|-------|----------|
| `400 Token inválido` | Usa el token correcto del email |
| `401 Unauthorized` | Haz login o refresca el token |
| `403 Permission denied` | El usuario no es ARTISTA |
| `404 Not found` | Verifica que el ID existe |
| `422 Unprocessable Entity` | Revisa los datos enviados |

## 📞 Contacto y Soporte

Para errores en email:
- Revisa `/narinocultura_backend/services/email_service.py`
- Confirma: `RESEND_API_KEY` o credenciales SMTP

Para otros errores:
- Consulta los logs del servidor
- Verifica las variables de entorno

---

**Versión:** 1.0 | **Última actualización:** Mayo 15, 2026
