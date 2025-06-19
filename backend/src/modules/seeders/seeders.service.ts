import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { EntidadOperadora } from '../entidad-operadora/entities/entidad-operadora.entity';
import { Ruta } from '../ruta/entities/ruta.entity';
import { Usuario, TipoUsuario } from '../usuario/entities/usuario.entity';
import { Cliente } from '../cliente/entities/cliente.entity';
import { Empleado, TipoEmpleado } from '../empleado/entities/empleado.entity';
import { Micro } from '../micro/entities/micro.entity';
import { Parada } from '../parada/entities/parada.entity';
import { TrackingLocation } from '../tracking/entities/tracking-location.entity';

@Injectable()
export class SeedersService {
  private readonly logger = new Logger(SeedersService.name);

  constructor(
    @InjectRepository(EntidadOperadora)
    private readonly entidadRepository: Repository<EntidadOperadora>,
    @InjectRepository(Ruta)
    private readonly rutaRepository: Repository<Ruta>,
    @InjectRepository(Usuario)
    private readonly usuarioRepository: Repository<Usuario>,
    @InjectRepository(Cliente)
    private readonly clienteRepository: Repository<Cliente>,
    @InjectRepository(Empleado)
    private readonly empleadoRepository: Repository<Empleado>,
    @InjectRepository(Micro)
    private readonly microRepository: Repository<Micro>,
    @InjectRepository(Parada)
    private readonly paradaRepository: Repository<Parada>,
    @InjectRepository(TrackingLocation)
    private readonly trackingRepository: Repository<TrackingLocation>,
  ) {}

  async seedAll() {
    this.logger.log('🌱 Iniciando seeders...');
    
    try {
      await this.seedEntidades();
      await this.seedMicros();
      await this.seedUsuarios();
      await this.seedRutas();
      await this.seedParadas();
      await this.seedTrackingLocations();
      
      this.logger.log('✅ Seeders completados exitosamente');
    } catch (error) {
      this.logger.error('❌ Error ejecutando seeders:', error);
      throw error;
    }
  }

  private async seedEntidades() {
    this.logger.log('📦 Creando entidades operadoras...');
    
    const entidades = [
      {
        id: 'ENT001',
        nombre: 'Crucero del Sur',
        nit: '1234567891',
        direccion: 'Av. Alemana 123, Santa Cruz de la Sierra, Bolivia',
        telefono: '3-123-4567',
        email: 'contacto@crucero.bo',
        representante: 'Juan Carlos Perez',
        activo: true,
      },
      {
        id: 'ENT002',
        nombre: 'Línea Amarilla',
        nit: '1234567892',
        direccion: 'Av. San Martín 456, Santa Cruz de la Sierra, Bolivia',
        telefono: '3-234-5678',
        email: 'info@lineaamarilla.bo',
        representante: 'Maria Rodriguez',
        activo: true,
      },
      {
        id: 'ENT003',
        nombre: 'Copacabana',
        nit: '1234567893',
        direccion: 'Terminal Bimodal, Santa Cruz de la Sierra, Bolivia',
        telefono: '3-345-6789',
        email: 'admin@copacabana.bo',
        representante: 'Pedro Sanchez',
        activo: true,
      },
    ];

    for (const entidadData of entidades) {
      const existing = await this.entidadRepository.findOne({ where: { id: entidadData.id } });
      if (!existing) {
        const entidad = this.entidadRepository.create(entidadData);
        await this.entidadRepository.save(entidad);
        this.logger.log(`✓ Entidad creada: ${entidadData.nombre} (${entidadData.id})`);
      } else {
        this.logger.log(`⚠️  Entidad ya existe: ${entidadData.nombre} (${entidadData.id})`);
      }
    }
  }

  private async seedMicros() {
    this.logger.log('🚌 Creando micros...');
    
    const micros = [
      {
        id: 'MCR001',
        idEntidad: 'ENT001',
        placa: 'SCZ-1001',
        modelo: 'Mercedes-Benz Sprinter',
        color: 'Azul y Blanco',
        capacidad: 25,
        anio: 2020,
        imei: '860123456789001',
        activo: true,
      },
      {
        id: 'MCR002',
        idEntidad: 'ENT001',
        placa: 'SCZ-1002',
        modelo: 'Iveco Daily',
        color: 'Azul y Blanco',
        capacidad: 22,
        anio: 2019,
        imei: '860123456789002',
        activo: true,
      },
    ];

    for (const microData of micros) {
      const existing = await this.microRepository.findOne({ where: { id: microData.id } });
      if (!existing) {
        const micro = this.microRepository.create(microData);
        await this.microRepository.save(micro);
        this.logger.log(`✓ Micro creado: ${microData.placa} (${microData.id})`);
      } else {
        this.logger.log(`⚠️  Micro ya existe: ${microData.placa} (${microData.id})`);
      }
    }
  }

  private async seedUsuarios() {
    this.logger.log('👥 Creando usuarios...');
    
    const usuarios = [
      // Usuario debug
      {
        id: 'USR001',
        nombre: 'Usuario Debug',
        correo: 'debug@crucero.bo',
        contrasena: 'password123',
        tipo: TipoUsuario.CLIENTE,
      },
      // Carlos Mamani - Empleado/Micrero
      {
        id: 'USR002',
        nombre: 'Carlos Mamani',
        correo: 'carlos.mamani@crucero.bo',
        contrasena: 'password123',
        tipo: TipoUsuario.EMPLEADO,
      },
      // Cliente de prueba
      {
        id: 'USR003',
        nombre: 'Ana Rodriguez',
        correo: 'ana.rodriguez@email.com',
        contrasena: 'password123',
        tipo: TipoUsuario.CLIENTE,
      },
    ];

    for (const userData of usuarios) {
      const existing = await this.usuarioRepository.findOne({ where: { id: userData.id } });
      if (!existing) {
        const hashedPassword = await bcrypt.hash(userData.contrasena, 10);
        const usuario = this.usuarioRepository.create({
          ...userData,
          contrasena: hashedPassword,
        });
        await this.usuarioRepository.save(usuario);
        this.logger.log(`✓ Usuario creado: ${userData.nombre} (${userData.correo})`);

        // Crear perfil específico
        if (userData.tipo === TipoUsuario.CLIENTE) {
          const cliente = this.clienteRepository.create({
            id: `CLI_${userData.id}`,
            userId: userData.id,
            walletAddress: `0x${Math.random().toString(16).substr(2, 40)}`,
            registros: [],
            notificaciones: [],
            tarjetas: [],
            saldo: 100.00,
          });
          await this.clienteRepository.save(cliente);
          this.logger.log(`✓ Cliente creado: CLI_${userData.id}`);
        }

        if (userData.tipo === TipoUsuario.EMPLEADO) {
          const empleado = this.empleadoRepository.create({
            id: `EMP_${userData.id}`,
            userId: userData.id,
            tipo: TipoEmpleado.CHOFER,
            idEntidad: 'ENT001',
            idMicro: userData.id === 'USR002' ? 'MCR001' : undefined, // Carlos Mamani asignado a MCR001
            licencia: 'LIC123456',
            fechaContratacion: new Date('2023-01-01'),
            salario: 3500.00,
            activo: true,
          });
          await this.empleadoRepository.save(empleado);
          this.logger.log(`✓ Empleado creado: EMP_${userData.id}`);
        }
      } else {
        this.logger.log(`⚠️  Usuario ya existe: ${userData.correo}`);
      }
    }
  }

  private async seedRutas() {
    this.logger.log('🛣️  Creando rutas de Santa Cruz...');
    
    const rutas = [
      {
        id: 'RUT001',
        idEntidad: 'ENT001',
        nombre: 'Centro - Plan 3000',
        descripcion: 'Ruta que conecta el centro de la ciudad con Plan 3000',
        origenLat: -17.79329,
        origenLong: -63.1868,
        destinoLat: -17.7812,
        destinoLong: -63.18883,
        vertices: JSON.stringify([
          [-63.1868, -17.79329],
          [-63.18722, -17.79051],
          [-63.18777, -17.7887],
          [-63.18843, -17.78693],
          [-63.18888, -17.78533],
          [-63.18886, -17.78328],
          [-63.18883, -17.7812]
        ]),
        distancia: 12.5,
        tiempo: 35,
      },
      {
        id: 'RUT003',
        idEntidad: 'ENT001',
        nombre: 'Centro - Equipetrol',
        descripcion: 'Ruta que conecta el centro con el barrio Equipetrol',
        origenLat: -17.78362,
        origenLong: -63.18217,
        destinoLat: -17.75896,
        destinoLong: -63.14521,
        vertices: JSON.stringify([
          [-63.18217, -17.78362],
          [-63.17854, -17.77932],
          [-63.17245, -17.77412],
          [-63.16598, -17.76847],
          [-63.15932, -17.76234],
          [-63.15287, -17.75687],
          [-63.14521, -17.75896]
        ]),
        distancia: 8.7,
        tiempo: 25,
      },
    ];

    for (const rutaData of rutas) {
      const existing = await this.rutaRepository.findOne({ where: { id: rutaData.id } });
      if (!existing) {
        const ruta = this.rutaRepository.create(rutaData);
        await this.rutaRepository.save(ruta);
        this.logger.log(`✓ Ruta creada: ${rutaData.nombre} (${rutaData.id})`);
      } else {
        this.logger.log(`⚠️  Ruta ya existe: ${rutaData.nombre} (${rutaData.id})`);
      }
    }
  }

  private async seedParadas() {
    this.logger.log('🚏 Creando paradas...');
    
    const paradas = [
      // Paradas para RUT001 (Centro - Plan 3000)
      {
        id: 'PAR001',
        idRuta: 'RUT001',
        nombre: 'Plaza Principal',
        descripcion: 'Parada central en la plaza principal',
        latitud: -17.79329,
        longitud: -63.1868,
        orden: 1,
        activo: true,
      },
      {
        id: 'PAR002',
        idRuta: 'RUT001',
        nombre: 'Av. Cristo Redentor',
        descripcion: 'Parada en Avenida Cristo Redentor',
        latitud: -17.79051,
        longitud: -63.18722,
        orden: 2,
        activo: true,
      },
      {
        id: 'PAR003',
        idRuta: 'RUT001',
        nombre: 'Terminal Plan 3000',
        descripcion: 'Terminal final en Plan 3000',
        latitud: -17.7812,
        longitud: -63.18883,
        orden: 3,
        activo: true,
      },
    ];

    for (const paradaData of paradas) {
      const existing = await this.paradaRepository.findOne({ where: { id: paradaData.id } });
      if (!existing) {
        const parada = this.paradaRepository.create(paradaData);
        await this.paradaRepository.save(parada);
        this.logger.log(`✓ Parada creada: ${paradaData.nombre} (${paradaData.id})`);
      } else {
        this.logger.log(`⚠️  Parada ya existe: ${paradaData.nombre} (${paradaData.id})`);
      }
    }
  }

  private async seedTrackingLocations() {
    this.logger.log('📍 Creando ubicaciones de tracking...');
    
    // Datos de tracking de ejemplo para la ruta RUT001
    const trackingData = [
      {
        idMicro: 'MCR001',
        idRuta: 'RUT001',
        latitud: -17.79329,
        longitud: -63.1868,
        altura: 450.5,
        precision: 5.0,
        bateria: 85.2,
        imei: '860123456789001',
        fuente: 'seeder',
      },
    ];

    for (const tracking of trackingData) {
      // Para tracking, siempre creamos uno nuevo ya que representa momentos en el tiempo
      const location = this.trackingRepository.create(tracking);
      const savedLocation = await this.trackingRepository.save(location);
      this.logger.log(`✓ Tracking location creada: ${savedLocation.id}`);
    }
  }

  async clearAll() {
    this.logger.log('🗑️  Limpiando todas las tablas...');
    
    try {
      // Orden importante: primero las dependencias, luego las tablas padre
      await this.trackingRepository.delete({});
      await this.paradaRepository.delete({});
      await this.clienteRepository.delete({});
      await this.empleadoRepository.delete({});
      await this.microRepository.delete({});
      await this.rutaRepository.delete({});
      await this.usuarioRepository.delete({});
      await this.entidadRepository.delete({});
      
      this.logger.log('✅ Todas las tablas han sido limpiadas');
    } catch (error) {
      this.logger.error('❌ Error limpiando tablas:', error);
      throw error;
    }
  }
} 