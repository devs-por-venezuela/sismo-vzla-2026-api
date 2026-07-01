-- 1. Usuarios y Voluntarios
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id TEXT UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    nationality TEXT, -- ISO 3166-1 alpha-3
    entity_type TEXT DEFAULT 'human', -- human, canine, equine
    metadata TEXT, -- JSON blob (comodín para cualquier dato extra)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL, -- admin, volunteer_coordinator, etc.
    name TEXT NOT NULL,
    description TEXT,
    metadata TEXT -- JSON blob (comodín para cualquier dato extra)
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER,
    role_id INTEGER,
    metadata TEXT, -- JSON blob (comodín para cualquier dato extra)
    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(user_id) REFERENCES users(id),
    FOREIGN KEY(role_id) REFERENCES roles(id)
);

-- 2. Especialidades
CREATE TABLE IF NOT EXISTS specialties (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    metadata TEXT -- JSON
);

CREATE TABLE IF NOT EXISTS volunteer_specialties (
    volunteer_id INTEGER,
    specialty_id INTEGER,
    metadata TEXT, -- JSON
    FOREIGN KEY(volunteer_id) REFERENCES users(id),
    FOREIGN KEY(specialty_id) REFERENCES specialties(id)
);


-- 3. Sistema Unificado de Instalaciones (Facilities)
-- Reemplaza a las 6 tablas individuales para facilitar queries y mantenimiento
CREATE TABLE IF NOT EXISTS facilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL, -- shelter, medical, bathroom, morgue, dining, waste
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    latitude REAL, -- Para geolocalización ligera
    longitude REAL,
    status TEXT, -- operational, full, disabled, maintenance
    contact_phone TEXT,
    metadata TEXT, -- JSON para capacidades, suministros, notas específicas
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 4. Inventario
CREATE TABLE IF NOT EXISTS item_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    metadata TEXT -- JSON blob (comodín para cualquier dato extra)
);

CREATE TABLE IF NOT EXISTS items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    name TEXT NOT NULL,
    unit TEXT, -- kg, lts, units
    is_perishable BOOLEAN DEFAULT 0,
    metadata TEXT, -- JSON blob (comodín para cualquier dato extra)
    FOREIGN KEY(category_id) REFERENCES item_categories(id)
);

CREATE TABLE IF NOT EXISTS center_stock (
    center_id INTEGER,
    item_id INTEGER,
    quantity DECIMAL(12,2),
    metadata TEXT, -- JSON blob (comodín para cualquier dato extra)
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(center_id, item_id),
    FOREIGN KEY(center_id) REFERENCES facilities(id),
    FOREIGN KEY(item_id) REFERENCES items(id)
);

-- 5. Movimientos y Logística
CREATE TABLE IF NOT EXISTS inventory_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    center_origin_id INTEGER,
    center_destination_id INTEGER,
    movement_type TEXT, -- donation_in, transfer, dispatch_to_affected
    quantity DECIMAL(12,2),
    performed_by INTEGER,
    movement_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT, -- JSON blob (comodín para cualquier dato extra)
    FOREIGN KEY(center_origin_id) REFERENCES facilities(id),
    FOREIGN KEY(center_destination_id) REFERENCES facilities(id),
    FOREIGN KEY(performed_by) REFERENCES users(id)
);

-- Índices para optimizar la velocidad en móviles (búsqueda rápida)
CREATE INDEX idx_facilities_type ON facilities(type);
CREATE INDEX idx_users_nationality ON users(nationality);
CREATE INDEX idx_movements_timestamp ON inventory_movements(movement_timestamp);

-- Índices para optimizar el filtrado de Facilities (Búsqueda por tipo y ubicación)
CREATE INDEX IF NOT EXISTS idx_facilities_type_status ON facilities(type, status);
CREATE INDEX IF NOT EXISTS idx_facilities_city ON facilities(city);

-- Índices para búsquedas de Inventario (Crucial para reportar escasez o suministros)
CREATE INDEX IF NOT EXISTS idx_center_stock_center_id ON center_stock(center_id);
CREATE INDEX IF NOT EXISTS idx_items_category ON items(category_id);

-- Índices para Sincronización (Delta Sync)
-- Estos son los MÁS importantes. Aseguran que buscar "lo nuevo" sea instantáneo
CREATE INDEX IF NOT EXISTS idx_users_updated_at ON users(updated_at);
CREATE INDEX IF NOT EXISTS idx_facilities_updated_at ON facilities(updated_at);
CREATE INDEX IF NOT EXISTS idx_movements_updated_at ON inventory_movements(movement_timestamp);

-- Índices para búsqueda textual/identificación rápida
CREATE INDEX IF NOT EXISTS idx_users_doc_id ON users(document_id);