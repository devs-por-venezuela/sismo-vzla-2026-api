import { Hono } from 'hono'

type Bindings = {
  DB: D1Database
  DB_BUCKET: R2Bucket
}

const app = new Hono<{ Bindings: Bindings }>()

// 1. RUTA DE LECTURA MASIVA (Sigue sirviendo el archivo de R2)
app.get('/api/data', async (c) => {
  const object = await c.env.DB_BUCKET.get('data.json')
  if (!object) return c.json({ error: 'Data unavailable' }, 404)
  
  return new Response(object.body, {
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=300' }
  })
})

// 2. RUTA DELTA SYNC (El núcleo de la eficiencia)
app.get('/api/sync', async (c) => {
  // El cliente envía el timestamp de su última actualización local
  const lastSync = c.req.query('since') || '1970-01-01 00:00:00'
  const db = c.env.DB

  try {
    // Consultamos cambios en todas las tablas clave usando 'updated_at'
    // Nota: Esto requiere que las tablas tengan la columna 'updated_at'
    const { results } = await db
      .prepare("SELECT * FROM collection_centers WHERE updated_at > ?")
      .bind(lastSync)
      .all()

    return c.json({
      timestamp: new Date().toISOString(), // Nuevo timestamp para que el cliente guarde
      data: results
    })
  } catch (e) {
    return c.json({ error: 'Error in sync' }, 500)
  }
})

// 3. RUTA DE REPORTE (Asegúrate de actualizar 'updated_at' al insertar/modificar)
app.post('/api/report', async (c) => {
  const { name, type, metadata } = await c.req.json()
  
  try {
    await c.env.DB.prepare(
      "INSERT INTO collection_centers (name, type, metadata, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)"
    )
    .bind(name, type, JSON.stringify(metadata || {}))
    .run()
    
    return c.json({ status: 'Report received' }, 202)
  } catch (e) {
    return c.json({ error: 'Error saving report' }, 500)
  }
})

// --- LÓGICA DE CRON TRIGGER ---
async function performSync(env: Bindings) {
  const { results } = await env.DB.prepare("SELECT * FROM collection_centers").all()
  await env.DB_BUCKET.put('data.json', JSON.stringify(results))
}

export default {
  async fetch(request: Request, env: Bindings, ctx: ExecutionContext) {
    return app.fetch(request, env, ctx)
  },
  async scheduled(event: ScheduledEvent, env: Bindings, ctx: ExecutionContext) {
    ctx.waitUntil(performSync(env))
  }
}