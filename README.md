# Products Launcher

Repositorio que reúne y levanta todo el proyecto de microservicios con **NestJS** (curso [NestJS + Microservicios](https://www.udemy.com/course/nestjs-microservicios/), Udemy, DevTalles). Los servicios viven en repositorios independientes y aquí se enlazan como **submódulos de Git**, junto con el `docker-compose.yml` que los ejecuta.

> Proyecto de práctica completado y desplegado en **Google Kubernetes Engine (GKE Autopilot)** con Helm, un Ingress único y pagos con Stripe en modo de prueba.

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
| `payments-ms` | [payments-ms](https://github.com/developer-ortega-microservicios/payments-ms) | Pagos con Stripe Checkout y webhooks |
| `auth-ms` | [auth-ms](https://github.com/developer-ortega-microservicios/auth-ms) | Autenticación con JWT, bcrypt, Prisma y MongoDB |
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

2. Crear el archivo `.env` a partir del ejemplo y completar los valores (PostgreSQL con letras y números, sin caracteres especiales; claves de Stripe **de prueba**; cadena de MongoDB y `JWT_SECRET` para `auth-ms`):
   ```bash
   cp .env.example .env
   ```
   > El `.env` está en `.gitignore`: nunca se sube. Solo se versiona `.env.example`, sin valores reales.

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

## Despliegue en Kubernetes

Los charts de Helm están en `k8s/`:

| Chart | Destino | Notas |
|-------|---------|-------|
| `k8s/tienda` | Kubernetes local (Docker Desktop) | Servicios `NodePort`, `imagePullSecrets` para Artifact Registry |
| `k8s/tienda-gke` | GKE Autopilot | Servicios `ClusterIP` + un solo **Ingress** (`/payments/*` → payments-ms, `/*` → client-gateway), health checks por `readinessProbe` y requests de recursos reducidos |

Flujo de despliegue en GKE:

1. Construir y subir las imágenes a **Artifact Registry** con Cloud Build (`cloudbuild.yml` en cada servicio) o con `docker build` + `docker push`.
2. Crear los secrets en el clúster (no se versionan):
   ```bash
   kubectl create secret generic payments-secrets --from-literal=STRIPE_SECRET=... --from-literal=STRIPE_ENDPOINT_SECRET=...
   kubectl create secret generic auth-secrets --from-literal=DATABASE_URL=... --from-literal=JWT_SECRET=...
   kubectl create secret generic orders-secrets --from-literal=database_url=...
   ```
3. Instalar el chart:
   ```bash
   cd k8s
   helm install tienda-gke ./tienda-gke
   kubectl get ingress   # esperar a que aparezca la IP pública
   ```
4. Poner esa IP en `STRIPE_SUCCESS_URL` / `STRIPE_CANCEL_URL` del deployment de `payments-ms`, ejecutar `helm upgrade tienda-gke ./tienda-gke` y crear en Stripe (modo prueba) un webhook hacia `http://<IP>/payments/webhook` con el evento `charge.succeeded`.

Comandos útiles de Helm y kubectl en [K8s.README.md](K8s.README.md).

> La IP del Ingress es efímera: si se recrea, hay que actualizar las URLs y el webhook. Al terminar de probar: `helm uninstall tienda-gke` y borrar el clúster para evitar costos.

## Seguridad

- Los `.env` están ignorados en el launcher y en cada microservicio; solo se suben los `.env.example`.
- Los secrets de Kubernetes se crean con `kubectl`, nunca como archivos del repositorio.
- La llave JSON de la cuenta de servicio de Google Cloud debe guardarse fuera del repositorio.
- Stripe se usa solo en **modo de prueba**.

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

NestJS · TypeScript · Prisma · NATS · PostgreSQL · MongoDB · SQLite · JWT · Stripe · Docker · Kubernetes (GKE) · Helm · Google Cloud Build · Artifact Registry
