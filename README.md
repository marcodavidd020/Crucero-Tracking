# 🚌 Crucero Tracking - Sistema de Transporte Público

Un sistema integral de tracking en tiempo real para transporte público en Santa Cruz de la Sierra, Bolivia. La aplicación permite a pasajeros seguir micros en tiempo real y a micreros gestionar sus rutas de manera eficiente.

## 🎯 Descripción General

Crucero Tracking es una solución tecnológica moderna que mejora la experiencia del transporte público mediante:

- **Tracking en tiempo real** de micros y rutas
- **Interfaz dual** para pasajeros y conductores (micreros)
- **Sistema offline** para funcionamiento sin conexión
- **Gestión de rutas** y entidades operadoras
- **Notificaciones** y actualizaciones en vivo

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │◄──►│   Backend API   │◄──►│   PostgreSQL    │
│   (Flutter)     │    │   (NestJS)      │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │              ┌─────────────────┐
         └─────────────►│   WebSocket     │
                        │   Real-time     │
                        └─────────────────┘
```

## 🎭 Usuarios del Sistema

### 👥 Pasajeros
- Ver rutas disponibles en tiempo real
- Seguir ubicación de micros
- Recibir notificaciones de llegada
- Funcionalidad offline para consultas

### 🚐 Micreros (Conductores)
- Gestionar rutas asignadas
- Compartir ubicación en tiempo real
- Ver estadísticas de viaje
- Sistema de autenticación seguro

### 🏢 Administradores
- Gestión de entidades operadoras
- Asignación de rutas y micros
- Monitoreo del sistema
- Reportes y analytics

## 🛠️ Tecnologías Utilizadas

### Frontend (Mobile)
- **Flutter 3.x** - Framework multiplataforma
- **Dart** - Lenguaje de programación
- **Riverpod** - Gestión de estado
- **MapLibre** - Mapas y geolocalización
- **Socket.IO** - Comunicación en tiempo real
- **Isar** - Base de datos local

### Backend
- **NestJS** - Framework Node.js
- **TypeScript** - Lenguaje tipado
- **PostgreSQL** - Base de datos principal
- **TypeORM** - ORM para base de datos
- **Socket.IO** - WebSockets
- **JWT** - Autenticación

### DevOps & Infraestructura
- **Docker** - Containerización
- **Git** - Control de versiones
- **AWS/Cloud** - Deployment

## 🚀 Características Principales

### 📱 Aplicación Móvil
- ✅ **Interfaz moderna y intuitiva**
- ✅ **Modo offline completo**
- ✅ **Tracking GPS en background**
- ✅ **Notificaciones push**
- ✅ **Soporte para múltiples idiomas**

### 🖥️ Backend API
- ✅ **API RESTful completa**
- ✅ **WebSockets para tiempo real**
- ✅ **Sistema de autenticación robusto**
- ✅ **Gestión de entidades y rutas**
- ✅ **Logs y monitoreo**

### 🗃️ Base de Datos
- ✅ **Esquema relacional optimizado**
- ✅ **Indices para consultas rápidas**
- ✅ **Respaldos automáticos**
- ✅ **Escalabilidad horizontal**

## 📁 Estructura del Proyecto

```
crucero-tracking/
├── 📱 mobile/              # Aplicación Flutter
│   ├── lib/
│   │   ├── features/       # Módulos por funcionalidad
│   │   ├── services/       # Servicios y APIs
│   │   ├── config/         # Configuración
│   │   └── common/         # Utilidades compartidas
│   └── README.md
├── 🖥️ backend/             # API NestJS
│   ├── src/
│   │   ├── modules/        # Módulos del sistema
│   │   ├── entities/       # Entidades de base de datos
│   │   └── common/         # Middlewares y utilidades
│   └── README.md
├── 📊 database/            # Scripts y migraciones
└── 📚 docs/               # Documentación adicional
```

## 🔧 Instalación Rápida

### Prerrequisitos
- Node.js 18+
- Flutter 3.x
- PostgreSQL 14+
- Git

### Configuración
```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/crucero-tracking.git
cd crucero-tracking

# Backend
cd backend
npm install
npm run start:dev

# Mobile
cd ../mobile
flutter pub get
flutter run
```

Ver los READMEs específicos de cada módulo para instrucciones detalladas.

## 🎮 Cómo Usar el Sistema

### Para Desarrolladores

#### 1. **Configuración Inicial**
```bash
# Configurar base de datos
sudo -u postgres psql -f backend/setup.sql

# Configurar variables de entorno
cp backend/.env.example backend/.env
# Editar backend/.env con tus configuraciones

# Configurar constantes del móvil
# Editar mobile/lib/config/constants.dart
```

#### 2. **Desarrollo Backend**
```bash
cd backend
npm run start:dev  # Puerto 3001
```

#### 3. **Desarrollo Mobile**
```bash
cd mobile
flutter run  # En emulador o dispositivo
```

### Para Usuarios Finales

#### **Pasajeros**
1. Abrir app → Seleccionar "Soy Pasajero"
2. Iniciar sesión con credenciales de cliente
3. Ver mapa con rutas disponibles
4. Seguir micros en tiempo real

#### **Micreros**
1. Abrir app → Seleccionar "Soy Micrero"
2. Iniciar sesión con credenciales de empleado
3. Seleccionar ruta desde dashboard
4. Iniciar tracking GPS automático

## 🔐 Credenciales de Prueba

### Clientes
```
Email: jose.cliente@gmail.com
Contraseña: 12345678
```

### Micreros
```
Email: marco.chofer@gmail.com
Contraseña: 12345678
```

## 🌟 Funcionalidades Destacadas

### **Sistema Offline Inteligente**
- Cache automático de rutas y datos
- Sincronización cuando se restaura conexión
- Login offline con credenciales guardadas

### **Tracking en Tiempo Real**
- GPS de alta precisión
- Actualización cada 5 segundos
- Persistencia en background para micreros

### **Arquitectura Escalable**
- Clean Architecture en Flutter
- Microservicios con NestJS
- Base de datos optimizada

### **UX/UI Moderna**
- Interfaz adaptativa
- Animaciones fluidas
- Diseño responsive

## 🤝 Equipo de Desarrollo

- **Desarrollo Mobile**: Flutter & Dart
- **Desarrollo Backend**: NestJS & TypeScript
- **Base de Datos**: PostgreSQL & TypeORM
- **DevOps**: Docker & Cloud Infrastructure

## 📈 Estado del Proyecto

🟢 **Activo** - En desarrollo continuo

### Versión Actual: v1.0.0
- ✅ Sistema de autenticación completo
- ✅ Tracking en tiempo real funcional
- ✅ Modo offline implementado
- ✅ Gestión de rutas y entidades
- ✅ Dashboard de micreros
- ✅ Página de bienvenida optimizada
- 🔄 Optimizaciones de rendimiento

### Próximas Características
- 🔄 Notificaciones push
- 🔄 Reportes y analytics
- 🔄 Sistema de pagos
- 🔄 Multi-idioma completo

## 🐛 Troubleshooting Rápido

### Backend no conecta
```bash
# Verificar PostgreSQL
sudo systemctl status postgresql

# Verificar puerto
netstat -tulpn | grep :3001

# Ver logs
cd backend && npm run start:dev
```

### Mobile no conecta
```bash
# Verificar IP en constants.dart
# mobile/lib/config/constants.dart
const String baseUrl = 'http://TU_IP:3001/api';

# Verificar permisos de ubicación
flutter doctor
```

### Error de autenticación
```bash
# Verificar JWT_SECRET en backend/.env
# Usar credenciales de prueba correctas
# Verificar que el backend esté corriendo
```

## 📚 Documentación Adicional

- **[Backend README](backend/README.md)** - Configuración detallada del servidor
- **[Mobile README](mobile/README.md)** - Guía completa de la app Flutter
- **[API Documentation](#)** - Endpoints y ejemplos
- **[Database Schema](backend/setup.sql)** - Estructura de base de datos

## 📞 Soporte

Para reportar bugs o solicitar nuevas características:
- 📧 Email: soporte@crucerotracking.com
- 🐛 Issues: [GitHub Issues](../../issues)
- 📖 Documentación: [Wiki del proyecto](../../wiki)
- 💬 Discussions: [GitHub Discussions](../../discussions)

## 📄 Licencia

Este proyecto está bajo la licencia [MIT](LICENSE) - ver el archivo LICENSE para más detalles.

## 🙏 Agradecimientos

- Comunidad de Flutter por el excelente framework
- Equipo de NestJS por el robusto backend framework
- MapLibre por los mapas de código abierto
- Contribuidores y beta testers

---

**Crucero Tracking** - Mejorando el transporte público con tecnología moderna 🚀

*Desarrollado con ❤️ en Santa Cruz de la Sierra, Bolivia*