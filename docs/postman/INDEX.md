# 📁 Índice - Carpeta Postman

## 📍 Ubicación
```
narinocultura_backend/
└── docs/
    └── postman/
        ├── Artista-Workflow.postman_collection.json    ← Colección Postman
        ├── Nariño-Cultura-Artista-Dev.postman_environment.json  ← Ambiente
        ├── INICIO-RAPIDO.md                            ← Comienza aquí
        ├── README-ARTISTA-WORKFLOW.md                  ← Guía detallada
        ├── URL-REFERENCE.md                            ← Tabla de URLs
        ├── PAYLOADS-EJEMPLOS.json                      ← Ejemplos JSON
        ├── artista-workflow.sh                         ← Script bash
        └── INDEX.md                                    ← Este archivo
```

---

## 🎯 ¿Por Dónde Empiezo?

### Si es tu primera vez:
1. Lee: **INICIO-RAPIDO.md** (5 minutos)
2. Importa: **Artista-Workflow.postman_collection.json** en Postman
3. Usa: El flujo paso a paso

### Si quieres referencia rápida:
1. Consulta: **URL-REFERENCE.md** (tabla de todas las URLs)
2. Mira ejemplos: **PAYLOADS-EJEMPLOS.json**

### Si prefieres terminal:
1. Ejecuta: **artista-workflow.sh**
2. Consulta: ejemplos de cURL al final

---

## 📄 Descripción de cada archivo

### 1. INICIO-RAPIDO.md
**Qué es:** Resumen ejecutivo de todo lo que necesitas

**Contiene:**
- ✅ Lista de archivos y qué hace cada uno
- ✅ 3 opciones para empezar
- ✅ Contenido organizado de la colección
- ✅ Variables automáticas
- ✅ Troubleshooting básico

**Cuándo leerlo:** PRIMERO

---

### 2. Artista-Workflow.postman_collection.json
**Qué es:** La colección principal de Postman

**Contiene:**
- ✅ 30+ requests HTTP
- ✅ Organizadas en 7 carpetas
- ✅ Headers pre-configurados
- ✅ Scripts para guardar tokens automáticamente
- ✅ Ejemplos de payloads

**Cómo importar:**
```
1. Abre Postman
2. Click "Import"
3. Selecciona este archivo
4. ¡Listo!
```

**Carpetas incluidas:**
- 1. Autenticación
- 2. Perfil de Usuario
- 3. Perfil de Artista
- 4. Obras de Arte
- 5. Subastas
- 6. Marketplace
- 7. Recuperación de Contraseña

---

### 3. Nariño-Cultura-Artista-Dev.postman_environment.json
**Qué es:** Variables pre-configuradas para Postman

**Contiene:**
- ✅ URL base (localhost:8000)
- ✅ URL producción (comentada)
- ✅ Credenciales de prueba
- ✅ Placeholders para IDs dinámicos

**Cómo importar:**
```
1. En Postman: Manage Environments
2. Click "Import"
3. Selecciona este archivo
4. Selecciona el ambiente antes de usar la colección
```

**Variables que se llenan automáticamente:**
- `access_token` (después de login)
- `refresh_token` (después de login)

---

### 4. README-ARTISTA-WORKFLOW.md
**Qué es:** Guía completa paso a paso

**Secciones:**
- Primeros pasos
- Configuración de variables
- Flujo de pruebas en 7 fases
- Manejo de tokens
- Tips de debugging
- Errores comunes y soluciones
- FAQ

**Cuándo leerlo:** Después de INICIO-RAPIDO

**Flujo recomendado (7 fases):**
1. Autenticación (registro, login)
2. Configurar perfil
3. Crear obras de arte
4. Subastas
5. Marketplace
6. Recuperación de contraseña

---

### 5. URL-REFERENCE.md
**Qué es:** Tabla de referencia rápida de TODOS los endpoints

**Contiene:**
- ✅ Tabla con método HTTP + endpoint
- ✅ Descripción de cada uno
- ✅ Ejemplos de payloads
- ✅ Códigos de respuesta
- ✅ Filtros disponibles
- ✅ Paginación y búsqueda

**Organizado por módulos:**
- Autenticación
- Usuario
- Artistas
- Obras de Arte
- Subastas
- Marketplace

**Cuándo consultarlo:** Cuando necesites encontrar un endpoint rápidamente

**Ejemplo:**
```
GET  /artists/                 Listar todos los artistas
POST /artists/                 Crear perfil de artista
GET  /artists/{id}/            Obtener detalle de artista
```

---

### 6. PAYLOADS-EJEMPLOS.json
**Qué es:** Archivo JSON con ejemplos de todos los payloads

**Contiene:**
- ✅ Estructura: endpoint, método, body, respuesta
- ✅ Notas sobre validaciones
- ✅ Restricciones y límites
- ✅ Headers requeridos
- ✅ Códigos de error

**Cómo usarlo:**
1. Busca el endpoint que necesitas
2. Copia el `body` del ejemplo
3. Pégalo en Postman
4. Personaliza los valores

**Ejemplo:**
```json
"crear_obra": {
  "title": "Tu título aquí",
  "description": "Tu descripción",
  "category_id": "uuid-aqui",
  "price": 2500000
}
```

**Ver en:**
- Editor JSON
- O abre con Postman

---

### 7. artista-workflow.sh
**Qué es:** Script bash para pruebas desde terminal

**Contiene:**
- ✅ Flujo automático completo
- ✅ Extrae IDs automáticamente
- ✅ Ejemplos de cURL para copiar
- ✅ No requiere Postman

**Requisitos:**
- Linux, Mac, o WSL en Windows
- `curl` instalado
- `jq` (para parsear JSON, opcional)

**Cómo usar:**
```bash
# Hacer ejecutable
chmod +x artista-workflow.sh

# Ejecutar
./artista-workflow.sh
```

**Qué hace:**
1. Registra nuevo artista
2. Pide que verifiques email
3. Hace login
4. Crea perfil de artista
5. Crea obra de arte
6. Crea subasta
7. Muestra IDs generados

**Al final imprime:**
- Comandos de cURL listos para copiar
- Ejemplos adicionales
- Resumen de IDs

---

## 🎯 Matriz de Decisión

| Situación | Archivo | Acción |
|-----------|---------|--------|
| Primera vez | INICIO-RAPIDO.md | Lee primero |
| Quiero usar Postman | Artista-Workflow.postman_collection.json | Importa |
| Necesito variables | Nariño-Cultura-Artista-Dev.postman_environment.json | Importa |
| Paso a paso detallado | README-ARTISTA-WORKFLOW.md | Lee secciones |
| Busco un endpoint | URL-REFERENCE.md | Busca en tabla |
| Necesito un payload | PAYLOADS-EJEMPLOS.json | Copia y adapta |
| Prefiero terminal | artista-workflow.sh | Ejecuta script |

---

## 🔄 Flujo Típico de Una Sesión

### Sesión 1: Configuración (15 min)
```
1. Lee INICIO-RAPIDO.md
2. Importa colección JSON
3. Importa ambiente JSON
4. Ejecuta "Registro como Artista"
5. Ejecuta "Login"
```

### Sesión 2+: Pruebas (variable)
```
1. Usa la colección organizada
2. Consulta URL-REFERENCE.md si necesitas un endpoint nuevo
3. Copia payloads de PAYLOADS-EJEMPLOS.json
4. Ejecuta requests
```

### Debugging
```
1. Revisa README-ARTISTA-WORKFLOW.md sección "Troubleshooting"
2. Consulta codes de error en URL-REFERENCE.md
3. Revisa los logs del servidor
```

---

## 💡 Tips de Uso

### Para no perder tokens:
- Postman guarda automáticamente `access_token` y `refresh_token`
- Están disponibles en `{{access_token}}` y `{{refresh_token}}`
- Se usan automáticamente en todas las requests

### Para reutilizar la colección:
- Los IDs (artist_id, artwork_id) debes copiarlos manualmente
- O use la variable environment personalizada
- O copia desde la respuesta de cada request

### Para trabajar en equipo:
- Comparte estos 7 archivos
- Cada persona importa la colección y el ambiente
- Todos usan las mismas URLs y estructura

### Para agregar más endpoints:
- Copia una request similar
- Cambiad el endpoint y método
- Personaliza el body
- Prueba

---

## 🆘 Preguntas Frecuentes

**P: ¿Dónde guardo mis pruebas?**
A: Postman guarda automáticamente en la colección

**P: ¿Puedo exportar mis resultados?**
A: Sí, Postman tiene opción de exportar colecciones y resultados

**P: ¿Necesito todos estos archivos?**
A: No. Con solo la colección JSON y el ambiente JSON puedes trabajar

**P: ¿Qué pasa si cambia la API?**
A: Actualiza URL-REFERENCE.md y la colección JSON

**P: ¿Cómo agrego nuevos endpoints?**
A: En Postman, click "+ New Request", sigue la estructura

**P: ¿Puedo usar estas colecciones en producción?**
A: Solo cambia la URL base al dominio de producción

---

## 📞 Soporte

**Si algo falla:**
1. Consulta README-ARTISTA-WORKFLOW.md → Troubleshooting
2. Verifica logs del servidor
3. Revisa que el backend esté corriendo
4. Confirma configuración de email

**Si encuentras errores:**
- Revisa el código de respuesta (200, 400, 401, etc.)
- Consulta PAYLOADS-EJEMPLOS.json para ver estructura esperada
- Verifica tokens en la sección de Headers

---

## 📊 Resumen Rápido

| Archivo | Tipo | Tamaño | Uso |
|---------|------|--------|-----|
| INICIO-RAPIDO.md | Markdown | ~5 KB | Orientación |
| Artista-Workflow.postman_collection.json | JSON | ~50 KB | Postman |
| Nariño-Cultura-Artista-Dev.postman_environment.json | JSON | ~2 KB | Postman |
| README-ARTISTA-WORKFLOW.md | Markdown | ~15 KB | Referencia |
| URL-REFERENCE.md | Markdown | ~20 KB | Consulta |
| PAYLOADS-EJEMPLOS.json | JSON | ~15 KB | Referencia |
| artista-workflow.sh | Shell | ~8 KB | Terminal |
| INDEX.md | Markdown | ~15 KB | Este archivo |

**Total:** ~130 KB de archivos de utilidad

---

**Versión:** 1.0  
**Fecha:** Mayo 15, 2026  
**Estado:** ✅ Completo

**Siguiente paso:** Abre [INICIO-RAPIDO.md](INICIO-RAPIDO.md)
