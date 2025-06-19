# Backend - Sistema de Tracking de Cruceros 🚌

Backend desarrollado con NestJS para el sistema de tracking de transporte público. Proporciona APIs REST y WebSockets para la aplicación móvil Flutter.

## 🛠️ Tecnologías

- **NestJS** - Framework de Node.js
- **PostgreSQL** - Base de datos principal
- **TypeORM** - ORM para manejo de base de datos
- **Socket.IO** - WebSockets para tiempo real
- **JWT** - Autenticación

## 📋 Prerrequisitos

- Node.js 18+ 
- PostgreSQL 12+
- npm o yarn

## 🚀 Instalación

### 1. Instalar dependencias
```bash
npm install
```

### 2. Configurar PostgreSQL
```bash
# Crear base de datos
sudo -u postgres psql
postgres=# CREATE DATABASE crucero_tracking;
postgres=# \q

# O usar el script proporcionado
sudo -u postgres psql -f setup.sql
```

### 3. Configurar variables de entorno
```bash
# Crear archivo .env en la raíz del proyecto
cp .env.example .env
```

Configurar las siguientes variables en `.env`:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=tu_password
DB_NAME=crucero_tracking

# Application Configuration
NODE_ENV=development
PORT=3001
API_PREFIX=api

# JWT Configuration
JWT_SECRET=tu-clave-secreta-super-segura
JWT_EXPIRES_IN=24h

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://192.168.100.67:3000
```

### 4. Ejecutar la aplicación
```bash
# Desarrollo
npm run start:dev

# Producción
npm run build
npm run start:prod
```

## 📡 API Endpoints

### Entidades Operadoras
- `GET /api/entidad-operadora` - Listar todas las entidades
- `POST /api/entidad-operadora` - Crear nueva entidad
- `GET /api/entidad-operadora/:id` - Obtener entidad por ID
- `PATCH /api/entidad-operadora/:id` - Actualizar entidad
- `DELETE /api/entidad-operadora/:id` - Eliminar entidad

### Rutas
- `GET /api/ruta` - Listar todas las rutas
- `GET /api/ruta/:idEntidad` - Obtener rutas por entidad (usado por móvil)
- `POST /api/ruta` - Crear nueva ruta
- `GET /api/ruta/detail/:id` - Obtener ruta por ID
- `PATCH /api/ruta/:id` - Actualizar ruta
- `DELETE /api/ruta/:id` - Eliminar ruta

## 🔌 WebSockets

### Socket General (puerto 3001)
```javascript
// Conexión
const socket = io('http://localhost:3001');

// Eventos disponibles
socket.emit('message', { message: 'Hola mundo' });
socket.emit('joinRoom', 'sala123');
socket.emit('leaveRoom', 'sala123');

// Escuchar eventos
socket.on('messageResponse', (data) => console.log(data));
socket.on('userJoined', (data) => console.log(data));
socket.on('userLeft', (data) => console.log(data));
```

### Socket de Tracking (/tracking namespace)
```javascript
// Conexión con autenticación
const trackingSocket = io('http://localhost:3001/tracking', {
  auth: {
    microId: 'MICRO001',
    token: 'jwt-token'
  }
});

// Enviar ubicación
trackingSocket.emit('updateLocation', {
  id_micro: 'MICRO001',
  latitud: -16.5000,
  longitud: -68.1193,
  altura: 3500,
  precision: 10,
  bateria: 85,
  imei: 'dispositivo-flutter',
  fuente: 'app_flutter',
  id_ruta: 'RUT001'
});

// Unirse a ruta
trackingSocket.emit('joinRoute', 'RUT001');
trackingSocket.emit('leaveRoute', 'RUT001');

// Escuchar eventos
trackingSocket.on('locationUpdate', (data) => console.log(data));
trackingSocket.on('initialTrackingData', (data) => console.log(data));
trackingSocket.on('routeLocationUpdate', (data) => console.log(data));
trackingSocket.on('connectionStatusChanged', (data) => console.log(data));
```

## 🗄️ Estructura de Base de Datos

### Entidades (`entidades`)
- `id` (VARCHAR) - ID único de la entidad
- `nombre` (VARCHAR) - Nombre de la empresa
- `tipo` (VARCHAR) - Tipo de transporte
- `direccion` (TEXT) - Dirección física
- `correo_contacto` (VARCHAR) - Email de contacto
- `wallet_address` (VARCHAR) - Dirección de wallet blockchain
- `saldo_ingresos` (DECIMAL) - Saldo actual
- `estado` (BOOLEAN) - Estado activo/inactivo
- `created_at`, `updated_at` - Timestamps

### Rutas (`rutas`)
- `id` (VARCHAR) - ID único de la ruta
- `id_entidad` (VARCHAR) - FK a entidades
- `nombre` (VARCHAR) - Nombre de la ruta
- `descripcion` (TEXT) - Descripción
- `origen_lat`, `origen_long` (DECIMAL) - Coordenadas origen
- `destino_lat`, `destino_long` (DECIMAL) - Coordenadas destino
- `vertices` (TEXT) - JSON con puntos de la ruta
- `distancia` (DECIMAL) - Distancia en km
- `tiempo` (DECIMAL) - Tiempo estimado en minutos
- `created_at`, `updated_at` - Timestamps

### Tracking Locations (`tracking_locations`)
- `id` (UUID) - ID único del registro
- `id_micro` (VARCHAR) - Identificador del micro/bus
- `id_ruta` (VARCHAR) - FK a rutas (opcional)
- `latitud`, `longitud` (DECIMAL) - Coordenadas GPS
- `altura` (DECIMAL) - Altitud
- `precision` (DECIMAL) - Precisión GPS
- `bateria` (DECIMAL) - Nivel de batería
- `imei` (VARCHAR) - IMEI del dispositivo
- `fuente` (VARCHAR) - Fuente de la ubicación
- `created_at` - Timestamp

## 🔧 Comandos de Desarrollo

```bash
# Instalar dependencias
npm install

# Modo desarrollo con hot reload
npm run start:dev

# Build para producción
npm run build

# Ejecutar tests
npm run test

# Test con coverage
npm run test:cov

# Linting
npm run lint

# Formatear código
npm run format
```

## 🐳 Docker (Opcional)

```bash
# Construir imagen
docker build -t crucero-backend .

# Ejecutar con docker-compose
docker-compose up -d
```

## 📝 Notas de Desarrollo

1. **TypeORM Sync**: En desarrollo usa `synchronize: true` para crear tablas automáticamente
2. **Logs**: Los logs de WebSocket aparecen con emojis para fácil identificación
3. **CORS**: Configurado para permitir el dominio del móvil Flutter
4. **Validación**: Usa class-validator para validar DTOs
5. **Rate Limiting**: Considera implementar rate limiting en producción

## 🚀 Deployment

### Variables de entorno para producción:
```env
NODE_ENV=production
DB_HOST=tu-servidor-postgres
DB_PASSWORD=password-seguro
JWT_SECRET=clave-jwt-super-segura-de-32-caracteres
CORS_ORIGIN=https://tu-dominio.com
```

### PM2 (Recomendado para producción):
```bash
npm install -g pm2
pm2 start npm --name "crucero-backend" -- run start:prod
pm2 save
pm2 startup
```

## 🔍 Troubleshooting

### Error de conexión a PostgreSQL:
- Verificar que PostgreSQL esté ejecutándose
- Comprobar credenciales en `.env`
- Verificar que la base de datos `crucero_tracking` exista

### Error de CORS:
- Añadir la IP/dominio del cliente móvil a `CORS_ORIGIN`
- Verificar configuración de red local

### WebSocket no conecta:
- Verificar que el puerto 3001 esté disponible
- Comprobar firewall y configuración de red
- Revisar logs del servidor para errores

## 📧 Soporte

Para soporte técnico, revisar los logs de la aplicación:
```bash
# Ver logs en tiempo real
npm run start:dev

# Logs de producción con PM2
pm2 logs crucero-backend
```
