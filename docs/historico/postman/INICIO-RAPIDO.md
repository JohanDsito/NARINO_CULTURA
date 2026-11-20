# 📦 Archivos de Prueba Generados - Nariño Cultura

## ✅ Archivos Creados

Se han generado 5 archivos para facilitar las pruebas de API como **ARTISTA**:

### 1. **Artista-Workflow.postman_collection.json**
📍 Ubicación: `docs/postman/Artista-Workflow.postman_collection.json`

- **Descripción:** Colección completa de Postman con 30+ requests
- **Contenido:**
  - ✅ Autenticación (registro, login, logout, tokens)
  - ✅ Gestión de perfil de usuario
  - ✅ Perfil de artista
  - ✅ Creación y gestión de obras
  - ✅ Subastas y pujas
  - ✅ Marketplace y favoritos
  - ✅ Recuperación de contraseña

- **Cómo usar:**
  1. Abre Postman
  2. Click en **Import**
  3. Selecciona este archivo
  4. Las variables se auto-rellenan en el login

---

### 2. **Nariño-Cultura-Artista-Dev.postman_environment.json**
📍 Ubicación: `docs/postman/Nariño-Cultura-Artista-Dev.postman_environment.json`

- **Descripción:** Archivo de ambiente pre-configurado
- **Contiene:**
  - Variables de desarrollo (localhost:8000)
  - Variables de producción (comentadas)
  - Credenciales de prueba
  - IDs dinámicos para guardar respuestas

- **Cómo usar:**
  1. En Postman, click en el icono de ojo (👁️)
  2. Click en **Manage Environments**
  3. Click en **Import**
  4. Selecciona este archivo

---

### 3. **README-ARTISTA-WORKFLOW.md**
📍 Ubicación: `docs/postman/README-ARTISTA-WORKFLOW.md`

- **Descripción:** Guía completa paso a paso
- **Secciones:**
  - Cómo importar la colección
  - Configuración de variables
  - Flujo recomendado de 7 fases
  - Manejo de tokens
  - Tips de debugging
  - Errores comunes y soluciones

- **Ideal para:** Primeros pasos y referencia rápida

---

### 4. **artista-workflow.sh**
📍 Ubicación: `docs/postman/artista-workflow.sh`

- **Descripción:** Script de shell con ejemplos de cURL
- **Características:**
  - Flujo automático de registro, login, creación de contenido
  - Extrae IDs automáticamente
  - Proporciona ejemplos de comandos adicionales
  - No requiere Postman, usa terminal/bash

- **Cómo usar (en Linux/Mac):**
  ```bash
  chmod +x artista-workflow.sh
  ./artista-workflow.sh
  ```

- **En Windows (PowerShell):**
  ```powershell
  # Copiar comandos manualmente o usar WSL
  ```

---

### 5. **URL-REFERENCE.md**
📍 Ubicación: `docs/postman/URL-REFERENCE.md`

- **Descripción:** Tabla de referencia rápida de todos los endpoints
- **Contiene:**
  - Todos los endpoints por módulo
  - Métodos HTTP
  - Descripciones
  - Ejemplos de payloads JSON
  - Códigos de respuesta
  - Filtros y búsqueda
  - Ejemplos de paginación

- **Ideal para:** Consulta rápida durante desarrollo

---

## 🚀 Primeros Pasos Recomendados

### Opción A: Usar Postman (Recomendado)
```
1. Abre Postman
2. Importa: Artista-Workflow.postman_collection.json
3. Importa: Nariño-Cultura-Artista-Dev.postman_environment.json
4. Lee: README-ARTISTA-WORKFLOW.md
5. Comienza por la carpeta "1. Autenticación"
```

### Opción B: Usar cURL desde terminal
```
1. Abre terminal/bash
2. Ejecuta: ./artista-workflow.sh
3. Usa comandos adicionales del final del script
4. Consulta: URL-REFERENCE.md para más endpoints
```

### Opción C: Referencia rápida
```
1. Abre: URL-REFERENCE.md
2. Copia URLs que necesites
3. Haz requests con tu herramienta favorita
```

---

## 📊 Contenido de la Colección

### Carpeta 1: Autenticación (5 requests)
- Registro como Artista
- Verificar Email
- Login
- Refresh Token
- Logout

### Carpeta 2: Perfil de Usuario (3 requests)
- Obtener Mi Perfil
- Actualizar Mi Perfil
- Cambiar Contraseña

### Carpeta 3: Perfil de Artista (4 requests)
- Listar Artistas
- Obtener Detalle de Artista
- Crear/Actualizar Perfil
- Obtener Mi Perfil de Artista

### Carpeta 4: Obras de Arte (6 requests)
- Listar Categorías
- Listar Obras
- Obtener Detalle
- Crear Nueva Obra
- Actualizar Obra
- Listar Mis Obras

### Carpeta 5: Subastas (5 requests)
- Listar Subastas
- Obtener Detalle
- Crear Nueva Subasta
- Hacer Una Puja
- Listar Mis Subastas

### Carpeta 6: Marketplace (6 requests)
- Obtener Carrito
- Agregar al Carrito
- Listar Mis Órdenes
- Ver Mis Ventas
- Agregar a Favoritos
- Obtener Favoritos

### Carpeta 7: Recuperación de Contraseña (2 requests)
- Solicitar Reset
- Confirmar Reset

---

## 🔑 Variables Automáticas

Postman automáticamente:
- ✅ Guarda `access_token` después de login
- ✅ Guarda `refresh_token` después de login
- ✅ Usa estos tokens en todas las requests autenticadas
- ✅ Se puede usar `{{variable}}` en cualquier request

---

## 📝 Notas Importantes

### Variables que debes llenar manualmente:
1. `{{artist_id}}` - Después de crear perfil de artista
2. `{{artwork_id}}` - Después de crear una obra
3. `{{auction_id}}` - Después de crear una subasta
4. `{{category_id}}` - Obtenido al listar categorías
5. `{{verification_token}}` - Del email de verificación

### Flujo de verificación de email:
1. Ejecuta "Registro como Artista"
2. Revisa logs del servidor o email
3. Copia el token
4. En "Verificar Email", reemplaza `{{verification_token}}`
5. Ejecuta la request

### Configuración requerida:
- Backend corriendo en `http://localhost:8000`
- Base de datos disponible (SQLite o PostgreSQL)
- Email configurado (SMTP o Resend)

---

## 🆘 Troubleshooting

### ❌ Error: 401 Unauthorized
**Solución:** Ejecuta Login primero, los tokens se guardarán automáticamente

### ❌ Error: 404 Not Found
**Solución:** Verifica que el ID existe y usa la variable correcta (ej: `{{artwork_id}}`)

### ❌ Error: Email de verificación no llega
**Solución:**
- Verifica la consola del servidor (busca "Token")
- Si usas Resend, revisa spam
- Consulta configuración en `base.py`

### ❌ Error: 422 Unprocessable Entity
**Solución:** Revisa los datos que estás enviando, algún campo tiene formato incorrecto

---

## 📞 Dudas Frecuentes

**P: ¿Puedo usar estos archivos en producción?**
A: Cambia la URL base en el ambiente a tu dominio de producción

**P: ¿Cómo agrego más variables?**
A: En Postman, click en ojo (👁️) → edita las variables que necesites

**P: ¿Qué pasa si expira mi token?**
A: Ejecuta "Refresh Token" con el refresh_token

**P: ¿Puedo compartir estos archivos con mi equipo?**
A: Sí, son archivos JSON estándar de Postman. Solo cambien URLs según su servidor.

---

**Versión:** 1.0  
**Fecha:** Mayo 15, 2026  
**Estado:** ✅ Completo y listo para usar

Para más detalles, consulta los archivos README y URL-REFERENCE en la carpeta `/docs/postman/`
