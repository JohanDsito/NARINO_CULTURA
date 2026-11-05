"""Genera la colección de Postman de la prueba de humo (HU-B13).

Uso (desde la raíz del repositorio):
    python docs/api/postman/generar_prueba_humo.py

Crea NarinoCultura-PruebaHumo.postman_collection.json junto a este archivo.
"""
import json
import uuid
from pathlib import Path

OUT = Path(__file__).with_name("NarinoCultura-PruebaHumo.postman_collection.json")


def script(lines):
    return {"type": "text/javascript", "exec": lines}


def req(name, method, path, token=None, body=None, tests=None, prerequest=None, description=""):
    headers = [{"key": "Content-Type", "value": "application/json"}]
    if token:
        headers.append({"key": "Authorization", "value": "Bearer {{%s}}" % token})
    segments = [p for p in path.strip("/").split("/") if p]
    if path.endswith("/"):
        segments.append("")
    item = {
        "name": name,
        "request": {
            "method": method,
            "header": headers,
            "url": {"raw": "{{base_url}}" + path, "host": ["{{base_url}}"], "path": segments},
            "description": description,
        },
        "event": [],
    }
    if body is not None:
        item["request"]["body"] = {
            "mode": "raw",
            "raw": json.dumps(body, ensure_ascii=False, indent=2),
            "options": {"raw": {"language": "json"}},
        }
    if prerequest:
        item["event"].append({"listen": "prerequest", "script": script(prerequest)})
    if tests:
        item["event"].append({"listen": "test", "script": script(tests)})
    return item


def status_test(code):
    return [f'pm.test("HTTP {code}", () => pm.response.to.have.status({code}));']


def save(var, expr):
    return [f'if (pm.response.code < 300) {{ pm.collectionVariables.set("{var}", {expr}); console.log("{var} =", {expr}); }}']


def list_contains(title_text):
    return [
        "const body = pm.response.json();",
        "const items = Array.isArray(body) ? body : (body.results || []);",
        f'pm.test("La bandeja contiene: {title_text}", () => pm.expect(items.map(n => n.title)).to.include("{title_text}"));',
    ]


CHECKOUT = [
    "const d = pm.response.json();",
    "const params = new URLSearchParams({",
    '  "public-key": d.public_key, "currency": d.currency,',
    '  "amount-in-cents": String(d.amount_in_cents), "reference": d.reference,',
    '  "signature:integrity": d.integrity_signature,',
    "});",
    'const url = "https://checkout.wompi.co/p/?" + params.toString();',
    'pm.collectionVariables.set("checkout_url", url);',
    'pm.test("La llave es de pruebas (sandbox)", () => pm.expect(d.public_key).to.include("_test_"));',
    'console.log("Abre este enlace para pagar:", url);',
    "pm.visualizer.set(`<h3>Pagar en Wompi (sandbox)</h3>",
    '<p><a href="{{url}}" target="_blank">Abrir el Web Checkout de Wompi</a></p>',
    "<p>Tarjeta de prueba aprobada: <b>4242 4242 4242 4242</b>, cualquier fecha futura y CVC.</p>",
    "<p>Monto: {{amount}} COP · Referencia (orden): {{ref}}</p>`,",
    "  { url, amount: d.amount_in_cents / 100, ref: d.reference });",
]

AUCTION_TIMES = [
    "const now = new Date();",
    'const minutes = parseInt(pm.collectionVariables.get("auction_minutes") || "10", 10);',
    'pm.collectionVariables.set("auction_starts_at", now.toISOString());',
    'pm.collectionVariables.set("auction_ends_at", new Date(now.getTime() + minutes * 60000).toISOString());',
]

LOGIN = "/api/v1/auth/login/"
REGISTER = "/api/v1/auth/register/"
NOTIFICATIONS = "/api/v1/notifications/"

items = [
    {"name": "0. Salud", "item": [req("Health check", "GET", "/health/", tests=status_test(200))]},
    {
        "name": "1. Cuentas",
        "description": (
            "Registra el artista y dos compradores con correos reales (llega el enlace de verificación). "
            "Copia el token del enlace en verify_token y ejecuta 'Verificar correo' una vez por cuenta."
        ),
        "item": [
            req("Registrar artista", "POST", REGISTER,
                body={"email": "{{artist_email}}", "password": "{{password}}", "first_name": "Artista", "last_name": "Prueba", "role": "ARTISTA"},
                tests=status_test(201)),
            req("Registrar comprador 1", "POST", REGISTER,
                body={"email": "{{buyer1_email}}", "password": "{{password}}", "first_name": "Ana", "last_name": "Compradora", "role": "COMPRADOR"},
                tests=status_test(201)),
            req("Registrar comprador 2", "POST", REGISTER,
                body={"email": "{{buyer2_email}}", "password": "{{password}}", "first_name": "Luis", "last_name": "Comprador", "role": "COMPRADOR"},
                tests=status_test(201)),
            req("Verificar correo (repetir por cuenta)", "POST", "/api/v1/auth/verify-email/", body={"token": "{{verify_token}}"},
                tests=status_test(200),
                description="El token está al final del enlace del correo de verificación: ...?token=ESTE_VALOR"),
            req("Login admin", "POST", LOGIN, body={"email": "{{admin_email}}", "password": "{{admin_password}}"},
                tests=status_test(200) + save("admin_token", "pm.response.json().access")),
            req("Login artista", "POST", LOGIN, body={"email": "{{artist_email}}", "password": "{{password}}"},
                tests=status_test(200) + save("artist_token", "pm.response.json().access")),
            req("Login comprador 1", "POST", LOGIN, body={"email": "{{buyer1_email}}", "password": "{{password}}"},
                tests=status_test(200) + save("buyer1_token", "pm.response.json().access")),
            req("Login comprador 2", "POST", LOGIN, body={"email": "{{buyer2_email}}", "password": "{{password}}"},
                tests=status_test(200) + save("buyer2_token", "pm.response.json().access")),
        ],
    },
    {
        "name": "2. Obras",
        "item": [
            req("Crear perfil de artista", "POST", "/api/v1/artists/", "artist_token",
                {"artistic_name": "Artista Prueba Humo", "discipline": "Pintura", "city": "Pasto"}, tests=status_test(201)),
            req("Crear obra para venta directa", "POST", "/api/v1/artworks/", "artist_token",
                {"title": "Obra venta directa (prueba)", "description": "Obra de la prueba de humo", "technique": "Óleo", "price": "50000.00"},
                tests=status_test(201) + save("artwork_sale_id", "pm.response.json().id")),
            req("Crear obra para subasta", "POST", "/api/v1/artworks/", "artist_token",
                {"title": "Obra subasta (prueba)", "description": "Obra de la prueba de humo", "technique": "Acuarela", "price": "100000.00"},
                tests=status_test(201) + save("artwork_auction_id", "pm.response.json().id")),
            req("Admin aprueba obra de venta", "PATCH", "/api/v1/admin/artworks/{{artwork_sale_id}}/moderate/", "admin_token",
                {"status": "DISPONIBLE"}, tests=status_test(200)),
            req("Admin aprueba obra de subasta", "PATCH", "/api/v1/admin/artworks/{{artwork_auction_id}}/moderate/", "admin_token",
                {"status": "DISPONIBLE"}, tests=status_test(200)),
        ],
    },
    {
        "name": "3. Compra directa + Wompi",
        "item": [
            req("Comprador 1 agrega al carrito", "POST", "/api/v1/marketplace/cart/items/", "buyer1_token",
                {"artwork_id": "{{artwork_sale_id}}"}, tests=status_test(201)),
            req("Checkout", "POST", "/api/v1/marketplace/checkout/", "buyer1_token", {"order_type": "COMPRA_DIRECTA"},
                tests=status_test(201) + save("order_id", "pm.response.json().order_id")),
            req("Iniciar pago (genera enlace de Wompi)", "POST", "/api/v1/payments/initiate/", "buyer1_token", {"order_id": "{{order_id}}"},
                tests=status_test(201) + CHECKOUT,
                description=(
                    "Abre la pestaña 'Visualize' de la respuesta (o la consola) y paga en el enlace con la tarjeta "
                    "4242 4242 4242 4242. Espera unos segundos y sigue con la verificación."
                )),
            req("Verificar orden PAGADO", "GET", "/api/v1/marketplace/orders/", "buyer1_token", tests=[
                "const body = pm.response.json(); const items = Array.isArray(body) ? body : (body.results || []);",
                'const o = items.find(x => x.id === pm.collectionVariables.get("order_id"));',
                'pm.test("La orden existe", () => pm.expect(o).to.exist);',
                'pm.test("La orden quedó PAGADO (webhook de Wompi recibido)", () => pm.expect(o.status).to.eql("PAGADO"));',
            ]),
            req("Ver transacción", "GET", "/api/v1/payments/transactions/", "buyer1_token", tests=status_test(200)),
            req("Bandeja comprador 1: Pago confirmado", "GET", NOTIFICATIONS, "buyer1_token",
                tests=status_test(200) + list_contains("Pago confirmado")),
            req("Bandeja artista: Vendiste una obra", "GET", NOTIFICATIONS, "artist_token",
                tests=status_test(200) + list_contains("¡Vendiste una obra!")),
        ],
    },
    {
        "name": "4. Subasta",
        "item": [
            req("Artista crea subasta", "POST", "/api/v1/auctions/", "artist_token",
                {"artwork": "{{artwork_auction_id}}", "base_price": "100000.00", "starts_at": "{{auction_starts_at}}", "ends_at": "{{auction_ends_at}}"},
                prerequest=AUCTION_TIMES,
                tests=status_test(201) + save("auction_id", "pm.response.json().id")
                + ['pm.test("Queda PENDIENTE de aprobación", () => pm.expect(pm.response.json().status).to.eql("PENDIENTE"));']),
            req("Bandeja admin: subasta pendiente", "GET", NOTIFICATIONS, "admin_token",
                tests=status_test(200) + list_contains("Subasta pendiente de aprobación")),
            req("Admin aprueba subasta", "POST", "/api/v1/auctions/{{auction_id}}/approve/", "admin_token", {}, tests=status_test(200)),
            req("Comprador 1 puja 110.000", "POST", "/api/v1/auctions/{{auction_id}}/bid/", "buyer1_token", {"amount": "110000.00"},
                tests=status_test(201)),
            req("Comprador 2 puja 120.000", "POST", "/api/v1/auctions/{{auction_id}}/bid/", "buyer2_token", {"amount": "120000.00"},
                tests=status_test(201)),
            req("Seguridad: puja menor rechazada", "POST", "/api/v1/auctions/{{auction_id}}/bid/", "buyer1_token", {"amount": "115000.00"},
                tests=status_test(400)),
            req("Seguridad: el vendedor no puede pujar", "POST", "/api/v1/auctions/{{auction_id}}/bid/", "artist_token", {"amount": "200000.00"},
                tests=status_test(400)),
            req("Seguridad: comprador no puede editar la subasta", "PATCH", "/api/v1/auctions/{{auction_id}}/", "buyer1_token",
                {"base_price": "1.00"}, tests=status_test(403)),
            req("Bandeja comprador 1: te superaron", "GET", NOTIFICATIONS, "buyer1_token",
                tests=status_test(200) + list_contains("Te superaron en una subasta")),
            req("Bandeja artista: nueva puja", "GET", NOTIFICATIONS, "artist_token",
                tests=status_test(200) + list_contains("Nueva puja en tu subasta")),
            req("[Tras el cierre] Ver subasta como ganador", "GET", "/api/v1/auctions/{{auction_id}}/", "buyer2_token", tests=[
                "const a = pm.response.json();",
                'pm.test("Cerró sola (Celery Beat)", () => pm.expect(a.status).to.eql("CERRADA"));',
                'pm.test("El ganador ve su orden de pago", () => pm.expect(a.payment_order_id).to.be.a("string"));',
                'if (a.payment_order_id) pm.collectionVariables.set("winner_order_id", a.payment_order_id);',
            ], description="Ejecútalo cuando haya pasado auction_minutes: el worker cierra la subasta menos de un minuto después de vencer."),
            req("[Tras el cierre] Bandeja ganador: ¡Ganaste!", "GET", NOTIFICATIONS, "buyer2_token",
                tests=status_test(200) + list_contains("¡Ganaste la subasta!")),
            req("[Tras el cierre] Ganador inicia pago", "POST", "/api/v1/payments/initiate/", "buyer2_token", {"order_id": "{{winner_order_id}}"},
                tests=status_test(201) + CHECKOUT),
        ],
    },
    {
        "name": "5. Revisión (admin)",
        "item": [
            req("Registro de notificaciones (estado de los correos)", "GET", "/api/v1/admin/notifications/log/", "admin_token",
                tests=status_test(200)),
            req("Transacciones", "GET", "/api/v1/admin/transactions/", "admin_token", tests=status_test(200)),
        ],
    },
]

variables = {
    "base_url": "https://narinocultura-production.up.railway.app",
    "admin_email": "",
    "admin_password": "",
    "artist_email": "",
    "buyer1_email": "",
    "buyer2_email": "",
    "password": "",
    "verify_token": "",
    "auction_minutes": "10",
}
for computed in ("admin_token", "artist_token", "buyer1_token", "buyer2_token", "artwork_sale_id", "artwork_auction_id",
                 "order_id", "checkout_url", "auction_id", "auction_starts_at", "auction_ends_at", "winner_order_id"):
    variables[computed] = ""

collection = {
    "info": {
        "_postman_id": str(uuid.uuid4()),
        "name": "Nariño Cultura — Prueba de humo (HU-B13)",
        "description": (
            "Flujo de punta a punta contra el backend desplegado, sin frontend.\n\n"
            "1. En las variables de la colección completa los correos (pueden ser alias de Gmail: tu_correo+artista@gmail.com), "
            "una contraseña para las cuentas nuevas y las credenciales del administrador.\n"
            "2. Ejecuta las carpetas en orden, de arriba hacia abajo.\n"
            "3. El pago se hace en el Web Checkout de Wompi (sandbox): la petición 'Iniciar pago' arma el enlace.\n"
            "4. La subasta cierra sola: espera auction_minutes y ejecuta las peticiones '[Tras el cierre]'.\n\n"
            "WebSocket (opcional): en Postman, New → WebSocket → "
            "wss://narinocultura-production.up.railway.app/ws/auctions/{{auction_id}}/ "
            "para ver llegar bid_placed y auction_closed en vivo."
        ),
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    },
    "item": items,
    "variable": [{"key": k, "value": v, "type": "string"} for k, v in variables.items()],
}

if __name__ == "__main__":
    OUT.write_text(json.dumps(collection, ensure_ascii=False, indent=2), encoding="utf-8")
    total = sum(len(folder["item"]) for folder in items)
    print(f"{total} peticiones -> {OUT}")
