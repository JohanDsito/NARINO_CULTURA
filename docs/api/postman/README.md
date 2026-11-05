# Prueba de humo con Postman (HU-B13)

Recorre de punta a punta el backend desplegado, sin necesidad del frontend: cuentas, obras, compra directa con Wompi (sandbox), subasta completa con cierre automático, notificaciones y revisión del administrador.

## Generar e importar

```bash
python docs/api/postman/generar_prueba_humo.py
```

Crea `NarinoCultura-PruebaHumo.postman_collection.json`. En Postman: **Import** → ese archivo.

## Usar

1. En las **variables de la colección** completa `admin_email`, `admin_password`, `artist_email`, `buyer1_email`, `buyer2_email` y `password`. Los correos pueden ser alias de Gmail (`tucorreo+artista@gmail.com`).
2. Ejecuta las carpetas en orden, por tramos (hay pasos manuales):
   - **1–4:** registro de cuentas. Luego verifica cada correo copiando el `token` del enlace en `verify_token`.
   - **6–17:** logins, obras, carrito e "Iniciar pago". Paga en el enlace de la pestaña **Visualize** con la tarjeta de prueba `4242 4242 4242 4242`.
   - **18–21:** verificación del pago y de las notificaciones.
   - **Subasta:** hasta "Bandeja artista: nueva puja". Espera `auction_minutes` y ejecuta las peticiones **[Tras el cierre]**.
   - **5. Revisión (admin):** registro de correos y transacciones.

Para ver las pujas en vivo: **New → WebSocket** → `wss://<backend>/ws/auctions/<auction_id>/`.

Resultado de la ejecución del 5 de noviembre de 2026 en producción: todos los flujos pasaron (compra, pago, comprobante, subasta con cierre automático y correos).
