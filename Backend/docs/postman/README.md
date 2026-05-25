# Pruebas de API con Postman

Importa la colección [NARINO_CULTURA.postman_collection.json](C:\Users\Usuario\Desktop\NARINO_CULTURA\docs\postman\NARINO_CULTURA.postman_collection.json) en Postman.

## Variables importantes

- `baseUrl`: `http://localhost:8000/api/v1`
- `accessToken`: se llena después de `Login`
- `refreshToken`: se llena después de `Login`
- `verifyToken`: pégalo desde el correo de verificación
- `resetToken`: pégalo desde el correo de recuperación
- `artistSlug`, `artworkId`, `auctionId`, `eventId`, `orderId`, `transactionId`: llénalos con ids reales de respuestas anteriores

## Flujo recomendado de pruebas

1. `Auth > Register`
2. `Auth > Verify Email`
3. `Auth > Login`
4. `Auth > Me`
5. Si el usuario es artista:
   `Artists > Create Artist Profile`
6. `Artworks > List Categories`
7. `Artworks > Create Artwork`
8. `Marketplace > Add Item To Cart`
9. `Marketplace > Checkout`
10. `Payments > Initiate Payment`

## Roles sugeridos para probar

- `ARTISTA`: crear perfil, obras, subastas, ver ventas
- `COMPRADOR`: favoritos, carrito, checkout, pujas, eventos
- `GESTOR_CULTURAL`: crear y editar eventos
- `ADMINISTRADOR`: moderación, métricas, logs y transacciones

## Notas útiles

- Casi todo usa `Authorization: Bearer {{accessToken}}`
- Las rutas de `artists`, `artworks`, `auctions` y `events` vienen de `ViewSet`, por eso aceptan list/retrieve/create/update
- `Verify Email` y `Confirm Password Reset` necesitan tokens reales
- Si quieres probar varios roles, duplica el request `Register` y cambia email/role
- El proyecto ahora siembra categorias base de obras mediante migracion. Si no aparecen, ejecuta nuevamente `python manage.py migrate` en el backend y vuelve a consultar `GET /artworks/categories/`
