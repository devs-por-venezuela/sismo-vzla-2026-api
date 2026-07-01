# SismoVZLA App - Backend API (Cloudflare Workers)

Esta es la API que sirve de puente entre la aplicación móvil/web y la base de datos SQLite en Cloudflare Workers.

## 🚀 Características Principales

- **API Delta Sync**: Optimización para móviles. No descarga la base de datos completa. Consulta solo los cambios desde la última sincronización.
- **Gestión de Inventario**: Rutas para reportar heridos, fallecidos, insumos y necesidades.
- **Facilities Management**: CRUD básico para los centros de acopio.
- **Reporte de Incidentes**: Módulo dedicado a reportar afectaciones y emergencias.

## 🛠️ Tecnologías

- **Runtime**: Cloudflare Workers (V8)
- **Base de Datos**: D1 (SQLite)
- **Almacenamiento**: R2 (para archivos estáticos/JSON)
- **Framework**: Hono
- **Linguaje**: TypeScript

## 📦 Estructura de Tablas (Bases)

La base de datos está segmentada para mejor rendimiento:

1. **users**: Autenticación de usuarios.
2. **facilities**: Centros de acopio, hospitales, refugios.
3. **center_stock**: Inventario en tiempo real por centro.
4. **item_categories** & **items**: Catálogo de bienes.
5. **inventory_movements**: Historial de movimientos de inventario.
6. **incidents**: Reportes de emergencias por ciudadanos.
7. **victims**: Reporte de víctimas (heridos/fallecidos) asociados a incidentes.
8. **reports**: Reportes generales de afectaciones.

## 🔌 Endpoints Disponibles

### 📡 Lectura y Sincronización

- `GET /api/data`: Descarga masiva (Full Sync). Útil para la carga inicial.
- `GET /api/sync?since=YYYY-MM-DD HH:MM:SS`: Descarga incremental (Delta Sync). **Recomendado**.

### 📦 Inventario y Suministros

- `GET /api/inventory/centers`: Listar centros de acopio.
- `GET /api/inventory/categories`: Listar categorías de insumos.
- `GET /api/inventory/items?center_id=X`: Listar ítems por centro.
- `POST /api/inventory/movements`: Registrar entrada o salida de productos.

### 🏥 Instalaciones y Facilities

- `GET /api/facilities`: Listar instalaciones.
- `POST /api/facilities`: Crear nueva instalación.
- `PUT /api/facilities/:id`: Actualizar instalación.
- `GET /api/facilities/types`: Listar tipos (hospital, refugio, etc.).

### 🚨 Reportes de Incidentes

- `POST /api/incidents`: Reportar un incidente.
- `POST /api/incidents/:id/victims`: Reportar víctimas asociadas al incidente.
- `GET /api/incidents`: Listar incidentes.
- `GET /api/incidents/:id`: Ver detalle de un incidente.

## 🏃 Despliegue

1. **Configuración de Variables de Entorno**:
   El archivo `wrangler.toml` no se incluye en el repositorio para evitar exponer credenciales. En su lugar, copia el archivo de ejemplo y configúralo con tus credenciales:

   ```bash
   cp .env.local.example .env.local
   ```

   Luego edita `.env.local` e introduce el ID de tu base de datos y nombre del bucket de R2.

2. **Generar Configuración de Wrangler**:

   Para compilar el archivo `wrangler.toml` con las variables definidas en tu entorno local:

   ```bash
   npm run config
   ```

   *(Nota: Este script se ejecuta automáticamente al iniciar en modo desarrollo o realizar un despliegue).*

3. **Ejecutar en Desarrollo**:

   Para correr el servidor localmente con recarga en vivo (hot-reload):

   ```bash
   npm run dev
   ```

4. **Desplegar a Producción**:

   Para subir la API a Cloudflare Workers:

   ```bash
   npm run deploy
   ```

5. **Ejecutar Migraciones de Base de Datos (D1)**:
   Ejecuta las migraciones iniciales para crear las tablas en tu base de datos D1 local o remota:

   ```bash
   # Remoto:
   npx wrangler d1 execute <nombre-de-tu-db-en-d1> --remote --file=./schemas/schema.sql

   # Local:
   npx wrangler d1 execute <nombre-de-tu-db-en-d1> --local --file=./schemas/schema.sql
   ```

## 📝 Licencia

[MIT](LICENSE)
