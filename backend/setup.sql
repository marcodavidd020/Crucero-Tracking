-- Script de configuración para la base de datos crucero_tracking
-- Ejecutar como superusuario de PostgreSQL

-- Crear base de datos
CREATE DATABASE crucero_tracking;

-- Conectar a la base de datos
\c crucero_tracking;

-- Crear usuario específico para la aplicación (opcional)
-- CREATE USER crucero_user WITH PASSWORD 'crucero_password';
-- GRANT ALL PRIVILEGES ON DATABASE crucero_tracking TO crucero_user;

-- Las tablas se crearán automáticamente con TypeORM synchronize: true
-- Aquí incluimos datos de ejemplo para pruebas

-- Insertar entidades de ejemplo (después de que TypeORM cree las tablas)
-- Estos datos se pueden insertar manualmente o a través de la API

/*
-- Datos de ejemplo para entidades
INSERT INTO entidades (id, nombre, tipo, direccion, correo_contacto, wallet_address, saldo_ingresos, estado, created_at, updated_at) VALUES
('ENT001', 'Transportes El Crucero', 'Transporte Público', 'Av. Principal 123, La Paz', 'contacto@crucero.bo', '0x1234567890abcdef', 15000.50, true, NOW(), NOW()),
('ENT002', 'Línea Azul Express', 'Transporte Urbano', 'Calle Comercio 456, El Alto', 'info@azulexpress.bo', '0xabcdef1234567890', 8750.25, true, NOW(), NOW()),
('ENT003', 'Micros del Sur', 'Transporte Intermunicipal', 'Plaza San Francisco, La Paz', 'admin@microsdelsur.bo', '0x9876543210fedcba', 22300.75, true, NOW(), NOW());

-- Datos de ejemplo para rutas
INSERT INTO rutas (id, id_entidad, nombre, descripcion, origen_lat, origen_long, destino_lat, destino_long, vertices, distancia, tiempo, created_at, updated_at) VALUES
('RUT001', 'ENT001', 'La Paz - El Alto Centro', 'Ruta principal desde zona sur La Paz hasta el centro de El Alto', -16.5000, -68.1193, -16.5040, -68.1240, '[{"lat": -16.5000, "lng": -68.1193}, {"lat": -16.5020, "lng": -68.1220}, {"lat": -16.5040, "lng": -68.1240}]', 15.5, 45, NOW(), NOW()),
('RUT002', 'ENT001', 'Sopocachi - Villa Fátima', 'Conexión entre Sopocachi y Villa Fátima', -16.5100, -68.1150, -16.5200, -68.1100, '[{"lat": -16.5100, "lng": -68.1150}, {"lat": -16.5150, "lng": -68.1125}, {"lat": -16.5200, "lng": -68.1100}]', 8.2, 25, NOW(), NOW()),
('RUT003', 'ENT002', 'Terminal - Ceja El Alto', 'Ruta desde terminal de buses hasta la Ceja de El Alto', -16.5300, -68.1300, -16.5100, -68.1600, '[{"lat": -16.5300, "lng": -68.1300}, {"lat": -16.5200, "lng": -68.1450}, {"lat": -16.5100, "lng": -68.1600}]', 12.3, 35, NOW(), NOW());
*/

-- Índices adicionales para mejorar rendimiento
-- CREATE INDEX IF NOT EXISTS idx_tracking_micro_created ON tracking_locations(id_micro, created_at DESC);
-- CREATE INDEX IF NOT EXISTS idx_tracking_ruta_created ON tracking_locations(id_ruta, created_at DESC);
-- CREATE INDEX IF NOT EXISTS idx_entidades_estado ON entidades(estado);

-- Comentarios sobre las tablas
COMMENT ON DATABASE crucero_tracking IS 'Base de datos para sistema de tracking de transporte público';

-- Configuración de timezone
SET timezone = 'America/La_Paz';

PRINT 'Base de datos configurada exitosamente. Inicia el servidor NestJS para que TypeORM cree las tablas automáticamente.'; 