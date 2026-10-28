# Products Launcher

Repositorio que reúne y levanta todo el proyecto de microservicios con **NestJS** (curso [NestJS + Microservicios](https://www.udemy.com/course/nestjs-microservicios/), Udemy, DevTalles). Los servicios viven en repositorios independientes y aquí se enlazan como **submódulos de Git**, junto con el `docker-compose.yml` que los ejecuta.

> Proyecto de práctica, **en progreso**. Se actualiza a medida que avanza el curso.

## Arquitectura

```
Cliente HTTP
     │
     ▼
client-gateway :3000 ──NATS (:4222)──→ products-ms (SQLite)
                     ├─────────────→ orders-ms ──→ PostgreSQL (orders-db :5432)
                     ├─────────────→ payments-ms ──→ Stripe (webhooks)
                     └─────────────→ auth-ms ──→ MongoDB
```

| Servicio | Repositorio | Descripción |
|----------|-------------|-------------|
| `client-gateway` | [client-gateway](https://github.com/developer-ortega-microservicios/client-gateway) | API Gateway: único punto de entrada HTTP |
| `products-ms` | [products-ms](https://github.com/developer-ortega-microservicios/products-ms) | Microservicio de productos (Prisma + SQLite) |
| `orders-ms` | [orders-ms](https://github.com/developer-ortega-microservicios/orders-ms) | Microservicio de órdenes (Prisma + PostgreSQL) |
| `payments-ms` | [payments-ms](https://github.com/developer-ortega-microservicios/payments-ms) | Pagos con Stripe y webhooks (en desarrollo) |
| `auth-ms` | [auth-ms](https://github.com/developer-ortega-microservicios/auth-ms) | Autenticación con JWT, bcrypt, Prisma y MongoDB (en desarrollo) |
| `nats-server` | imagen `nats` | Bus de mensajes entre servicios |
| `orders-db` | imagen `postgres:16.2` | Base de datos de órdenes |

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (incluye Docker Compose)
- [Git](https://git-scm.com/)

## Cómo levantarlo

1. Clonar el repositorio **con sus submódulos**:
   ```bash
   git clone --recurse-submodules https://github.com/developer-ortega-microservicios/products-launcher.git
   cd products-launcher
   ```
   Si ya lo clonaste sin submódulos:
   ```bash
   git submodule update --init --recursive
   ```

2. Crear el archivo `.env` a partir del ejemplo y completar la contraseña de PostgreSQL (usar letras y números, sin caracteres especiales):
   ```bash
   cp .env.example .env
   ```
   ```
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=tu_clave
   POSTGRES_DB=ordersdb
   ```

3. Construir y levantar todos los servicios:
   ```bash
   docker compose up --build
   ```

Al arrancar, `products-ms` y `orders-ms` generan el cliente de Prisma y aplican sus migraciones automáticamente.

## Probar la API

Con todo corriendo, el gateway queda en `http://localhost:3000/api`:

| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/products` | Crear un producto |
| GET | `/api/products?page=1&limit=10` | Listar productos |
| POST | `/api/orders` | Crear una orden (valida los productos con `products-ms`) |
| GET | `/api/orders` | Listar órdenes |
| PATCH | `/api/orders/:id` | Cambiar el estado de una orden |

Ejemplo para crear una orden:

```json
{
  "items": [
    { "productId": 1, "quantity": 2, "price": 100 }
  ]
}
```

## Trabajar con los submódulos

Los submódulos apuntan a un commit concreto de cada servicio. Para traer los últimos cambios de todos:

```bash
git submodule update --remote --merge
git add .
git commit -m "chore: actualizar submódulos"
git push
```

Para modificar un servicio, entra a su carpeta (`cd orders-ms`), haz commit y push **en ese repositorio**, y luego actualiza la referencia aquí.

## Comandos útiles

```bash
docker compose up -d --build            # Levantar en segundo plano
docker compose logs -f orders-ms        # Ver logs de un servicio
docker compose up --build orders-ms     # Reconstruir un solo servicio
docker compose down                     # Apagar (conserva los datos de PostgreSQL)
docker compose down -v                  # Apagar y borrar los datos
```

## Stack técnico

NestJS · TypeScript · Prisma · NATS · PostgreSQL · SQLite · Docker Compose
